import React, { useState, useEffect, useCallback, useRef } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  View,
  FlatList,
  StyleSheet,
  TouchableOpacity,
  RefreshControl,
  Image,
  StatusBar,
  Alert,
  Platform,
} from 'react-native';

import {
  Text,
  Searchbar,
  Badge,
  Divider,
  ActivityIndicator,
  Button,
  Icon,
} from 'react-native-paper';
import { getFirebaseFirestore, getCurrentUser, getFirebaseAuth } from '../services/firebase';
import {
  getLocalHiddenChatsMap,
  isChatLocallyHidden,
  addLocalHiddenChatId,
  removeLocalHiddenChatId,
  markNotificationAsRead,
} from '../services/notifications';
import { useLanguage } from '../context/LanguageContext';
import BrandLogo from '../components/BrandLogo';
import { UserAvatar } from '../components/UserAvatar';
import { ChatListSkeleton } from '../components/SkeletonLoaders';
import { ScalePressable } from '../components/animations/ScalePressable';

export default function ChatsScreen({ navigation, user: initialUser }: any) {
  const [chats, setChats] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [showSearch, setShowSearch] = useState(false);
  const [activeFilter, setActiveFilter] = useState<'all' | 'buy' | 'sell'>('all');
  const [activeUser, setActiveUser] = useState<any>(initialUser || getCurrentUser());
  const { translateDynamic } = useLanguage();

  // Cache fetched partner photos across renders so they aren't re-fetched constantly
  const partnerPhotoCacheRef = useRef<Record<string, string>>({});
  const mergeDebounceTimerRef = useRef<NodeJS.Timeout | null>(null);

  // Listen to auth state changes reactively
  useEffect(() => {
    let unsubAuth = () => {};
    try {
      const auth = getFirebaseAuth();
      if (auth && typeof auth.onAuthStateChanged === 'function') {
        unsubAuth = auth.onAuthStateChanged((u: any) => {
          setActiveUser(u || getCurrentUser());
        });
      } else {
        setActiveUser(getCurrentUser());
      }
    } catch (_) {
      setActiveUser(getCurrentUser());
    }
    return () => {
      try { unsubAuth(); } catch (_) {}
    };
  }, []);

  const getCleanId = (val: any): string => {
    if (!val) return '';
    if (typeof val === 'string') return val.trim();
    if (typeof val === 'object') return String(val.id || val.uid || val._id || '').trim();
    return String(val).trim();
  };

  const matchesUser = (idVal: any, user: any): boolean => {
    if (!idVal || !user) return false;
    const clean = getCleanId(idVal).toLowerCase();
    const uUid = getCleanId(user.uid).toLowerCase();
    const uId = getCleanId(user.id).toLowerCase();
    const uPhone = getCleanId(user.phoneNumber).toLowerCase();
    const uEmail = getCleanId(user.email).toLowerCase();
    return Boolean(
      (uUid && clean === uUid) ||
      (uId && clean === uId) ||
      (uPhone && clean === uPhone) ||
      (uEmail && clean === uEmail)
    );
  };

  // Helper to accurately determine if current user is the buyer in a chat
  const isCurrentUserBuyer = (chat: any, activeUid: string): boolean => {
    if (!chat) return true;
    const buyerId = getCleanId(chat.buyerId);
    const sellerId = getCleanId(chat.sellerId);

    // 1. If sellerId matches active user, user is the SELLER (so isCurrentUserBuyer = false)
    if (sellerId && (sellerId === activeUid || matchesUser(sellerId, activeUser))) {
      return false;
    }
    // 2. If buyerId matches active user, user is the BUYER
    if (buyerId && (buyerId === activeUid || matchesUser(buyerId, activeUser))) {
      return true;
    }
    // 3. Fallback: if sellerId is a valid partner ID (not current user), user is buyer
    if (sellerId && sellerId !== activeUid && !matchesUser(sellerId, activeUser) && sellerId !== 'seller') {
      return true;
    }
    // 4. Fallback: if buyerId is someone else, user is the seller
    if (buyerId && buyerId !== activeUid && !matchesUser(buyerId, activeUser) && buyerId !== 'buyer') {
      return false;
    }
    return true;
  };

  // Helper to get the other party's user ID
  const getPartnerIdFromChat = (c: any, uid: string): string => {
    if (!c) return '';
    const bId = getCleanId(c.buyerId);
    const sId = getCleanId(c.sellerId);
    if (sId && sId !== uid && !matchesUser(sId, activeUser) && sId !== 'seller') return sId;
    if (bId && bId !== uid && !matchesUser(bId, activeUser) && bId !== 'buyer') return bId;
    if (Array.isArray(c.participants)) {
      const other = c.participants.find((p: any) => {
        const pid = getCleanId(p);
        return pid && pid !== uid && !matchesUser(pid, activeUser) && pid !== 'seller' && pid !== 'buyer';
      });
      if (other) return getCleanId(other);
    }
    return isCurrentUserBuyer(c, uid) ? sId : bId;
  };

  const buyerChatsRef = useRef<any[]>([]);
  const sellerChatsRef = useRef<any[]>([]);
  const partChatsRef = useRef<any[]>([]);

  const loadUserChats = useCallback(() => {
    const activeUid = activeUser?.uid || activeUser?.id;
    if (!activeUid) {
      setLoading(false);
      setRefreshing(false);
      return () => {};
    }

    try {
      const db = getFirebaseFirestore();
      if (!db || typeof db.collection !== 'function') {
        setLoading(false);
        setRefreshing(false);
        return () => {};
      }

      const doMergeChats = async () => {
        try {
          const chatsMap = new Map<string, any>();
          const hiddenMap = await getLocalHiddenChatsMap();

          [...buyerChatsRef.current, ...sellerChatsRef.current, ...partChatsRef.current].forEach((c) => {
            if (!c || !c.id) return;
            const msgTime = parseTimestamp(c.lastMessageAt || c.updatedAt || c.createdAt || 0);
            if (isChatLocallyHidden(c.id, msgTime, hiddenMap)) return;
            if (Array.isArray(c.hiddenFor) && c.hiddenFor.includes(activeUid)) {
              const clearedTime = parseTimestamp(c.clearedAt?.[activeUid] || 0);
              if (clearedTime && msgTime <= clearedTime) return;
            }
            
            // If already present, merge properties preserving live text/timestamps
            if (chatsMap.has(c.id)) {
              const existing = chatsMap.get(c.id);
              chatsMap.set(c.id, {
                ...existing,
                ...c,
                lastMessageText: c.lastMessageText || existing.lastMessageText,
                lastMessageAt: c.lastMessageAt || existing.lastMessageAt,
              });
            } else {
              chatsMap.set(c.id, c);
            }
          });
          
          const list = Array.from(chatsMap.values());
          
          // Sort by latest message time
          list.sort((a, b) => {
            const timeA = parseTimestamp(a.lastMessageAt || a.updatedAt || a.createdAt || 0);
            const timeB = parseTimestamp(b.lastMessageAt || b.updatedAt || b.createdAt || 0);
            return timeB - timeA;
          });

          // Inject any previously cached photos immediately so there is no flicker
          const listWithCachedPhotos = list.map((c: any) => {
            const pId = getPartnerIdFromChat(c, activeUid);
            const cachedPhoto = pId ? partnerPhotoCacheRef.current[pId] : null;
            if (cachedPhoto && !c.partnerPhoto) {
              const isUserBuyer = isCurrentUserBuyer(c, activeUid);
              return {
                ...c,
                partnerPhoto: cachedPhoto,
                sellerPhoto: isUserBuyer ? cachedPhoto : (c.sellerPhoto || cachedPhoto),
                buyerPhoto: !isUserBuyer ? cachedPhoto : (c.buyerPhoto || cachedPhoto),
              };
            }
            return c;
          });

          setChats(listWithCachedPhotos);
          setLoading(false);
          setRefreshing(false);

          // Find partner IDs whose photos are not yet in cache
          const uncachedPartnerIds = Array.from(
            new Set(
              list
                .map((c: any) => getPartnerIdFromChat(c, activeUid))
                .filter((id: string) => id && id !== 'seller' && id !== 'buyer' && !partnerPhotoCacheRef.current[id])
            )
          );

          if (uncachedPartnerIds.length > 0) {
            Promise.all(
              uncachedPartnerIds.map(async (pId) => {
                try {
                  if (!pId) return { pId, photo: null };
                  const uDoc = await db.collection('users').doc(pId).get();
                  const exists = typeof uDoc?.exists === 'function' ? uDoc.exists() : Boolean(uDoc?.exists);
                  if (exists) {
                    const uData = typeof uDoc?.data === 'function' ? uDoc.data() : uDoc?.data;
                    const photo =
                      uData?.photoURL ||
                      uData?.profilePhoto ||
                      uData?.profileImageUrl ||
                      uData?.avatarUrl ||
                      uData?.photo ||
                      uData?.customPhoto ||
                      null;
                    return { pId, photo };
                  }
                } catch (_) {}
                return { pId, photo: null };
              })
            ).then((results) => {
              let hasNewPhotos = false;
              results.forEach((r) => {
                if (r.photo) {
                  partnerPhotoCacheRef.current[r.pId] = r.photo;
                  hasNewPhotos = true;
                }
              });
              if (hasNewPhotos) {
                setChats((prev) =>
                  prev.map((c) => {
                    const pId = getPartnerIdFromChat(c, activeUid);
                    const livePhoto = pId ? partnerPhotoCacheRef.current[pId] : null;
                    const isUserBuyer = isCurrentUserBuyer(c, activeUid);
                    if (livePhoto && c.partnerPhoto !== livePhoto) {
                      return {
                        ...c,
                        partnerPhoto: livePhoto,
                        sellerPhoto: isUserBuyer ? livePhoto : (c.sellerPhoto || livePhoto),
                        buyerPhoto: !isUserBuyer ? livePhoto : (c.buyerPhoto || livePhoto),
                      };
                    }
                    return c;
                  })
                );
              }
            });
          }
        } catch (err) {
          console.warn('[ChatsScreen] mergeChats error:', err);
          setLoading(false);
          setRefreshing(false);
        }
      };

      // Debounce mergeChats slightly (40ms) so simultaneous snapshots from buyer, seller, part queries collapse into a single render
      const mergeChats = () => {
        if (mergeDebounceTimerRef.current) {
          clearTimeout(mergeDebounceTimerRef.current);
        }
        mergeDebounceTimerRef.current = setTimeout(() => {
          doMergeChats();
        }, 40);
      };

      const unsubBuyer = db.collection('chats').where('buyerId', '==', activeUid).onSnapshot(
        (snapshot: any) => {
          const list: any[] = [];
          if (snapshot && typeof snapshot.forEach === 'function') {
            snapshot.forEach((doc: any) => list.push({ id: doc.id || (doc.data && doc.data().id), ...(doc.data ? doc.data() : doc) }));
          }
          buyerChatsRef.current = list;
          mergeChats();
        },
        () => {
          mergeChats();
        }
      );

      const unsubSeller = db.collection('chats').where('sellerId', '==', activeUid).onSnapshot(
        (snapshot: any) => {
          const list: any[] = [];
          if (snapshot && typeof snapshot.forEach === 'function') {
            snapshot.forEach((doc: any) => list.push({ id: doc.id || (doc.data && doc.data().id), ...(doc.data ? doc.data() : doc) }));
          }
          sellerChatsRef.current = list;
          mergeChats();
        },
        () => {
          mergeChats();
        }
      );

      const unsubPart = db.collection('chats').where('participants', 'array-contains', activeUid).onSnapshot(
        (snapshot: any) => {
          const list: any[] = [];
          if (snapshot && typeof snapshot.forEach === 'function') {
            snapshot.forEach((doc: any) => list.push({ id: doc.id || (doc.data && doc.data().id), ...(doc.data ? doc.data() : doc) }));
          }
          partChatsRef.current = list;
          mergeChats();
        },
        () => {
          mergeChats();
        }
      );

      return () => {
        try { unsubBuyer(); } catch (_) {}
        try { unsubSeller(); } catch (_) {}
        try { unsubPart(); } catch (_) {}
      };
    } catch (e) {
      console.warn('[ChatsScreen] Error in loadUserChats:', e);
      setLoading(false);
      setRefreshing(false);
      return () => {};
    }
  }, [activeUser?.uid, activeUser?.id]);

  useEffect(() => {
    setLoading(true);
    const unsub = loadUserChats();
    return () => {
      try {
        if (typeof unsub === 'function') unsub();
      } catch (_) {}
    };
  }, [loadUserChats]);

  const onRefresh = async () => {
    setRefreshing(true);
    const activeUid = activeUser?.uid || activeUser?.id;
    if (!activeUid) {
      setRefreshing(false);
      return;
    }
    try {
      const db = getFirebaseFirestore();
      if (db && typeof db.collection === 'function') {
        const [bSnap, sSnap, pSnap] = await Promise.all([
          db.collection('chats').where('buyerId', '==', activeUid).get().catch(() => null),
          db.collection('chats').where('sellerId', '==', activeUid).get().catch(() => null),
          db.collection('chats').where('participants', 'array-contains', activeUid).get().catch(() => null),
        ]);
        const bList: any[] = [];
        if (bSnap && typeof bSnap.forEach === 'function') {
          bSnap.forEach((doc: any) => bList.push({ id: doc.id, ...(doc.data ? doc.data() : doc) }));
        }
        const sList: any[] = [];
        if (sSnap && typeof sSnap.forEach === 'function') {
          sSnap.forEach((doc: any) => sList.push({ id: doc.id, ...(doc.data ? doc.data() : doc) }));
        }
        const pList: any[] = [];
        if (pSnap && typeof pSnap.forEach === 'function') {
          pSnap.forEach((doc: any) => pList.push({ id: doc.id, ...(doc.data ? doc.data() : doc) }));
        }
        buyerChatsRef.current = bList;
        sellerChatsRef.current = sList;
        partChatsRef.current = pList;

        const chatsMap = new Map<string, any>();
        const hiddenMap = await getLocalHiddenChatsMap();
        [...bList, ...sList, ...pList].forEach((c) => {
          if (!c || !c.id) return;
          const msgTime = parseTimestamp(c.lastMessageAt || c.updatedAt || c.createdAt || 0);
          if (isChatLocallyHidden(c.id, msgTime, hiddenMap)) return;
          if (Array.isArray(c.hiddenFor) && c.hiddenFor.includes(activeUid)) {
            const clearedTime = parseTimestamp(c.clearedAt?.[activeUid] || 0);
            if (clearedTime && msgTime <= clearedTime) return;
          }
          if (chatsMap.has(c.id)) {
            const existing = chatsMap.get(c.id);
            chatsMap.set(c.id, {
              ...existing,
              ...c,
              lastMessageText: c.lastMessageText || existing.lastMessageText,
              lastMessageAt: c.lastMessageAt || existing.lastMessageAt,
            });
          } else {
            chatsMap.set(c.id, c);
          }
        });
        const list = Array.from(chatsMap.values());
        list.sort((a, b) => {
          const timeA = parseTimestamp(a.lastMessageAt || a.updatedAt || a.createdAt || 0);
          const timeB = parseTimestamp(b.lastMessageAt || b.updatedAt || b.createdAt || 0);
          return timeB - timeA;
        });
        setChats(list);
      }
    } catch (e) {
      console.warn('[ChatsScreen] Refresh error:', e);
    } finally {
      setRefreshing(false);
    }
  };

  const parseTimestamp = (ts: any): number => {
    if (!ts) return Date.now();
    if (typeof ts === 'number') return ts;
    if (typeof ts === 'string') {
      const parsed = Date.parse(ts);
      return isNaN(parsed) ? Date.now() : parsed;
    }
    if (typeof ts === 'object') {
      if (typeof ts.toMillis === 'function') return ts.toMillis();
      if (typeof ts.seconds === 'number') return ts.seconds * 1000;
    }
    return Date.now();
  };

  const formatChatTime = (timestamp: any) => {
    const millis = parseTimestamp(timestamp);
    const date = new Date(millis);
    const now = new Date();
    
    const isToday =
      date.getDate() === now.getDate() &&
      date.getMonth() === now.getMonth() &&
      date.getFullYear() === now.getFullYear();

    if (isToday) {
      let hours = date.getHours();
      const minutes = date.getMinutes();
      const ampm = hours >= 12 ? 'PM' : 'AM';
      hours = hours % 12;
      hours = hours ? hours : 12;
      const minutesStr = minutes < 10 ? '0' + minutes : minutes;
      return `${hours}:${minutesStr} ${ampm}`;
    }

    const yesterday = new Date(now);
    yesterday.setDate(now.getDate() - 1);
    const isYesterday =
      date.getDate() === yesterday.getDate() &&
      date.getMonth() === yesterday.getMonth() &&
      date.getFullYear() === yesterday.getFullYear();

    if (isYesterday) {
      return translateDynamic('Yesterday');
    }

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return `${date.getDate()} ${months[date.getMonth()]}`;
  };

  const formatPrice = (price: number) => {
    if (!price) return '₹0';
    return `₹${Number(price).toLocaleString('en-IN')}`;
  };

  if (!activeUser) {
    return (
      <View style={styles.authPromptContainer}>
        <StatusBar barStyle="light-content" backgroundColor="#0066FF" />
        <View style={styles.authCard}>
          <View style={styles.authIconCircle}>
            <Icon source="message-text-lock-outline" size={36} color="#0072F5" />
          </View>
          <Text variant="titleLarge" style={styles.authTitle}>
            {translateDynamic('Sign in to View Chats')}
          </Text>
          <Text variant="bodyMedium" style={styles.authSub}>
            {translateDynamic('Connect directly with verified buyers and sellers in real-time.')}
          </Text>
          <Button
            mode="contained"
            onPress={() => navigation.navigate('Auth')}
            style={styles.signInBtn}
            buttonColor="#0072F5"
            textColor="#FFFFFF"
            icon="login"
          >
            {translateDynamic('Sign In / Register')}
          </Button>
        </View>
      </View>
    );
  }

  const filteredChats = chats.filter((chat) => {
    const activeUid = activeUser?.uid || activeUser?.id || '';
    const msgTime = parseTimestamp(chat.lastMessageAt || chat.updatedAt || chat.createdAt || 0);
    if (Array.isArray(chat.hiddenFor) && chat.hiddenFor.includes(activeUid)) {
      const clearedTime = parseTimestamp(chat.clearedAt?.[activeUid] || 0);
      if (clearedTime && msgTime <= clearedTime) {
        return false;
      }
    }
    const isUserBuyer = isCurrentUserBuyer(chat, activeUid);

    // Filter by Tab:
    // 'buy' tab: ONLY show chats where current user is BUYING from a seller
    if (activeFilter === 'buy' && !isUserBuyer) {
      return false;
    }
    // 'sell' tab: ONLY show chats where current user is SELLING to a buyer
    if (activeFilter === 'sell' && isUserBuyer) {
      return false;
    }

    const partnerName = isUserBuyer ? chat.sellerName : chat.buyerName;
    const query = searchQuery.trim().toLowerCase();
    if (!query) return true;
    return (
      (partnerName || '').toLowerCase().includes(query) ||
      (chat.buyerName || '').toLowerCase().includes(query) ||
      (chat.sellerName || '').toLowerCase().includes(query) ||
      (chat.partTitle || '').toLowerCase().includes(query) ||
      (chat.lastMessageText || '').toLowerCase().includes(query)
    );
  });

  const renderChatItem = ({ item }: { item: any }) => {
    const activeUid = activeUser?.uid || activeUser?.id || '';
    const isUserBuyer = isCurrentUserBuyer(item, activeUid);
    const partnerName = isUserBuyer
      ? item.sellerName || translateDynamic('Verified Seller')
      : item.buyerName || translateDynamic('Buyer');
    const partnerId = getPartnerIdFromChat(item, activeUid);
    const userProfilePicture = (
      item.partnerPhoto ||
      (isUserBuyer
        ? (item.sellerPhoto || item.sellerPhotoURL || item.sellerAvatar)
        : (item.buyerPhoto || item.buyerPhotoURL || item.buyerAvatar)) ||
      null
    );

    const isLastSenderMe = Boolean(item.lastSenderId && (item.lastSenderId === activeUid || matchesUser(item.lastSenderId, activeUser)));
    const unreadCount = isLastSenderMe
      ? 0
      : (typeof item.unreadCount?.[activeUid] === 'number'
          ? item.unreadCount[activeUid]
          : (typeof item.unreadCount === 'number'
              ? item.unreadCount
              : (item.unread ? 1 : 0)));

    const handleDeleteChat = (chatItem: any) => {
      Alert.alert(
        translateDynamic('Delete Conversation'),
        `${translateDynamic('Are you sure you want to delete the chat with')} ${partnerName}?`,
        [
          { text: translateDynamic('Cancel'), style: 'cancel' },
          {
            text: translateDynamic('Delete'),
            style: 'destructive',
            onPress: async () => {
              try {
                const now = Date.now();
                // Immediate local UI update
                setChats((prev) => prev.filter((c) => c.id !== chatItem.id));

                if (chatItem.id) {
                  await addLocalHiddenChatId(chatItem.id, now);
                }
                const db = getFirebaseFirestore();
                if (db && typeof db.collection === 'function' && chatItem.id) {
                  const chatRef = db.collection('chats').doc(chatItem.id);
                  const snap = await chatRef.get();
                  const exists = typeof snap?.exists === 'function' ? snap.exists() : Boolean(snap?.exists);
                  const sData = typeof snap?.data === 'function' ? snap.data() : snap?.data;
                  const currentHidden = exists ? (sData?.hiddenFor || []) : [];
                  const nextHidden = Array.from(new Set([...currentHidden, activeUid]));
                  
                  await chatRef.set({
                    hiddenFor: nextHidden,
                    clearedAt: {
                      ...(sData?.clearedAt || {}),
                      [activeUid]: now,
                    },
                  }, { merge: true });

                  // Also delete any existing notification documents for this chat so they never resurrect or trigger unread badges
                  try {
                    const notifQuery = await db.collection('notifications')
                      .where('chatId', '==', chatItem.id)
                      .where('recipientId', '==', activeUid)
                      .get();
                    if (notifQuery && typeof notifQuery.forEach === 'function') {
                      notifQuery.forEach(async (nDoc: any) => {
                        try {
                          if (typeof nDoc?.ref?.delete === 'function') {
                            await nDoc.ref.delete();
                          } else if (nDoc?.id) {
                            await db.collection('notifications').doc(nDoc.id).delete();
                          }
                        } catch (_) {}
                      });
                    }
                  } catch (_) {}
                }
              } catch (err: any) {
                console.warn('[ChatsScreen] Delete error:', err);
              }
            },
          },
        ]
      );
    };

    return (
      <ScalePressable
        scaleTo={0.96}
        style={styles.chatCard}
        onLongPress={() => handleDeleteChat(item)}
        onPress={() => {
          if (item.id) {
            removeLocalHiddenChatId(item.id);
            if (activeUid) {
              markNotificationAsRead(`${item.id}_${activeUid}`);
            }
          }
          navigation.navigate('ChatRoom', {
            chatId: item.id,
            partnerId: partnerId,
            partnerName: partnerName,
            partnerPhoto: userProfilePicture,
            part: {
              id: item.partId,
              title: item.partTitle || 'Spare Part',
              imageUrl: item.partImageUrl,
              price: item.partPrice || 0,
              sellerId: item.sellerId,
              sellerName: item.sellerName,
            },
            chat: {
              ...item,
              partnerPhoto: userProfilePicture,
              sellerPhoto: isUserBuyer ? (userProfilePicture || item.sellerPhoto) : item.sellerPhoto,
              buyerPhoto: !isUserBuyer ? (userProfilePicture || item.buyerPhoto) : item.buyerPhoto,
            },
          });
        }}
      >
        {/* User Profile Avatar */}
        <View style={styles.avatarContainer}>
          <UserAvatar
            photoUrl={userProfilePicture}
            name={partnerName}
            size={48}
            borderWidth={1.5}
            borderColor="#E2E8F0"
          />

          {/* Small Product Part Thumbnail Badge */}
          {item.partImageUrl ? (
            <View style={styles.partBadgeContainer}>
              <Image source={{ uri: item.partImageUrl }} style={styles.partBadgeImage} />
            </View>
          ) : null}
        </View>

        {/* Middle Content: Name, Role Badge, Part Title & Last Message */}
        <View style={styles.chatInfo}>
          <View style={styles.nameAndBadgeRow}>
            <Text numberOfLines={1} style={styles.partnerNameText}>
              {partnerName}
            </Text>
            <View
              style={[
                styles.roleBadge,
                isUserBuyer ? styles.roleBadgeBuy : styles.roleBadgeSell,
              ]}
            >
              <Text
                style={[
                  styles.roleBadgeText,
                  isUserBuyer ? styles.roleBadgeTextBuy : styles.roleBadgeTextSell,
                ]}
              >
                {isUserBuyer ? translateDynamic('Buy') : translateDynamic('Sell')}
              </Text>
            </View>
          </View>

          {item.partTitle ? (
            <Text numberOfLines={1} style={styles.partTitleSub}>
              {item.partTitle}
            </Text>
          ) : null}

          <Text numberOfLines={1} style={styles.lastMessageText}>
            {item.lastMessageText || translateDynamic('Tap to start conversation...')}
          </Text>
        </View>

        {/* Right Content: Timestamp & Blue Unread Count */}
        <View style={styles.metaContainer}>
          <Text style={styles.timestampText}>
            {formatChatTime(item.lastMessageAt || item.updatedAt || item.createdAt)}
          </Text>
          {unreadCount > 0 ? (
            <View style={styles.unreadCircleBadge}>
              <Text style={styles.unreadCircleBadgeText}>
                {unreadCount > 99 ? '99+' : unreadCount}
              </Text>
            </View>
          ) : (
            <View style={{ height: 20 }} />
          )}
        </View>
      </ScalePressable>
    );
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#0066FF" />

      {/* Royal Blue Top Header Bar matching Home Screen */}
      <View style={styles.header}>
        {/* Row 1: Brand title Auto Parts India */}
        <View style={styles.brandRow}>
          <Text style={styles.brandAutoParts}>Auto Parts </Text>
          <Text style={styles.brandIndia}>India</Text>
        </View>

        {/* Row 2: Chats Title & Icons */}
        <View style={styles.titleRow}>
          <Text style={styles.headerMainTitle}>{translateDynamic('Chats')}</Text>
          <View style={styles.headerActionIcons}>
            <TouchableOpacity
              style={styles.headerIconBtn}
              onPress={() => setShowSearch(!showSearch)}
              activeOpacity={0.7}
            >
              <Icon source="magnify" size={24} color="#FFFFFF" />
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.headerIconBtn}
              onPress={onRefresh}
              activeOpacity={0.7}
            >
              <Icon source="dots-vertical" size={24} color="#FFFFFF" />
            </TouchableOpacity>
          </View>
        </View>

        {/* Expandable Search Input */}
        {showSearch && (
          <View style={styles.searchbarWrap}>
            <Searchbar
              placeholder={translateDynamic('Search chats or parts...')}
              onChangeText={setSearchQuery}
              value={searchQuery}
              style={styles.searchbar}
              inputStyle={styles.searchInput}
              iconColor="#FFFFFF"
              placeholderTextColor="rgba(255, 255, 255, 0.7)"
            />
          </View>
        )}

        {/* Row 3: Filter Tabs: All, Buy, Sell */}
        <View style={styles.filterTabsRow}>
          <TouchableOpacity
            style={[
              styles.filterTabPill,
              activeFilter === 'all' ? styles.filterTabPillActive : styles.filterTabPillInactive,
            ]}
            onPress={() => setActiveFilter('all')}
            activeOpacity={0.8}
          >
            <Text
              style={[
                styles.filterTabText,
                activeFilter === 'all' ? styles.filterTabTextActive : styles.filterTabTextInactive,
              ]}
            >
              {translateDynamic('All')}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[
              styles.filterTabPill,
              activeFilter === 'buy' ? styles.filterTabPillActive : styles.filterTabPillInactive,
            ]}
            onPress={() => setActiveFilter('buy')}
            activeOpacity={0.8}
          >
            <Text
              style={[
                styles.filterTabText,
                activeFilter === 'buy' ? styles.filterTabTextActive : styles.filterTabTextInactive,
              ]}
            >
              {translateDynamic('Buy')}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[
              styles.filterTabPill,
              activeFilter === 'sell' ? styles.filterTabPillActive : styles.filterTabPillInactive,
            ]}
            onPress={() => setActiveFilter('sell')}
            activeOpacity={0.8}
          >
            <Text
              style={[
                styles.filterTabText,
                activeFilter === 'sell' ? styles.filterTabTextActive : styles.filterTabTextInactive,
              ]}
            >
              {translateDynamic('Sell')}
            </Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Main White Curved List Container */}
      <View style={styles.sheetContainer}>
        {loading ? (
          <ChatListSkeleton count={6} />
        ) : (
          <FlatList
            data={filteredChats}
            keyExtractor={(item) => item.id}
            renderItem={renderChatItem}
            ItemSeparatorComponent={() => <Divider style={styles.divider} />}
            contentContainerStyle={styles.listContent}
            keyboardShouldPersistTaps="handled"
            keyboardDismissMode="on-drag"
            showsVerticalScrollIndicator={false}
            scrollEventThrottle={16}
            bounces={true}
            alwaysBounceVertical={true}
            decelerationRate="normal"
            overScrollMode="never"
            removeClippedSubviews={Platform.OS === 'android'}
            initialNumToRender={10}
            maxToRenderPerBatch={10}
            windowSize={7}
            updateCellsBatchingPeriod={50}
            refreshControl={
              <RefreshControl
                refreshing={refreshing}
                onRefresh={onRefresh}
                colors={['#0072F5']}
                tintColor="#0072F5"
              />
            }
            ListEmptyComponent={
              <View style={styles.emptyContainer}>
                <View style={styles.emptyIconCircle}>
                  <Icon
                    source={
                      activeFilter === 'buy'
                        ? 'shopping-outline'
                        : activeFilter === 'sell'
                        ? 'tag-outline'
                        : 'chat-outline'
                    }
                    size={44}
                    color="#94A3B8"
                  />
                </View>
                <Text variant="titleMedium" style={styles.emptyTitle}>
                  {searchQuery
                    ? translateDynamic('No matching conversations found')
                    : activeFilter === 'buy'
                    ? translateDynamic('No buying chats yet')
                    : activeFilter === 'sell'
                    ? translateDynamic('No selling inquiries yet')
                    : translateDynamic('No active conversations yet')}
                </Text>
                <Text variant="bodySmall" style={styles.emptySub}>
                  {searchQuery
                    ? translateDynamic('Try a different search query for parts or sellers.')
                    : activeFilter === 'buy'
                    ? translateDynamic('When you chat with sellers to buy auto spare parts, those conversations appear here.')
                    : activeFilter === 'sell'
                    ? translateDynamic('When buyers send inquiries for parts you posted for sale, those messages appear here.')
                    : translateDynamic('Browse spare parts and click "Chat" to contact sellers in real-time.')}
                </Text>
                {!searchQuery && (
                  <Button
                    mode="contained-tonal"
                    onPress={() => {
                      if (activeFilter === 'sell') {
                        navigation.navigate('MainTabs', { screen: 'Sell' });
                      } else {
                        navigation.navigate('MainTabs', { screen: 'HomeTab' });
                      }
                    }}
                    style={{ marginTop: 16 }}
                    buttonColor="#EFF6FF"
                    textColor="#0072F5"
                    icon={activeFilter === 'sell' ? 'plus-circle' : 'car-search'}
                  >
                    {activeFilter === 'sell'
                      ? translateDynamic('Post an Ad to Sell Parts')
                      : translateDynamic('Browse Spare Parts to Buy')}
                  </Button>
                )}
              </View>
            }
          />
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0066FF',
  },
  header: {
    backgroundColor: '#0066FF',
    paddingTop: Platform.OS === 'android' ? 14 : 8,
    paddingHorizontal: 16,
    paddingBottom: 16,
  },
  brandRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 10,
  },
  brandAutoParts: {
    fontSize: 18,
    fontWeight: '800',
    color: '#FFFFFF',
    letterSpacing: 0.2,
  },
  brandIndia: {
    fontSize: 18,
    fontWeight: '800',
    color: '#FF6B00',
    letterSpacing: 0.2,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 14,
  },
  headerMainTitle: {
    fontSize: 28,
    fontWeight: '800',
    color: '#FFFFFF',
  },
  headerActionIcons: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  headerIconBtn: {
    width: 38,
    height: 38,
    borderRadius: 19,
    justifyContent: 'center',
    alignItems: 'center',
  },
  headerProfileBtn: {
    width: 34,
    height: 34,
    borderRadius: 17,
    justifyContent: 'center',
    alignItems: 'center',
    marginLeft: 2,
  },
  searchbarWrap: {
    marginBottom: 12,
  },
  searchbar: {
    backgroundColor: 'rgba(255, 255, 255, 0.16)',
    borderRadius: 14,
    height: 42,
    elevation: 0,
    borderWidth: 0,
  },
  searchInput: {
    fontSize: 13,
    color: '#FFFFFF',
    minHeight: 0,
  },
  filterTabsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  filterTabPill: {
    paddingHorizontal: 22,
    paddingVertical: 8,
    borderRadius: 20,
  },
  filterTabPillActive: {
    backgroundColor: '#0072F5',
  },
  filterTabPillInactive: {
    backgroundColor: 'rgba(255, 255, 255, 0.12)',
  },
  filterTabText: {
    fontSize: 13,
    fontWeight: '700',
  },
  filterTabTextActive: {
    color: '#FFFFFF',
  },
  filterTabTextInactive: {
    color: '#CBD5E1',
  },
  sheetContainer: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    overflow: 'hidden',
  },
  listContent: {
    paddingVertical: 6,
    flexGrow: 1,
  },
  chatCard: {
    flexDirection: 'row',
    paddingVertical: 14,
    paddingHorizontal: 16,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
  },
  avatarContainer: {
    marginRight: 14,
    position: 'relative',
  },
  avatarImage: {
    width: 52,
    height: 52,
    borderRadius: 26,
    backgroundColor: '#F1F5F9',
  },
  avatarPlaceholder: {
    width: 52,
    height: 52,
    borderRadius: 26,
    backgroundColor: '#0072F5',
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarInitial: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  partBadgeContainer: {
    position: 'absolute',
    bottom: -2,
    right: -2,
    width: 22,
    height: 22,
    borderRadius: 11,
    borderWidth: 2,
    borderColor: '#FFFFFF',
    overflow: 'hidden',
    backgroundColor: '#0F172A',
  },
  partBadgeImage: {
    width: '100%',
    height: '100%',
    resizeMode: 'cover',
  },
  chatInfo: {
    flex: 1,
    justifyContent: 'center',
    marginRight: 12,
  },
  nameAndBadgeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 2,
  },
  partnerNameText: {
    fontSize: 16,
    fontWeight: '700',
    color: '#0F172A',
    flex: 1,
    marginRight: 8,
  },
  roleBadge: {
    paddingHorizontal: 8,
    paddingVertical: 2.5,
    borderRadius: 6,
  },
  roleBadgeBuy: {
    backgroundColor: '#EFF6FF',
  },
  roleBadgeSell: {
    backgroundColor: '#FFFBEB',
  },
  roleBadgeText: {
    fontSize: 11,
    fontWeight: '700',
    textTransform: 'uppercase',
    letterSpacing: 0.3,
  },
  roleBadgeTextBuy: {
    color: '#0066FF',
  },
  roleBadgeTextSell: {
    color: '#D97706',
  },
  partTitleSub: {
    fontSize: 12,
    fontWeight: '600',
    color: '#0066FF',
    marginBottom: 3,
  },
  lastMessageText: {
    fontSize: 14,
    color: '#64748B',
    lineHeight: 18,
  },
  metaContainer: {
    alignItems: 'flex-end',
    justifyContent: 'space-between',
    height: 44,
  },
  timestampText: {
    fontSize: 12,
    color: '#64748B',
    fontWeight: '500',
  },
  unreadCircleBadge: {
    backgroundColor: '#0072F5',
    minWidth: 20,
    height: 20,
    borderRadius: 10,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 6,
  },
  unreadCircleBadgeText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '800',
  },
  divider: {
    backgroundColor: '#F1F5F9',
    height: 1,
    marginLeft: 82,
  },
  centerContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 32,
  },
  loadingText: {
    marginTop: 12,
    fontSize: 13,
    color: '#64748B',
    fontWeight: '500',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 64,
    paddingHorizontal: 32,
  },
  emptyIconCircle: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#EFF6FF',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
  },
  emptyTitle: {
    fontWeight: '700',
    color: '#1E293B',
    textAlign: 'center',
    marginBottom: 6,
  },
  emptySub: {
    color: '#64748B',
    textAlign: 'center',
    lineHeight: 18,
    maxWidth: 280,
  },
  authPromptContainer: {
    flex: 1,
    backgroundColor: '#0066FF',
    justifyContent: 'center',
    padding: 24,
  },
  authCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 24,
    padding: 28,
    alignItems: 'center',
    elevation: 6,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 10,
  },
  authIconCircle: {
    width: 72,
    height: 72,
    borderRadius: 36,
    backgroundColor: 'rgba(0, 114, 245, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
  },
  authTitle: {
    fontWeight: '800',
    color: '#0F172A',
    textAlign: 'center',
    marginBottom: 8,
  },
  authSub: {
    color: '#64748B',
    textAlign: 'center',
    marginBottom: 24,
    lineHeight: 20,
  },
  signInBtn: {
    width: '100%',
    borderRadius: 14,
    paddingVertical: 4,
  },
});
