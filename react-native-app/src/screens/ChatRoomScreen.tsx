import React, { useState, useEffect, useRef, useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  View,
  FlatList,
  KeyboardAvoidingView,
  Platform,
  PermissionsAndroid,
  StyleSheet,
  Image,
  Alert,
  ScrollView,
  TouchableOpacity,
  Modal,
  StatusBar,
  Linking,
  TextInput,
  Text,
  BackHandler,
  Animated,
  useWindowDimensions,
} from 'react-native';
import { Icon, ActivityIndicator, Appbar } from 'react-native-paper';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { getFirebaseFirestore, getCurrentUser } from '../services/firebase';
import { sendChatMessageNotification, markNotificationAsRead, markChatNotificationsAsRead, addLocalHiddenChatId, removeLocalHiddenChatId } from '../services/notifications';
import { promptImageSourceDialog } from '../services/imagePickerService';
import { uploadImageToCloudinary, deleteImageFromCloudinary } from '../services/cloudinary';
import { useLanguage } from '../context/LanguageContext';
import { LanguageSelectorModal } from '../components/LanguageSelectorModal';
import { TypingIndicator } from '../components/animations';
import { MakeOfferModal } from '../components/MakeOfferModal';
import { AudioVoiceNotePlayer } from '../components/AudioVoiceNotePlayer';
import { chatSounds } from '../utils/chatSoundEffects';
import { ScalePressable } from '../components/animations/ScalePressable';

interface ChatMessage {
  id: string;
  senderId: string;
  senderName: string;
  senderPhoto?: string;
  text?: string;
  imageUrl?: string | null;
  createdAt: number | any;
  status?: 'pending' | 'sent' | 'delivered' | 'read' | 'failed';
  readBy?: string[];
  isDeleted?: boolean;
  deletedFor?: string[];
  type?: 'text' | 'offer' | 'audio';
  offerPrice?: number;
  offerStatus?: 'pending' | 'accepted' | 'rejected';
  audioDuration?: string;
  audioUrl?: string | null;
}

export default function ChatRoomScreen({ route, navigation, user: initialUser }: any) {
  const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = useWindowDimensions();
  const insets = useSafeAreaInsets();
  const { language, t, translateDynamic } = useLanguage();

  const {
    chatId: routeChatId,
    part: routePart,
    chat: routeChat,
    partnerId: routePartnerId,
    partnerPhoto: routePartnerPhoto,
    partnerName: routePartnerName,
  } = route.params || {};
  const activeUser = initialUser || getCurrentUser();
  const currentUid = activeUser?.uid || activeUser?.id || 'guest';
  const currentName = activeUser?.displayName || activeUser?.name || activeUser?.email?.split('@')[0] || 'User';
  const currentUserPhoto = activeUser?.photoURL || activeUser?.profilePhoto || '';

  const getCleanId = (val: any): string => {
    if (!val) return '';
    if (typeof val === 'string') return val;
    if (typeof val === 'object') return val.id || val.uid || val._id || '';
    return String(val);
  };

  // Determine item & chatId
  const part = routePart || (routeChat ? {
    id: routeChat.partId,
    title: routeChat.partTitle,
    imageUrl: routeChat.partImageUrl,
    price: routeChat.partPrice,
    sellerId: routeChat.sellerId,
    sellerName: routeChat.sellerName,
    sellerPhoto: routeChat.sellerPhoto,
    contactPhone: routeChat.contactPhone,
  } : null);

  const sellerUidFromPart = getCleanId(part?.sellerId) || getCleanId(part?.userId) || getCleanId(part?.ownerId);
  const chatId = routeChatId || (part && currentUid ? `${currentUid}_${sellerUidFromPart || 'seller'}_${part.id || 'item'}` : 'default_chat');

  // Loaded chat document state from Firestore (in case routeChat wasn't fully populated)
  const [remoteChatDoc, setRemoteChatDoc] = useState<any>(null);

  // Subscribe to the chat document itself so participants/names/photos are always accurate in real-time
  useEffect(() => {
    if (!chatId) return;
    let unsub = () => {};
    try {
      const db = getFirebaseFirestore();
      if (db && typeof db.collection === 'function') {
        unsub = db.collection('chats').doc(chatId).onSnapshot((docSnap: any) => {
          if (docSnap && docSnap.exists) {
            const data = docSnap.data();
            setRemoteChatDoc(data);
          }
        }, () => {});
      }
    } catch (_) {}
    return () => { try { unsub(); } catch (_) {} };
  }, [chatId]);

  // Instantly clear unread count for current user when entering chat room
  useEffect(() => {
    if (!chatId || !currentUid) return;

    try {
      const db = getFirebaseFirestore();
      if (db && typeof db.collection === 'function') {
        db.collection('chats').doc(chatId).get().then((docSnap: any) => {
          if (docSnap && docSnap.exists) {
            const data = docSnap.data();
            const unreadMap = { ...(data?.unreadCount || {}) };
            if (unreadMap[currentUid] > 0 || data?.unread === true) {
              unreadMap[currentUid] = 0;
              const remainingUnread = Object.entries(unreadMap).some(([k, v]) => k !== currentUid && Number(v) > 0);
              db.collection('chats').doc(chatId).set({
                unreadCount: unreadMap,
                unread: remainingUnread,
              }, { merge: true }).catch(() => {});
            }
          }
        }).catch(() => {});
      }
    } catch (_) {}

    markChatNotificationsAsRead(chatId, currentUid);
  }, [chatId, currentUid]);

  const mergedChat = remoteChatDoc || routeChat;

  const buyerId = getCleanId(mergedChat?.buyerId);
  const sellerId = getCleanId(mergedChat?.sellerId) || getCleanId(part?.sellerId);

  // Partner Identification logic
  const isCurrentUserBuyer = sellerId
    ? sellerId !== currentUid
    : (buyerId ? buyerId === currentUid : true);

  // Compute partnerId accurately
  let resolvedPartnerId = getCleanId(routePartnerId);
  if (!resolvedPartnerId || resolvedPartnerId === 'seller' || resolvedPartnerId === 'buyer') {
    if (sellerId && sellerId !== currentUid) {
      resolvedPartnerId = sellerId;
    } else if (buyerId && buyerId !== currentUid) {
      resolvedPartnerId = buyerId;
    } else if (Array.isArray(mergedChat?.participants)) {
      const other = mergedChat.participants.find((p: any) => {
        const pid = getCleanId(p);
        return pid && pid !== currentUid && pid !== 'seller' && pid !== 'buyer';
      });
      if (other) resolvedPartnerId = getCleanId(other);
    }
  }

  const partnerId = resolvedPartnerId || (isCurrentUserBuyer ? sellerId : buyerId) || 'seller';

  const partnerName = routePartnerName || (mergedChat
    ? (isCurrentUserBuyer ? (mergedChat.sellerName || 'Verified Seller') : (mergedChat.buyerName || 'Buyer'))
    : (part ? (part.sellerName || 'Verified Seller') : 'Seller'));
  const partnerRole = isCurrentUserBuyer ? 'Seller' : 'Buyer';

  const partnerPhoto = (
    routePartnerPhoto ||
    mergedChat?.partnerPhoto ||
    (isCurrentUserBuyer
      ? (mergedChat?.sellerPhoto || mergedChat?.sellerPhotoURL || mergedChat?.sellerAvatar)
      : (mergedChat?.buyerPhoto || mergedChat?.buyerPhotoURL || mergedChat?.buyerAvatar)) ||
    part?.sellerPhoto ||
    part?.sellerPhotoURL ||
    ''
  );

  const [livePartnerPhoto, setLivePartnerPhoto] = useState<string | null>(partnerPhoto || null);

  useEffect(() => {
    if (!partnerId || partnerId === 'seller' || partnerId === 'buyer') return;
    let unsub = () => {};
    try {
      const db = getFirebaseFirestore();
      if (db && typeof db.collection === 'function') {
        unsub = db.collection('users').doc(partnerId).onSnapshot((docSnap: any) => {
          const exists = typeof docSnap?.exists === 'function' ? docSnap.exists() : Boolean(docSnap?.exists);
          if (exists) {
            const uData = typeof docSnap?.data === 'function' ? docSnap.data() : docSnap?.data;
            const photo =
              uData?.photoURL ||
              uData?.profilePhoto ||
              uData?.profileImageUrl ||
              uData?.avatarUrl ||
              uData?.photo ||
              uData?.customPhoto ||
              null;
            if (photo) {
              setLivePartnerPhoto(photo);
            }
          }
        }, () => {});
      }
    } catch (_) {}
    return () => { try { unsub(); } catch (_) {} };
  }, [partnerId]);

  const effectivePartnerPhoto = livePartnerPhoto || partnerPhoto || null;

  // State Management
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [inputText, setInputText] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [uploadingImageUri, setUploadingImageUri] = useState<string | null>(null);
  const [showLanguageModal, setShowLanguageModal] = useState(false);
  const [showOptionsMenu, setShowOptionsMenu] = useState(false);
  const [showEmojiPicker, setShowEmojiPicker] = useState(false);
  const [selectedPreviewImage, setSelectedPreviewImage] = useState<string | null>(null);

  // Feature State: Make Offer & Audio Voice Notes
  const [showMakeOfferModal, setShowMakeOfferModal] = useState(false);
  const [isRecordingAudio, setIsRecordingAudio] = useState(false);
  const [recordingSeconds, setRecordingSeconds] = useState(0);
  const [recordedAudioPreview, setRecordedAudioPreview] = useState<{
    audioUrl: string;
    durationStr: string;
    seconds: number;
  } | null>(null);
  const [isPreviewPlaying, setIsPreviewPlaying] = useState(false);
  const [previewPlaybackTime, setPreviewPlaybackTime] = useState<string | null>(null);

  const recordingTimerRef = useRef<NodeJS.Timeout | null>(null);
  const mediaRecorderRef = useRef<any>(null);
  const audioChunksRef = useRef<Blob[]>([]);
  const mediaStreamRef = useRef<any>(null);
  const recordingStartTimeRef = useRef<number>(0);
  const previewAudioRef = useRef<any>(null);
  const previewTimerRef = useRef<any>(null);
  const micScaleAnim = useRef(new Animated.Value(1)).current;
  const hasProcessedInitialOffer = useRef(false);

  // Pulse animation while user is pressing and holding the mic button
  useEffect(() => {
    if (isRecordingAudio) {
      const pulse = Animated.loop(
        Animated.sequence([
          Animated.timing(micScaleAnim, {
            toValue: 1.25,
            duration: 350,
            useNativeDriver: true,
          }),
          Animated.timing(micScaleAnim, {
            toValue: 1.0,
            duration: 350,
            useNativeDriver: true,
          }),
        ])
      );
      pulse.start();
      return () => pulse.stop();
    } else {
      micScaleAnim.stopAnimation();
      micScaleAnim.setValue(1);
    }
  }, [isRecordingAudio]);

  // Clean up audio references on unmount
  useEffect(() => {
    return () => {
      if (previewAudioRef.current) {
        try {
          previewAudioRef.current.pause();
        } catch (_) {}
        previewAudioRef.current = null;
      }
      if (previewTimerRef.current) clearInterval(previewTimerRef.current);
      if (recordingTimerRef.current) clearInterval(recordingTimerRef.current);
      if (mediaStreamRef.current) {
        try {
          mediaStreamRef.current.getTracks().forEach((track: any) => track.stop());
        } catch (_) {}
      }
    };
  }, []);

  // Auto Send Offer if coming from ProductDetailScreen
  useEffect(() => {
    if (route.params?.initialOfferPrice && !hasProcessedInitialOffer.current) {
      hasProcessedInitialOffer.current = true;
      handleSubmitOffer(Number(route.params.initialOfferPrice));
    }
  }, [route.params?.initialOfferPrice]);

  // Unified Back Navigation Logic
  const handleBackNavigation = useCallback(() => {
    if (navigation.canGoBack()) {
      navigation.goBack();
    } else {
      navigation.navigate('MainTabs', { screen: 'ChatsTab' });
    }
    return true; // Prevent default behavior
  }, [navigation]);

  useEffect(() => {
    const backHandler = BackHandler.addEventListener('hardwareBackPress', handleBackNavigation);
    return () => backHandler.remove();
  }, [handleBackNavigation]);

  // Presence & Typing State
  const [partnerPresence, setPartnerPresence] = useState<{ online: boolean; lastSeen: number }>({
    online: false,
    lastSeen: 0,
  });
  const [partnerIsTyping, setPartnerIsTyping] = useState(false);

  const flatListRef = useRef<FlatList>(null);
  const isNearBottomRef = useRef(true);
  const handleChatScroll = useCallback((event: any) => {
    const { layoutMeasurement, contentOffset, contentSize } = event.nativeEvent;
    const paddingToBottom = 120;
    const isClose = layoutMeasurement.height + contentOffset.y >= contentSize.height - paddingToBottom;
    isNearBottomRef.current = isClose;
  }, []);
  const typingTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  // 1. Subscribe to Chat Messages Real-time (Firestore query)
  useEffect(() => {
    if (!chatId) return;

    removeLocalHiddenChatId(chatId);
    if (currentUid) {
      markChatNotificationsAsRead(chatId, currentUid);
    }

    let unsubscribe = () => {};
    try {
      const db = getFirebaseFirestore();
      if (!db || typeof db.collection !== 'function') return;

      const messagesRef = db.collection('chats').doc(chatId).collection('messages');

      unsubscribe = messagesRef.onSnapshot(
        (snapshot: any) => {
          const list: ChatMessage[] = [];
          if (snapshot && typeof snapshot.forEach === 'function') {
            snapshot.forEach((doc: any) => {
              const data = doc.data ? doc.data() : doc;
              list.push({
                id: doc.id || data.id,
                ...data,
                status: data.status || 'read',
              });
            });
          }

          // Sort messages reliably by timestamp client-side so no messages are dropped
          list.sort((a, b) => {
            const timeA = parseTimestamp(a.createdAt || a.createdAt);
            const timeB = parseTimestamp(b.createdAt || b.createdAt);
            return timeA - timeB;
          });

          setMessages(list);

          // If there are unread messages sent by the partner, mark them as read and reset unread status
          const hasIncomingUnread = list.some((msg) => msg.senderId !== currentUid && msg.status !== 'read');
          if (hasIncomingUnread) {
            list.forEach(async (msg) => {
              if (msg.senderId !== currentUid && msg.status !== 'read') {
                try {
                  await messagesRef.doc(msg.id).set({ status: 'read' }, { merge: true });
                } catch (_) {}
              }
            });

            try {
              const currentUnreadMap = mergedChat?.unreadCount || {};
              const newUnreadMap = { ...currentUnreadMap };
              newUnreadMap[currentUid] = 0;
              const remainingUnread = Object.entries(newUnreadMap).some(([k, v]) => k !== currentUid && Number(v) > 0);
              
              db.collection('chats').doc(chatId).set({
                unreadCount: newUnreadMap,
                unread: remainingUnread,
              }, { merge: true });
              markChatNotificationsAsRead(chatId, currentUid);
            } catch (_) {}
          }
        },
        (err: any) => {
          console.warn('[ChatRoomScreen] Messages snapshot error:', err);
        }
      );
    } catch (e) {
      console.warn('[ChatRoomScreen] Exception in messages listener:', e);
    }

    return () => {
      try {
        unsubscribe();
      } catch (_) {}
    };
  }, [chatId, currentUid]);

  // 2. Subscribe to Partner Typing Status & Presence Real-time
  useEffect(() => {
    if (!chatId || !partnerId) return;

    let unsubTyping = () => {};
    let unsubPresence = () => {};

    try {
      const db = getFirebaseFirestore();
      if (db && typeof db.collection === 'function') {
        const typingDocRef = db.collection('chats').doc(chatId).collection('typing').doc(partnerId);
        unsubTyping = typingDocRef.onSnapshot(
          (docSnap: any) => {
            const data = docSnap?.data ? docSnap.data() : docSnap;
            if (data && data.isTyping) {
              const age = Date.now() - (data.createdAt || 0);
              setPartnerIsTyping(age < 8000);
            } else {
              setPartnerIsTyping(false);
            }
          },
          (err: any) => console.warn('[ChatRoomScreen] Typing error:', err)
        );

        const presenceDocRef = db.collection('presence').doc(partnerId);
        unsubPresence = presenceDocRef.onSnapshot(
          (docSnap: any) => {
            const data = docSnap?.data ? docSnap.data() : (docSnap?.exists ? docSnap.data() : null);
            if (data && typeof data === 'object') {
              const lastSeen = data.lastSeen || 0;
              const active = data.online === true && (Date.now() - lastSeen < 60000);
              setPartnerPresence({
                online: active,
                lastSeen: lastSeen,
              });
            } else {
              // Try fallback to users/{partnerId} collection if presence doc doesn't exist
              db.collection('users').doc(partnerId).get().then((userSnap: any) => {
                const uData = userSnap?.data ? userSnap.data() : null;
                if (uData && uData.online === true && (Date.now() - (uData.lastSeen || 0) < 60000)) {
                  setPartnerPresence({
                    online: true,
                    lastSeen: uData.lastSeen || Date.now(),
                  });
                } else {
                  setPartnerPresence({
                    online: false,
                    lastSeen: uData?.lastSeen || 0,
                  });
                }
              }).catch(() => {
                setPartnerPresence({ online: false, lastSeen: 0 });
              });
            }
          },
          (err: any) => {
            console.warn('[ChatRoomScreen] Presence error:', err);
            setPartnerPresence({ online: false, lastSeen: 0 });
          }
        );
      }
    } catch (e) {
      console.warn('[ChatRoomScreen] Exception in typing/presence:', e);
    }

    return () => {
      try {
        unsubTyping();
        unsubPresence();
      } catch (_) {}
    };
  }, [chatId, partnerId]);

  // Update Current User's Typing Status
  const emitTyping = useCallback(
    async (isTyping: boolean) => {
      if (!chatId || !currentUid) return;
      try {
        const db = getFirebaseFirestore();
        if (db && typeof db.collection === 'function') {
          await db
            .collection('chats')
            .doc(chatId)
            .collection('typing')
            .doc(currentUid)
            .set({
              isTyping,
              timestamp: Date.now(),
              userId: currentUid,
            }, { merge: true });
        }
      } catch (_) {}
    },
    [chatId, currentUid]
  );

  const handleInputChange = (text: string) => {
    setInputText(text);

    if (text.trim().length > 0) {
      emitTyping(true);
      if (typingTimeoutRef.current) clearTimeout(typingTimeoutRef.current);
      typingTimeoutRef.current = setTimeout(() => {
        emitTyping(false);
      }, 3000);
    } else {
      emitTyping(false);
    }
  };

  // 3. Send Message Logic
  const executeSend = async (textToSend: string, imageUrl?: string | null, extraData?: Record<string, any>) => {
    const cleanText = textToSend ? textToSend.trim() : '';
    if (!cleanText && !imageUrl && !extraData) return;
    if (!chatId || !activeUser) {
      Alert.alert('Sign In Required', 'Please sign in to message this seller.');
      return;
    }

    const now = Date.now();

    setInputText('');
    emitTyping(false);
    setIsSending(true);

    setTimeout(() => {
      flatListRef.current?.scrollToEnd({ animated: true });
    }, 100);

    try {
      const db = getFirebaseFirestore();
      if (!db || typeof db.collection !== 'function') {
        throw new Error('Firestore is not initialized');
      }

      const messagesRef = db.collection('chats').doc(chatId).collection('messages');

      const msgPayload: any = {
        senderId: currentUid,
        senderName: currentName,
        senderPhoto: currentUserPhoto,
        text: cleanText,
        imageUrl: imageUrl || null,
        createdAt: now,
        status: 'sent',
        type: extraData?.type || 'text',
        ...(extraData || {}),
      };

      const docRef = await messagesRef.add(msgPayload);

      // Update parent Chat document for inbox previews
      const resolvedBuyerId = mergedChat?.buyerId || (isCurrentUserBuyer ? currentUid : partnerId);
      const resolvedBuyerName = mergedChat?.buyerName || (isCurrentUserBuyer ? currentName : partnerName);
      const resolvedSellerId = mergedChat?.sellerId || (isCurrentUserBuyer ? partnerId : currentUid);
      const resolvedSellerName = mergedChat?.sellerName || (isCurrentUserBuyer ? partnerName : currentName);
      const participantsList = Array.from(new Set([currentUid, partnerId, resolvedBuyerId, resolvedSellerId].filter(Boolean)));

      const isMeIdentifier = (idVal: any): boolean => {
        if (!idVal) return false;
        const clean = String(idVal).trim().toLowerCase();
        const cUid = String(currentUid || '').trim().toLowerCase();
        const cPhone = String(activeUser?.phoneNumber || '').trim().toLowerCase();
        const cEmail = String(activeUser?.email || '').trim().toLowerCase();
        const cId = String(activeUser?.id || '').trim().toLowerCase();
        return Boolean(
          (cUid && clean === cUid) ||
          (cPhone && clean === cPhone) ||
          (cEmail && clean === cEmail) ||
          (cId && clean === cId)
        );
      };

      // Accurately resolve recipient ID (never notify oneself)
      let effectiveRecipientId = partnerId;
      if (!effectiveRecipientId || isMeIdentifier(effectiveRecipientId) || effectiveRecipientId === 'seller' || effectiveRecipientId === 'buyer') {
        effectiveRecipientId = isCurrentUserBuyer ? resolvedSellerId : resolvedBuyerId;
      }
      if (!effectiveRecipientId || isMeIdentifier(effectiveRecipientId) || effectiveRecipientId === 'seller' || effectiveRecipientId === 'buyer') {
        const other = participantsList.find((p) => p && !isMeIdentifier(p) && p !== 'seller' && p !== 'buyer');
        if (other) effectiveRecipientId = other;
      }

      const chatDocRef = db.collection('chats').doc(chatId);
      const currentUnreadMap = mergedChat?.unreadCount || {};
      const newUnreadMap = { ...currentUnreadMap };
      newUnreadMap[currentUid] = 0;
      if (effectiveRecipientId && !isMeIdentifier(effectiveRecipientId)) {
        newUnreadMap[effectiveRecipientId] = (Number(newUnreadMap[effectiveRecipientId]) || 0) + 1;
      }
      
      const resolvedBuyerPhoto = isCurrentUserBuyer
        ? (currentUserPhoto || mergedChat?.buyerPhoto || '')
        : (effectivePartnerPhoto || mergedChat?.buyerPhoto || '');
      const resolvedSellerPhoto = !isCurrentUserBuyer
        ? (currentUserPhoto || mergedChat?.sellerPhoto || '')
        : (effectivePartnerPhoto || mergedChat?.sellerPhoto || '');

      await chatDocRef.set(
        {
          id: chatId,
          partId: part?.id || mergedChat?.partId || '',
          partTitle: part?.title || part?.partTitle || mergedChat?.partTitle || 'Spare Part',
          partImageUrl: part?.imageUrl || part?.partImageUrl || mergedChat?.partImageUrl || '',
          partPrice: Number(part?.price || part?.partPrice || mergedChat?.partPrice) || 0,
          buyerId: resolvedBuyerId,
          buyerName: resolvedBuyerName,
          buyerPhoto: resolvedBuyerPhoto,
          sellerId: resolvedSellerId,
          sellerName: resolvedSellerName,
          sellerPhoto: resolvedSellerPhoto,
          lastMessageText: imageUrl ? '📷 Photo Attachment' : (extraData?.type === 'audio' ? `🎤 Voice Note (${extraData?.duration || '0:02'})` : cleanText),
          lastMessageAt: now,
          lastSenderId: currentUid,
          participants: participantsList,
          unread: true,
          unreadCount: newUnreadMap,
          hiddenFor: (mergedChat?.hiddenFor || []).filter((u: string) => u !== currentUid && u !== effectiveRecipientId),
        },
        { merge: true }
      );

      // Real-time Chat Notification & Push dispatch (only if recipient is valid and not oneself)
      removeLocalHiddenChatId(chatId);
      if (effectiveRecipientId && !isMeIdentifier(effectiveRecipientId) && effectiveRecipientId !== 'seller' && effectiveRecipientId !== 'buyer') {
        sendChatMessageNotification({
          chatId,
          recipientId: effectiveRecipientId,
          senderId: currentUid,
          senderName: currentName,
          senderPhoto: currentUserPhoto,
          text: cleanText || (imageUrl ? '📷 Photo Attachment' : (extraData?.type === 'audio' ? `🎤 Voice Note (${extraData?.duration || '0:02'})` : 'New message')),
          partId: part?.id || mergedChat?.partId || '',
          partTitle: part?.title || part?.partTitle || mergedChat?.partTitle || 'Spare Part',
          partPrice: Number(part?.price || part?.partPrice || mergedChat?.partPrice) || 0,
          partImageUrl: part?.imageUrl || part?.partImageUrl || mergedChat?.partImageUrl || '',
          buyerId: resolvedBuyerId,
          buyerName: resolvedBuyerName,
          sellerId: resolvedSellerId,
          sellerName: resolvedSellerName,
        }).catch((e) => console.warn('[ChatRoomScreen] sendChatMessageNotification warning:', e));
      }

    } catch (err: any) {
      console.warn('[ChatRoomScreen] Failed to send message:', err);
      Alert.alert('Message Not Sent', 'Could not send your message. Please check your internet connection.');
    } finally {
      setIsSending(false);
      setTimeout(() => {
        flatListRef.current?.scrollToEnd({ animated: true });
      }, 100);
    }
  };

  const handleSendPress = () => {
    if (inputText.trim()) {
      executeSend(inputText);
    }
  };

  // Offer Submission Handler
  const handleSubmitOffer = (offerPrice: number) => {
    const formatted = `₹${offerPrice.toLocaleString('en-IN')}`;
    executeSend(`🏷️ Made an offer of ${formatted}`, null, {
      type: 'offer',
      offerPrice,
      offerStatus: 'pending',
    });
  };

  // Accept Offer Handler
  const handleAcceptOffer = async (msgItem: ChatMessage) => {
    try {
      const db = getFirebaseFirestore();
      if (db && chatId && msgItem.id) {
        await db.collection('chats').doc(chatId).collection('messages').doc(msgItem.id).update({
          offerStatus: 'accepted',
        });
        executeSend(`🎉 Offer of ₹${Number(msgItem.offerPrice || 0).toLocaleString('en-IN')} accepted! You can arrange delivery now.`, null);
      }
    } catch (e) {
      console.warn('[ChatRoomScreen] Accept offer error:', e);
    }
  };

  // Reject Offer Handler
  const handleRejectOffer = async (msgItem: ChatMessage) => {
    try {
      const db = getFirebaseFirestore();
      if (db && chatId && msgItem.id) {
        await db.collection('chats').doc(chatId).collection('messages').doc(msgItem.id).update({
          offerStatus: 'rejected',
        });
        executeSend(`Offer of ₹${Number(msgItem.offerPrice || 0).toLocaleString('en-IN')} was declined.`, null);
      }
    } catch (e) {
      console.warn('[ChatRoomScreen] Reject offer error:', e);
    }
  };

  // Audio Voice Note Recording Handlers (WhatsApp Hold/Tap to Record, Live Waveform, Stop to Preview & Send)
  const startAudioRecording = async () => {
    if (Platform.OS === 'android') {
      try {
        const granted = await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
          {
            title: translateDynamic('Microphone Permission'),
            message: translateDynamic('Auto Parts India requires microphone access to record voice notes.'),
            buttonPositive: translateDynamic('Allow'),
            buttonNegative: translateDynamic('Cancel'),
          }
        );
        if (granted !== PermissionsAndroid.RESULTS.GRANTED && granted !== 'granted') {
          Alert.alert(
            translateDynamic('Permission Required'),
            translateDynamic('Microphone access is needed to record voice notes.')
          );
          return;
        }
      } catch (err) {
        console.warn('[ChatRoomScreen] Permission request error:', err);
      }
    }

    // Initialize MediaRecorder / Audio Stream if available
    try {
      if (typeof navigator !== 'undefined' && navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        mediaStreamRef.current = stream;
        audioChunksRef.current = [];

        if (typeof MediaRecorder !== 'undefined') {
          let options: any = {};
          if (MediaRecorder.isTypeSupported('audio/webm;codecs=opus')) {
            options = { mimeType: 'audio/webm;codecs=opus' };
          } else if (MediaRecorder.isTypeSupported('audio/mp4')) {
            options = { mimeType: 'audio/mp4' };
          } else if (MediaRecorder.isTypeSupported('audio/ogg')) {
            options = { mimeType: 'audio/ogg' };
          }

          const recorder = new MediaRecorder(stream, options);
          recorder.ondataavailable = (event: any) => {
            if (event.data && event.data.size > 0) {
              audioChunksRef.current.push(event.data);
            }
          };
          recorder.start(100);
          mediaRecorderRef.current = recorder;
        }
      }
    } catch (micErr: any) {
      console.warn('[ChatRoomScreen] getUserMedia warning (using synthesized voice fallback):', micErr);
    }

    setIsRecordingAudio(true);
    setRecordingSeconds(0);
    recordingStartTimeRef.current = Date.now();
    if (recordingTimerRef.current) clearInterval(recordingTimerRef.current);
    recordingTimerRef.current = setInterval(() => {
      setRecordingSeconds((prev) => prev + 1);
    }, 1000);
  };

  const cancelAudioRecording = () => {
    chatSounds.playTrash();
    setIsRecordingAudio(false);
    setRecordingSeconds(0);
    if (recordingTimerRef.current) clearInterval(recordingTimerRef.current);

    if (mediaRecorderRef.current) {
      try {
        if (mediaRecorderRef.current.state !== 'inactive') {
          mediaRecorderRef.current.stop();
        }
      } catch (_) {}
      mediaRecorderRef.current = null;
    }

    if (mediaStreamRef.current) {
      try {
        mediaStreamRef.current.getTracks().forEach((track: any) => track.stop());
      } catch (_) {}
      mediaStreamRef.current = null;
    }
    audioChunksRef.current = [];
  };

  const handleMicPressIn = async () => {
    chatSounds.playRecordStart();
    recordingStartTimeRef.current = Date.now();
    await startAudioRecording();
  };

  const handleMicPressOut = async () => {
    const elapsed = Date.now() - (recordingStartTimeRef.current || 0);
    // If held for less than 1 second, keep recording active (tap-to-record mode)
    if (elapsed < 1000) {
      return;
    }
    // Held for 1+ seconds, stop and preview
    await stopAndPreviewAudioNote();
  };

  const stopAndPreviewAudioNote = async () => {
    if (recordingTimerRef.current) clearInterval(recordingTimerRef.current);
    const secs = recordingSeconds || Math.max(1, Math.round((Date.now() - (recordingStartTimeRef.current || Date.now())) / 1000));
    const durationStr = `0:${secs < 10 ? '0' : ''}${secs}`;
    setIsRecordingAudio(false);
    setRecordingSeconds(0);

    // Play release stop sound
    chatSounds.playRecordStop();

    const recorder = mediaRecorderRef.current;
    const stream = mediaStreamRef.current;
    let base64Audio: string | null = null;

    if (recorder && recorder.state !== 'inactive') {
      try {
        await new Promise<void>((resolve) => {
          recorder.onstop = () => resolve();
          recorder.stop();
        });
      } catch (err) {
        console.warn('[ChatRoomScreen] Recorder stop error:', err);
      }
    }

    if (stream) {
      try {
        stream.getTracks().forEach((track: any) => track.stop());
      } catch (_) {}
      mediaStreamRef.current = null;
    }

    if (audioChunksRef.current && audioChunksRef.current.length > 0) {
      try {
        const mime = recorder?.mimeType || 'audio/webm';
        const audioBlob = new Blob(audioChunksRef.current, { type: mime });
        base64Audio = await new Promise<string>((resolve) => {
          const reader = new FileReader();
          reader.onloadend = () => {
            resolve(reader.result as string);
          };
          reader.readAsDataURL(audioBlob);
        });
      } catch (blobErr) {
        console.warn('[ChatRoomScreen] Blob to base64 error:', blobErr);
      }
    }

    if (!base64Audio) {
      base64Audio = chatSounds.generateWavVoiceNoteDataUrl(secs);
    }

    audioChunksRef.current = [];
    mediaRecorderRef.current = null;

    // Transition to preview state
    setRecordedAudioPreview({
      audioUrl: base64Audio || '',
      durationStr,
      seconds: secs,
    });
  };

  const stopAndSendAudioNoteDirectly = async () => {
    if (recordingTimerRef.current) clearInterval(recordingTimerRef.current);
    const secs = recordingSeconds || Math.max(1, Math.round((Date.now() - (recordingStartTimeRef.current || Date.now())) / 1000));
    const durationStr = `0:${secs < 10 ? '0' : ''}${secs}`;
    setIsRecordingAudio(false);
    setRecordingSeconds(0);
    chatSounds.playSend();

    const recorder = mediaRecorderRef.current;
    const stream = mediaStreamRef.current;
    let base64Audio: string | null = null;

    if (recorder && recorder.state !== 'inactive') {
      try {
        await new Promise<void>((resolve) => {
          recorder.onstop = () => resolve();
          recorder.stop();
        });
      } catch (err) {
        console.warn('[ChatRoomScreen] Recorder stop error:', err);
      }
    }

    if (stream) {
      try {
        stream.getTracks().forEach((track: any) => track.stop());
      } catch (_) {}
      mediaStreamRef.current = null;
    }

    if (audioChunksRef.current && audioChunksRef.current.length > 0) {
      try {
        const mime = recorder?.mimeType || 'audio/webm';
        const audioBlob = new Blob(audioChunksRef.current, { type: mime });
        base64Audio = await new Promise<string>((resolve) => {
          const reader = new FileReader();
          reader.onloadend = () => {
            resolve(reader.result as string);
          };
          reader.readAsDataURL(audioBlob);
        });
      } catch (blobErr) {
        console.warn('[ChatRoomScreen] Blob to base64 error:', blobErr);
      }
    }

    if (!base64Audio) {
      base64Audio = chatSounds.generateWavVoiceNoteDataUrl(secs);
    }

    audioChunksRef.current = [];
    mediaRecorderRef.current = null;
    setRecordedAudioPreview(null);

    executeSend(`🎤 Voice Note (${durationStr})`, null, {
      type: 'audio',
      audioDuration: durationStr,
      audioUrl: base64Audio || null,
    });
  };

  const discardAudioPreview = () => {
    // Play Trash Swoosh
    chatSounds.playTrash();
    if (previewAudioRef.current) {
      try {
        previewAudioRef.current.pause();
      } catch (_) {}
      previewAudioRef.current = null;
    }
    if (previewTimerRef.current) clearInterval(previewTimerRef.current);
    setIsPreviewPlaying(false);
    setPreviewPlaybackTime(null);
    setRecordedAudioPreview(null);
  };

  const togglePreviewPlayback = () => {
    if (!recordedAudioPreview) return;

    if (isPreviewPlaying) {
      if (previewAudioRef.current) {
        try {
          previewAudioRef.current.pause();
        } catch (_) {}
      }
      if (previewTimerRef.current) clearInterval(previewTimerRef.current);
      setIsPreviewPlaying(false);
    } else {
      if (recordedAudioPreview.audioUrl && typeof window !== 'undefined' && (window as any).Audio) {
        try {
          if (!previewAudioRef.current || previewAudioRef.current.src !== recordedAudioPreview.audioUrl) {
            const audio = new (window as any).Audio(recordedAudioPreview.audioUrl);
            previewAudioRef.current = audio;

            audio.onended = () => {
              setIsPreviewPlaying(false);
              setPreviewPlaybackTime(null);
              if (previewTimerRef.current) clearInterval(previewTimerRef.current);
            };

            audio.ontimeupdate = () => {
              if (audio.currentTime) {
                const curM = Math.floor(audio.currentTime / 60);
                const curS = Math.floor(audio.currentTime % 60);
                setPreviewPlaybackTime(`${curM}:${curS < 10 ? '0' : ''}${curS}`);
              }
            };

            audio.onerror = () => {
              simulatePreviewPlayback();
            };
          }

          previewAudioRef.current.play().then(() => {
            setIsPreviewPlaying(true);
          }).catch((err: any) => {
            console.warn('[ChatRoomScreen] Preview audio play error:', err);
            simulatePreviewPlayback();
          });
          return;
        } catch (e) {
          console.warn('[ChatRoomScreen] Preview audio creation error:', e);
        }
      }
      simulatePreviewPlayback();
    }
  };

  const simulatePreviewPlayback = () => {
    setIsPreviewPlaying(true);
    let sec = 0;
    if (previewTimerRef.current) clearInterval(previewTimerRef.current);
    previewTimerRef.current = setInterval(() => {
      sec += 1;
      setPreviewPlaybackTime(`0:${sec < 10 ? '0' : ''}${sec}`);
      if (sec >= (recordedAudioPreview?.seconds || 3)) {
        setIsPreviewPlaying(false);
        setPreviewPlaybackTime(null);
        if (previewTimerRef.current) clearInterval(previewTimerRef.current);
      }
    }, 1000);
  };

  const sendRecordedAudioNote = () => {
    if (!recordedAudioPreview) return;
    // 4. Play send confirmation sound
    chatSounds.playSend();

    if (previewAudioRef.current) {
      try {
        previewAudioRef.current.pause();
      } catch (_) {}
      previewAudioRef.current = null;
    }
    if (previewTimerRef.current) clearInterval(previewTimerRef.current);
    setIsPreviewPlaying(false);

    const { audioUrl, durationStr } = recordedAudioPreview;
    setRecordedAudioPreview(null);

    executeSend(`🎤 Voice Note (${durationStr})`, null, {
      type: 'audio',
      audioDuration: durationStr,
      audioUrl: audioUrl || null,
    });
  };

  // 4. Instant WhatsApp-Style Image Attachment with Real-time Optimistic Preview
  const handlePickImage = async () => {
    try {
      const selectedUri = await promptImageSourceDialog(
        translateDynamic('Attach Photo'),
        translateDynamic('Select camera or gallery to share spare part images')
      );

      if (selectedUri) {
        // Show instant preview bubble right away (WhatsApp Experience)
        setUploadingImageUri(selectedUri);
        setTimeout(() => {
          flatListRef.current?.scrollToEnd({ animated: true });
        }, 100);

        try {
          const cloudinaryUrl = await uploadImageToCloudinary(selectedUri, 'chat_attachments');
          // Send either the secure cloudinary URL or the base64/URI directly
          await executeSend('', cloudinaryUrl || selectedUri);
        } catch (err) {
          console.warn('[ChatRoomScreen] Image upload error:', err);
          // Still attempt to send with local/direct URI rather than completely failing
          try {
            await executeSend('', selectedUri);
          } catch (_) {
            Alert.alert('Upload Failed', 'Could not send photo. Please try again.');
          }
        } finally {
          setUploadingImageUri(null);
        }
      }
    } catch (err) {
      console.warn('[ChatRoomScreen] Image picker dialog error:', err);
      setUploadingImageUri(null);
    }
  };

  const retrySendMessage = (failedMsg: ChatMessage) => {
    setMessages((prev) => prev.filter((m) => m.id !== failedMsg.id));
    executeSend(failedMsg.text || '', failedMsg.imageUrl);
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

  const formatMessageTime = (ts: any) => {
    const millis = parseTimestamp(ts);
    try {
      return new Date(millis).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    } catch {
      return 'Just now';
    }
  };

  const getRelativePresenceTime = (lastSeen: number) => {
    if (!lastSeen) return translateDynamic('Offline');
    const diff = Math.floor((Date.now() - lastSeen) / 1000);
    if (diff < 60) return translateDynamic('Active just now');
    if (diff < 3600) return `Active ${Math.floor(diff / 60)}m ago`;
    if (diff < 86400) return `Active ${Math.floor(diff / 3600)}h ago`;
    return `Last seen ${Math.floor(diff / 86400)}d ago`;
  };

  const formatPrice = (price: number) => {
    if (!price) return '₹0';
    return `₹${Number(price).toLocaleString('en-IN')}`;
  };

  // Quick reply presets based on language
  const getQuickReplies = () => {
    switch (language) {
      case 'ta':
        return [
          'இது இன்னும் கிடைக்குமா?',
          'விலை குறைக்க முடியுமா?',
          'பொருள் எங்கே இருக்கிறது?',
          'கொரியர் மூலம் அனுப்ப முடியுமா?',
          'உத்தரவாதம் இருக்கிறதா?',
        ];
      case 'hi':
        return [
          'क्या यह अभी उपलब्ध है?',
          'क्या कीमत में छूट हो सकती है?',
          'पार्ट की वर्तमान स्थिति कैसी है?',
          'क्या आप कूरियर से भेज सकते हैं?',
          'क्या इस पर कोई वारंटी है?',
        ];
      default:
        return [
          'Is this still available?',
          'Is the price negotiable?',
          'What is the exact condition?',
          'Can you ship via courier?',
          'Any warranty or testing guarantee?',
        ];
      }
  };

  const handleCallPartner = () => {
    const phone = part?.contactPhone || mergedChat?.partnerPhone || mergedChat?.sellerPhone || mergedChat?.contactPhone;
    if (phone) {
      Alert.alert(
        'Call ' + (partnerName || 'Partner'),
        `Do you want to call ${partnerName || 'the partner'} at ${phone}?`,
        [
          { text: 'Cancel', style: 'cancel' },
          {
            text: 'Call Now',
            onPress: () => Linking.openURL(`tel:${phone}`),
          },
        ]
      );
    } else {
      Alert.alert(
        'Contact ' + (partnerName || 'Seller'),
        `Phone number is kept private by ${partnerName || 'this user'}. You can ask for their contact number in this chat or visit their profile.`,
        [
          { text: 'Cancel', style: 'cancel' },
          {
            text: 'Ask for Phone',
            onPress: () => executeSend('Could you please share your contact phone number?'),
          },
        ]
      );
    }
  };

  const isSameDay = (ts1: any, ts2: any) => {
    const d1 = new Date(parseTimestamp(ts1));
    const d2 = new Date(parseTimestamp(ts2));
    return (
      d1.getFullYear() === d2.getFullYear() &&
      d1.getMonth() === d2.getMonth() &&
      d1.getDate() === d2.getDate()
    );
  };

  const getDisplayDateLabel = (ts: any) => {
    const d = new Date(parseTimestamp(ts));
    const now = new Date();
    if (
      d.getFullYear() === now.getFullYear() &&
      d.getMonth() === now.getMonth() &&
      d.getDate() === now.getDate()
    ) {
      return translateDynamic('Today');
    }
    const yesterday = new Date(now);
    yesterday.setDate(now.getDate() - 1);
    if (
      d.getFullYear() === yesterday.getFullYear() &&
      d.getMonth() === yesterday.getMonth() &&
      d.getDate() === yesterday.getDate()
    ) {
      return translateDynamic('Yesterday');
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return `${d.getDate()} ${months[d.getMonth()]}`;
  };

  // Local deleted messages state for current chat
  const [localDeletedMsgIds, setLocalDeletedMsgIds] = useState<Set<string>>(new Set());

  useEffect(() => {
    if (!chatId) return;
    let isMounted = true;
    (async () => {
      try {
        const raw = await AsyncStorage.getItem(`@autoparts_deleted_messages_${chatId}`);
        if (raw && isMounted) {
          const arr = JSON.parse(raw);
          if (Array.isArray(arr)) {
            setLocalDeletedMsgIds(new Set<string>(arr));
          }
        }
      } catch (_) {}
    })();
    return () => { isMounted = false; };
  }, [chatId]);

  const clearedAtTimestamp = mergedChat?.clearedAt?.[currentUid] || remoteChatDoc?.clearedAt?.[currentUid] || 0;
  const visibleMessages = messages.filter((msg) => {
    if (!msg || !msg.id) return false;
    if (localDeletedMsgIds.has(msg.id)) return false;
    if (Array.isArray(msg.deletedFor) && msg.deletedFor.some((id: any) => {
      const clean = String(id || '').trim().toLowerCase();
      return clean === String(currentUid || '').trim().toLowerCase() ||
             (activeUser?.uid && clean === String(activeUser.uid).trim().toLowerCase()) ||
             (activeUser?.id && clean === String(activeUser.id).trim().toLowerCase());
    })) {
      return false;
    }
    const msgTime = parseTimestamp(msg.createdAt || msg.createdAt);
    if (clearedAtTimestamp > 0 && msgTime <= clearedAtTimestamp) {
      return false;
    }
    return true;
  });

  const handleMessageAction = (msgItem: ChatMessage) => {
    if (msgItem.isDeleted) return;

    const isMe = msgItem.senderId === currentUid;
    const msgTime = parseTimestamp(msgItem.createdAt);
    const isWithin15Min = Date.now() - msgTime <= 15 * 60 * 1000;

    const buttons: any[] = [];

    // Copy text if present
    if (msgItem.text) {
      buttons.push({
        text: translateDynamic('Copy Text'),
        onPress: () => {
          Alert.alert(translateDynamic('Copied'), translateDynamic('Message text copied to clipboard'));
        },
      });
    }

    // Delete for Me (always available)
    buttons.push({
      text: translateDynamic('Delete for Me'),
      onPress: async () => {
        try {
          if (msgItem.id && chatId) {
            setLocalDeletedMsgIds((prev) => {
              const next = new Set(prev);
              next.add(msgItem.id);
              AsyncStorage.setItem(`@autoparts_deleted_messages_${chatId}`, JSON.stringify(Array.from(next))).catch(() => {});
              return next;
            });
          }
          const db = getFirebaseFirestore();
          if (db && typeof db.collection === 'function' && chatId && msgItem.id) {
            const msgRef = db.collection('chats').doc(chatId).collection('messages').doc(msgItem.id);
            const docSnap = await msgRef.get();
            const currentDeletedFor = docSnap?.exists ? (docSnap.data()?.deletedFor || []) : [];
            const nextDeletedFor = Array.from(new Set([...currentDeletedFor, currentUid, activeUser?.uid, activeUser?.id].filter(Boolean)));
            await msgRef.set({ deletedFor: nextDeletedFor }, { merge: true });
          }
          setMessages((prev) => prev.filter((m) => m.id !== msgItem.id));
        } catch (err) {
          console.warn('[ChatRoomScreen] Delete for me error:', err);
        }
      },
    });

    // Delete for Everyone (if sent by current user and within 15 minutes)
    if (isMe) {
      if (isWithin15Min) {
        buttons.push({
          text: translateDynamic('Delete for Everyone'),
          style: 'destructive',
          onPress: async () => {
            try {
              const db = getFirebaseFirestore();
              if (db && typeof db.collection === 'function' && chatId && msgItem.id) {
                
                // If it's an image message, delete from Cloudinary backend first
                if (msgItem.imageUrl) {
                  try {
                    await deleteImageFromCloudinary(msgItem.imageUrl);
                    console.log('[ChatRoomScreen] Image deleted from backend');
                  } catch (imgError) {
                    console.warn('[ChatRoomScreen] Failed to delete image from backend', imgError);
                  }
                }

                await db
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .doc(msgItem.id)
                  .set({
                    isDeleted: true,
                    text: 'This message was deleted',
                    imageUrl: null,
                  }, { merge: true });

                await db.collection('chats').doc(chatId).set({
                  lastMessageText: 'This message was deleted',
                }, { merge: true });
              }
              setMessages((prev) =>
                prev.map((m) =>
                  m.id === msgItem.id
                    ? { ...m, isDeleted: true, text: 'This message was deleted', imageUrl: null }
                    : m
                )
              );
            } catch (err: any) {
              console.warn('[ChatRoomScreen] Delete for everyone error:', err);
            }
          },
        });
      } else {
        buttons.push({
          text: translateDynamic('Delete for Everyone (15m Limit Expired)'),
          onPress: () => {
            Alert.alert(
              translateDynamic('15-Minute Limit Expired'),
              translateDynamic('Delete for everyone is only available within 15 minutes of sending.')
            );
          },
        });
      }
    }

    buttons.push({ text: translateDynamic('Cancel'), style: 'cancel' });

    Alert.alert(translateDynamic('Message Options'), undefined, buttons);
  };

  const renderMessage = ({ item, index }: { item: ChatMessage; index: number }) => {
    const isMe = item.senderId === currentUid;
    const isFailed = item.status === 'failed';
    const isPending = item.status === 'pending';

    const prevMessage = index > 0 ? visibleMessages[index - 1] : null;
    const showDatePill = !prevMessage || !isSameDay(prevMessage.createdAt, item.createdAt);

    return (
      <View key={item.id}>
        {showDatePill && (
          <View style={styles.dateSeparatorWrap}>
            <View style={styles.dateSeparatorPill}>
              <Text style={styles.dateSeparatorText}>
                {getDisplayDateLabel(item.createdAt)}
              </Text>
            </View>
          </View>
        )}

        <View
          style={[
            styles.messageRow,
            isMe ? styles.myMessageRow : styles.theirMessageRow,
          ]}
        >
          {!isMe && (
            <TouchableOpacity
              activeOpacity={0.8}
              onPress={() => {
                if (partnerId && partnerId !== 'seller' && partnerId !== 'buyer') {
                  navigation.navigate('SellerProfile', { sellerId: partnerId, sellerName: partnerName });
                }
              }}
              style={styles.messageSenderAvatarWrap}
            >
              {effectivePartnerPhoto ? (
                <Image source={{ uri: effectivePartnerPhoto }} style={styles.messageSenderAvatar} />
              ) : (
                <View style={styles.messageSenderAvatarPlaceholder}>
                  <Text style={styles.messageSenderAvatarInitial}>
                    {(partnerName || 'U').charAt(0).toUpperCase()}
                  </Text>
                </View>
              )}
            </TouchableOpacity>
          )}
          <View style={[styles.bubbleWrapper, isMe ? styles.myBubbleWrapper : styles.theirBubbleWrapper]}>
            <TouchableOpacity
              activeOpacity={0.88}
              onLongPress={() => handleMessageAction(item)}
              style={[
                styles.bubbleBox,
                item.isDeleted
                  ? styles.deletedBubble
                  : isMe
                    ? isFailed
                      ? styles.failedBubble
                      : item.imageUrl && !item.text
                        ? styles.imageOnlyBubble
                        : styles.myBubble
                    : styles.theirBubble,
                item.imageUrl && !item.text && { padding: 0, overflow: 'hidden' },
              ]}
            >
              {item.isDeleted ? (
                <View style={styles.deletedMessageRow}>
                  <Icon source="cancel" size={14} color="#64748B" />
                  <Text style={styles.deletedMessageText}>
                    {translateDynamic('This message was deleted')}
                  </Text>
                </View>
              ) : item.type === 'offer' ? (
                <View style={[styles.offerCardInsideBubble, isMe ? styles.myOfferCard : styles.theirOfferCard]}>
                  <View style={styles.offerHeaderRow}>
                    <View style={[styles.offerIconPill, isMe ? styles.myOfferIconPill : styles.theirOfferIconPill]}>
                      <Icon source="tag-outline" size={14} color={isMe ? '#FFFFFF' : '#0066FF'} />
                    </View>
                    <Text style={[styles.offerHeaderTitle, { color: isMe ? 'rgba(255,255,255,0.9)' : '#475569' }]}>
                      PRICE OFFER
                    </Text>
                  </View>

                  <Text style={[styles.offerPriceMain, { color: isMe ? '#FFFFFF' : '#0066FF' }]}>
                    ₹{Number(item.offerPrice || 0).toLocaleString('en-IN')}
                  </Text>

                  {item.offerStatus === 'accepted' ? (
                    <View style={styles.offerStatusBadgeSuccess}>
                      <Icon source="check-circle" size={14} color="#FFFFFF" />
                      <Text style={styles.offerStatusBadgeSuccessText}>OFFER ACCEPTED</Text>
                    </View>
                  ) : item.offerStatus === 'rejected' ? (
                    <View style={styles.offerStatusBadgeDanger}>
                      <Icon source="close-circle" size={14} color="#FFFFFF" />
                      <Text style={styles.offerStatusBadgeDangerText}>OFFER DECLINED</Text>
                    </View>
                  ) : !isMe ? (
                    <View style={styles.offerActionsRow}>
                      <TouchableOpacity
                        style={styles.offerAcceptBtn}
                        onPress={() => handleAcceptOffer(item)}
                        activeOpacity={0.8}
                      >
                        <Icon source="check" size={14} color="#FFFFFF" />
                        <Text style={styles.offerAcceptBtnText}>{translateDynamic('Accept')}</Text>
                      </TouchableOpacity>
                      <TouchableOpacity
                        style={styles.offerDeclineBtn}
                        onPress={() => handleRejectOffer(item)}
                        activeOpacity={0.8}
                      >
                        <Icon source="close" size={14} color="#DC2626" />
                        <Text style={styles.offerDeclineBtnText}>{translateDynamic('Decline')}</Text>
                      </TouchableOpacity>
                    </View>
                  ) : (
                    <View style={styles.offerAwaitingRow}>
                      <ActivityIndicator size={11} color={isMe ? 'rgba(255,255,255,0.8)' : '#64748B'} />
                      <Text style={[styles.offerPendingSubText, { color: isMe ? 'rgba(255,255,255,0.8)' : '#64748B' }]}>
                        {translateDynamic('Awaiting seller response...')}
                      </Text>
                    </View>
                  )}
                </View>
              ) : item.type === 'audio' ? (
                <AudioVoiceNotePlayer
                  durationText={item.audioDuration || '0:05'}
                  isMe={isMe}
                  audioUrl={item.audioUrl}
                />
              ) : (
                <>
                  {/* Image attachment */}
                  {item.imageUrl ? (
                    <TouchableOpacity
                      activeOpacity={0.9}
                      onPress={() => setSelectedPreviewImage(item.imageUrl || null)}
                      onLongPress={() => handleMessageAction(item)}
                      style={styles.imageAttachmentContainer}
                    >
                      <Image
                        source={{ uri: item.imageUrl }}
                        style={styles.messageImage}
                        resizeMode="cover"
                      />
                      <View style={styles.zoomOverlayIcon}>
                        <Icon source="magnify-plus-outline" size={18} color="#FFFFFF" />
                      </View>
                    </TouchableOpacity>
                  ) : null}

                  {/* Message text content */}
                  {item.text ? (
                    <Text
                      style={[
                        styles.messageText,
                        isMe ? styles.myMessageText : styles.theirMessageText,
                      ]}
                    >
                      {item.text}
                    </Text>
                  ) : null}
                </>
              )}

              {/* Timestamp & Status ticks */}
              <View style={[styles.metaRow, isMe && !item.isDeleted ? styles.myMetaRow : styles.theirMetaRow]}>
                <Text style={[styles.timeText, isMe && !item.isDeleted ? styles.myTimeText : styles.theirTimeText]}>
                  {formatMessageTime(item.createdAt)}
                </Text>

                {isMe && !item.isDeleted && (
                  <View style={styles.statusTickContainer}>
                    {isPending ? (
                      <ActivityIndicator size={10} color="#BAE6FD" />
                    ) : isFailed ? (
                      <TouchableOpacity
                        onPress={() => retrySendMessage(item)}
                        style={styles.retryBtn}
                      >
                        <Icon source="alert-circle" size={12} color="#EF4444" />
                        <Text style={styles.retryText}>{translateDynamic('Retry')}</Text>
                      </TouchableOpacity>
                    ) : item.status === 'read' ? (
                      <Icon source="check-all" size={14} color="#FFFFFF" />
                    ) : item.status === 'delivered' ? (
                      <Icon source="check-all" size={14} color="rgba(255,255,255,0.7)" />
                    ) : (
                      <Icon source="check" size={14} color="rgba(255,255,255,0.7)" />
                    )}
                  </View>
                )}
              </View>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    );
  };

  return (
    <View style={styles.outerContainer}>
      <StatusBar barStyle="dark-content" backgroundColor="#FFFFFF" />

      {/* 1. CLEAN MODERN WHITE HEADER */}
      <View style={[styles.headerBar, { paddingTop: Math.max(insets.top, 8) }]}>
        {/* Back Button */}
        <TouchableOpacity
          style={styles.backBtn}
          onPress={handleBackNavigation}
          activeOpacity={0.7}
        >
          <Icon source="arrow-left" size={22} color="#0F172A" />
        </TouchableOpacity>

        {/* Partner Info and Presence Status */}
        <TouchableOpacity
          style={styles.partnerHeaderInfo}
          activeOpacity={0.8}
          onPress={() => {
            if (partnerId && partnerId !== 'seller' && partnerId !== 'buyer') {
              navigation.navigate('SellerProfile', { sellerId: partnerId, sellerName: partnerName });
            }
          }}
        >
          <View style={styles.partnerHeaderAvatarWrapper}>
            {effectivePartnerPhoto ? (
              <Image source={{ uri: effectivePartnerPhoto }} style={styles.partnerHeaderAvatar} />
            ) : (
              <View style={styles.partnerHeaderAvatarPlaceholder}>
                <Text style={styles.partnerHeaderAvatarInitial}>
                  {(partnerName || 'U').charAt(0).toUpperCase()}
                </Text>
              </View>
            )}
            {/* Online Indicator Badge on Avatar */}
            {partnerPresence.online && (
              <View style={styles.avatarOnlineBadge} />
            )}
          </View>

          <View style={styles.partnerTextCol}>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
              <Text numberOfLines={1} style={styles.partnerHeaderName}>
                {partnerName}
              </Text>
              {isCurrentUserBuyer && (
                <Icon source="check-decagram" size={14} color="#0066FF" />
              )}
            </View>

            <View style={styles.statusIndicatorRow}>
              {partnerIsTyping ? (
                <Text style={styles.typingStatusText}>
                  {translateDynamic('typing...')}
                </Text>
              ) : partnerPresence.online ? (
                <Text style={styles.onlineStatusText}>
                  {translateDynamic('Active now')}
                </Text>
              ) : (
                <Text style={styles.offlineStatusText}>
                  {getRelativePresenceTime(partnerPresence.lastSeen)}
                </Text>
              )}
            </View>
          </View>
        </TouchableOpacity>

        {/* Header Right Action Buttons: Phone & 3-Dots */}
        <View style={styles.headerRightActions}>
          <TouchableOpacity
            style={styles.headerRightBtn}
            activeOpacity={0.7}
            onPress={handleCallPartner}
          >
            <Icon source="phone-outline" size={20} color="#334155" />
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.headerRightBtn}
            activeOpacity={0.7}
            onPress={() => setShowOptionsMenu(true)}
          >
            <Icon source="dots-vertical" size={20} color="#334155" />
          </TouchableOpacity>
        </View>
      </View>

      {/* 2. PRODUCT INQUIRY CARD BANNER */}
      {part ? (
        <View style={styles.productBannerCard}>
          <TouchableOpacity
            style={styles.productBannerTouch}
            activeOpacity={0.88}
            onPress={() => navigation.navigate('ProductDetail', { part })}
          >
            <Image
              source={{
                uri:
                  part.imageUrl ||
                  part.partImageUrl ||
                  'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&q=80&w=200',
              }}
              style={styles.productBannerImage}
            />
            <View style={styles.productBannerInfo}>
              <View style={styles.productBannerBadgeRow}>
                <Text style={styles.productBannerCategoryBadge}>SPARE PART</Text>
              </View>
              <Text numberOfLines={1} style={styles.productBannerTitle}>
                {part.title || part.partTitle || 'Auto Spare Part'}
              </Text>
              <Text style={styles.productBannerPrice}>
                {formatPrice(Number(part.price || part.partPrice) || 0)}
              </Text>
            </View>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.makeOfferHeaderBtn}
            onPress={() => setShowMakeOfferModal(true)}
            activeOpacity={0.8}
          >
            <Icon source="tag-outline" size={15} color="#0066FF" />
            <Text style={styles.makeOfferHeaderBtnText}>Make Offer</Text>
          </TouchableOpacity>
        </View>
      ) : null}

      {/* 3. MESSAGE FEED + COMPOSER */}
      <KeyboardAvoidingView
        style={styles.contentFlex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        keyboardVerticalOffset={Platform.OS === 'ios' ? 10 : 0}
      >
        <FlatList
          ref={flatListRef}
          data={visibleMessages}
          keyExtractor={(item) => item.id}
          renderItem={renderMessage}
          contentContainerStyle={styles.messageListContainer}
          onScroll={handleChatScroll}
          scrollEventThrottle={16}
          onContentSizeChange={() => {
            if (isNearBottomRef.current) {
              flatListRef.current?.scrollToEnd({ animated: false });
            }
          }}
          onLayout={() => {
            flatListRef.current?.scrollToEnd({ animated: false });
          }}
          keyboardDismissMode={Platform.OS === 'ios' ? 'interactive' : 'on-drag'}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
          bounces={true}
          alwaysBounceVertical={true}
          overScrollMode="never"
          decelerationRate="normal"
          removeClippedSubviews={Platform.OS === 'android'}
          ListEmptyComponent={
            <View style={styles.emptyFeedContainer}>
              <View style={styles.emptyFeedIconCircle}>
                <Icon source="chat-processing-outline" size={32} color="#0072F5" />
              </View>
              <Text style={styles.emptyFeedTitle}>
                {translateDynamic('Chat with')} {partnerName}
              </Text>
              <Text style={styles.emptyFeedSub}>
                {translateDynamic('Ask about part condition, negotiate price, or arrange courier delivery.')}
              </Text>
            </View>
          }
          ListFooterComponent={
            <>
              {partnerIsTyping && (
                <View style={{ marginVertical: 6, marginHorizontal: 12 }}>
                  <TypingIndicator dotSize={7} dotColor="#3B82F6" />
                </View>
              )}
              {uploadingImageUri && (
                <View style={styles.uploadingImageCard}>
                  <Image source={{ uri: uploadingImageUri }} style={styles.uploadingImageThumb} resizeMode="cover" />
                  <View style={styles.uploadingImageOverlay}>
                    <View style={styles.uploadingSpinnerCircle}>
                      <ActivityIndicator size={20} color="#FFFFFF" />
                    </View>
                    <Text style={styles.uploadingImageOverlayText}>
                      {translateDynamic('Sending photo...')}
                    </Text>
                  </View>
                </View>
              )}
            </>
          }
        />

        {/* 4. QUICK REPLIES CHIP BAR */}
        <View style={styles.quickRepliesBar}>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.quickRepliesScroll}
          >
            <View style={styles.zapIconContainer}>
              <Icon source="flash" size={14} color="#F59E0B" />
            </View>
            {getQuickReplies().map((replyText, idx) => (
              <TouchableOpacity
                key={`bar-${idx}`}
                style={styles.quickReplyChip}
                onPress={() => executeSend(replyText)}
                disabled={isSending || !!uploadingImageUri}
                activeOpacity={0.7}
              >
                <Text style={styles.quickReplyChipText}>{replyText}</Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>

        {/* Quick Emoji Picker Drawer if opened */}
        {showEmojiPicker && (
          <View style={styles.emojiPickerBar}>
            {['👍', '👌', '🤝', '🚗', '🔧', '✅', '🙏', '😊', '💰', '📦'].map((emoji) => (
              <TouchableOpacity
                key={emoji}
                style={styles.emojiItem}
                onPress={() => {
                  setInputText((prev) => prev + emoji);
                  setShowEmojiPicker(false);
                }}
              >
                <Text style={styles.emojiText}>{emoji}</Text>
              </TouchableOpacity>
            ))}
          </View>
        )}

        {/* 5. NATIVE MESSAGE COMPOSER */}
        {isRecordingAudio ? (
          /* State 1: Active Audio Recording Bar (Cancel, Live Timer, Stop & Direct Send) */
          <View style={[styles.composerContainer, styles.recordingComposerBar, { paddingBottom: Math.max(insets.bottom, 8) }]}>
            {/* Delete / Cancel Recording Button */}
            <TouchableOpacity
              style={styles.cancelRecBtn}
              onPress={cancelAudioRecording}
              activeOpacity={0.7}
              accessibilityLabel={translateDynamic('Cancel recording')}
            >
              <View style={styles.trashCircleBtn}>
                <Icon source="delete-outline" size={20} color="#EF4444" />
              </View>
            </TouchableOpacity>

            {/* Live Recording Status & Timer */}
            <View style={styles.recordingStatusWrap}>
              <Animated.View style={[styles.recordingRedDot, { opacity: recordingSeconds % 2 === 0 ? 1 : 0.4 }]} />
              <Text style={styles.recordingTimerText}>
                0:{recordingSeconds < 10 ? '0' : ''}{recordingSeconds}
              </Text>
              
              {/* Live Audio Waveform Bars */}
              <View style={styles.liveRecordWaveRow}>
                {[0.4, 0.8, 0.5, 0.9, 0.7, 0.5, 0.8, 0.4].map((h, idx) => {
                  const dynamicH = Math.max(4, Math.round(h * 16 * ((recordingSeconds % 2 === 0 ? 1 : 0.6) + (idx % 2 === 0 ? 0.3 : 0.1))));
                  return (
                    <View
                      key={`live-wave-${idx}`}
                      style={[styles.liveWaveBar, { height: dynamicH }]}
                    />
                  );
                })}
              </View>
            </View>

            {/* Action Buttons: Stop to Preview & Direct Send */}
            <View style={styles.recordingActionsGroup}>
              {/* Stop & Preview Button (Red square/stop icon) */}
              <TouchableOpacity
                style={styles.stopRecordingBtn}
                onPress={stopAndPreviewAudioNote}
                activeOpacity={0.8}
                accessibilityLabel={translateDynamic('Stop and preview')}
              >
                <Icon source="stop" size={18} color="#FFFFFF" />
              </TouchableOpacity>

              {/* Direct Send Button (Blue send icon) */}
              <TouchableOpacity
                style={styles.directSendRecBtn}
                onPress={stopAndSendAudioNoteDirectly}
                activeOpacity={0.85}
                accessibilityLabel={translateDynamic('Send voice note')}
              >
                <Icon source="send" size={17} color="#FFFFFF" />
              </TouchableOpacity>
            </View>
          </View>
        ) : recordedAudioPreview ? (
          /* State 2: Audio Recorded Preview Bar (WhatsApp Style Preview before Send) */
          <View style={[styles.composerContainer, styles.previewComposerBar, { paddingBottom: Math.max(insets.bottom, 8) }]}>
            {/* Discard / Trash Button */}
            <TouchableOpacity
              style={styles.previewDiscardBtn}
              onPress={discardAudioPreview}
              activeOpacity={0.7}
              accessibilityLabel={translateDynamic('Discard voice note')}
            >
              <Icon source="trash-can-outline" size={22} color="#EF4444" />
            </TouchableOpacity>

            {/* Audio Preview Waveform & Play/Pause */}
            <View style={styles.previewAudioPlayerWrap}>
              <TouchableOpacity
                style={styles.previewPlayBtn}
                onPress={togglePreviewPlayback}
                activeOpacity={0.8}
                accessibilityLabel={translateDynamic('Play voice note')}
              >
                <Icon
                  source={isPreviewPlaying ? 'pause' : 'play'}
                  size={20}
                  color="#0066FF"
                />
              </TouchableOpacity>

              <View style={styles.previewWaveContainer}>
                {[0.4, 0.8, 0.5, 0.9, 0.6, 1.0, 0.7, 0.4, 0.9, 0.5, 0.8, 0.6].map((h, i) => (
                  <View
                    key={i}
                    style={[
                      styles.previewWaveBar,
                      {
                        height: Math.round(h * 18),
                        backgroundColor: isPreviewPlaying ? '#0066FF' : '#94A3B8',
                      },
                    ]}
                  />
                ))}
              </View>

              <Text style={styles.previewDurationText}>
                {previewPlaybackTime || recordedAudioPreview.durationStr}
              </Text>
            </View>

            {/* Send Audio Button */}
            <TouchableOpacity
              style={[styles.sendButton, styles.sendButtonActive]}
              onPress={sendRecordedAudioNote}
              activeOpacity={0.85}
              accessibilityLabel={translateDynamic('Send audio message')}
            >
              <Icon source="send" size={18} color="#FFFFFF" />
            </TouchableOpacity>
          </View>
        ) : (
          /* State 3: Normal Composer */
          <View style={[styles.composerContainer, { paddingBottom: Math.max(insets.bottom, 8) }]}>
            {/* Paperclip Attachment Button */}
            <TouchableOpacity
              style={styles.attachBtn}
              onPress={handlePickImage}
              disabled={!!uploadingImageUri || isSending}
              activeOpacity={0.7}
              accessibilityLabel={translateDynamic('Attach image')}
            >
              <Icon source="paperclip" size={24} color="#64748B" />
            </TouchableOpacity>

            {/* Capsule Text Input */}
            <View style={styles.inputBubbleWrap}>
              <TextInput
                placeholder={translateDynamic('Type a message...')}
                value={inputText}
                onChangeText={handleInputChange}
                style={styles.nativeInput}
                placeholderTextColor="#94A3B8"
                multiline
                maxLength={1000}
              />
              <TouchableOpacity
                style={styles.emojiBtn}
                onPress={() => setShowEmojiPicker(!showEmojiPicker)}
                activeOpacity={0.7}
              >
                <Icon source="emoticon-happy-outline" size={22} color="#64748B" />
              </TouchableOpacity>
            </View>

            {/* Mic or Send Button */}
            {inputText.trim().length > 0 ? (
              <TouchableOpacity
                style={[styles.sendButton, styles.sendButtonActive]}
                onPress={handleSendPress}
                disabled={isSending}
                activeOpacity={0.8}
                accessibilityLabel={translateDynamic('Send message')}
              >
                {isSending ? (
                  <ActivityIndicator size={16} color="#FFFFFF" />
                ) : (
                  <Icon source="send" size={18} color="#FFFFFF" />
                )}
              </TouchableOpacity>
            ) : (
              <Animated.View style={{ transform: [{ scale: micScaleAnim }] }}>
                <TouchableOpacity
                  style={[styles.sendButton, { backgroundColor: '#0066FF' }]}
                  onPress={() => {
                    if (!isRecordingAudio) {
                      chatSounds.playRecordStart();
                      recordingStartTimeRef.current = Date.now();
                      startAudioRecording();
                    }
                  }}
                  activeOpacity={0.8}
                  accessibilityLabel={translateDynamic('Record voice message')}
                >
                  <Icon source="microphone" size={20} color="#FFFFFF" />
                </TouchableOpacity>
              </Animated.View>
            )}
          </View>
        )}
      </KeyboardAvoidingView>

      {/* Make Offer Modal */}
      <MakeOfferModal
        visible={showMakeOfferModal}
        partTitle={part?.title || part?.partTitle || mergedChat?.partTitle}
        listedPrice={Number(part?.price || part?.partPrice || mergedChat?.partPrice) || 0}
        onClose={() => setShowMakeOfferModal(false)}
        onSubmitOffer={handleSubmitOffer}
      />

      {/* Options Menu Modal */}
      <Modal
        visible={showOptionsMenu}
        transparent={true}
        animationType="fade"
        onRequestClose={() => setShowOptionsMenu(false)}
      >
        <TouchableOpacity
          style={styles.modalOverlay}
          activeOpacity={1}
          onPress={() => setShowOptionsMenu(false)}
        >
          <View style={styles.optionsCard}>
            <View style={styles.sheetHandle} />

            <View style={styles.optionsHeader}>
              <View>
                <Text style={styles.optionsTitle}>{partnerName}</Text>
                <Text style={styles.optionsSubtitle}>{translateDynamic('Chat options & controls')}</Text>
              </View>
              <TouchableOpacity
                style={styles.closeOptionsBtn}
                onPress={() => setShowOptionsMenu(false)}
              >
                <Icon source="close" size={18} color="#64748B" />
              </TouchableOpacity>
            </View>

            <TouchableOpacity
              style={styles.optionItem}
              onPress={() => {
                setShowOptionsMenu(false);
                handleCallPartner();
              }}
            >
              <View style={[styles.optionIconBox, { backgroundColor: '#EFF6FF' }]}>
                <Icon source="phone-outline" size={20} color="#0066FF" />
              </View>
              <View style={styles.optionTextCol}>
                <Text style={styles.optionItemText}>{translateDynamic('Voice Call')}</Text>
                <Text style={styles.optionItemSub}>{translateDynamic('Call seller via mobile network')}</Text>
              </View>
            </TouchableOpacity>

            {partnerId && partnerId !== 'seller' && (
              <TouchableOpacity
                style={styles.optionItem}
                onPress={() => {
                  setShowOptionsMenu(false);
                  navigation.navigate('SellerProfile', { sellerId: partnerId, sellerName: partnerName });
                }}
              >
                <View style={[styles.optionIconBox, { backgroundColor: '#EFF6FF' }]}>
                  <Icon source="account-circle-outline" size={20} color="#0066FF" />
                </View>
                <View style={styles.optionTextCol}>
                  <Text style={styles.optionItemText}>{translateDynamic('View Profile')}</Text>
                  <Text style={styles.optionItemSub}>{translateDynamic('Check seller ratings & inventory')}</Text>
                </View>
              </TouchableOpacity>
            )}

            <TouchableOpacity
              style={styles.optionItem}
              onPress={() => {
                setShowOptionsMenu(false);
                setShowLanguageModal(true);
              }}
            >
              <View style={[styles.optionIconBox, { backgroundColor: '#EFF6FF' }]}>
                <Icon source="translate" size={20} color="#0066FF" />
              </View>
              <View style={styles.optionTextCol}>
                <Text style={styles.optionItemText}>{translateDynamic('Chat Language')}</Text>
                <Text style={styles.optionItemSub}>{translateDynamic('Translate or switch language')}</Text>
              </View>
            </TouchableOpacity>

            <View style={styles.optionsDivider} />

            <TouchableOpacity
              style={styles.optionItem}
              onPress={() => {
                setShowOptionsMenu(false);
                Alert.alert(
                  translateDynamic('Clear Chat History'),
                  translateDynamic('Are you sure you want to clear all messages in this conversation for you?'),
                  [
                    { text: translateDynamic('Cancel'), style: 'cancel' },
                    {
                      text: translateDynamic('Clear Chat'),
                      style: 'destructive',
                      onPress: async () => {
                        try {
                          const db = getFirebaseFirestore();
                          if (db && typeof db.collection === 'function' && chatId) {
                            await db.collection('chats').doc(chatId).set({
                              clearedAt: {
                                ...(remoteChatDoc?.clearedAt || {}),
                                [currentUid]: Date.now(),
                              },
                            }, { merge: true });
                          }
                          setMessages([]);
                        } catch (err) {
                          console.warn('Error clearing chat:', err);
                        }
                      },
                    },
                  ]
                );
              }}
            >
              <View style={[styles.optionIconBox, { backgroundColor: '#FFF1F2' }]}>
                <Icon source="delete-sweep-outline" size={20} color="#E11D48" />
              </View>
              <View style={styles.optionTextCol}>
                <Text style={[styles.optionItemText, { color: '#E11D48' }]}>
                  {translateDynamic('Clear Chat History')}
                </Text>
                <Text style={styles.optionItemSub}>{translateDynamic('Remove messages on this device')}</Text>
              </View>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.optionItem}
              onPress={() => {
                setShowOptionsMenu(false);
                Alert.alert(
                  translateDynamic('Delete Conversation'),
                  translateDynamic('Are you sure you want to delete this chat conversation?'),
                  [
                    { text: translateDynamic('Cancel'), style: 'cancel' },
                    {
                      text: translateDynamic('Delete'),
                      style: 'destructive',
                      onPress: async () => {
                        try {
                          if (chatId) {
                            await addLocalHiddenChatId(chatId);
                            const db = getFirebaseFirestore();
                            if (db && typeof db.collection === 'function') {
                              const chatRef = db.collection('chats').doc(chatId);
                              const snap = await chatRef.get();
                              const currentHidden = snap?.exists ? (snap.data()?.hiddenFor || []) : [];
                              const nextHidden = Array.from(new Set([...currentHidden, currentUid]));
                              await chatRef.set({
                                hiddenFor: nextHidden,
                                clearedAt: {
                                  ...(snap.data()?.clearedAt || {}),
                                  [currentUid]: Date.now(),
                                },
                              }, { merge: true });
                            }
                          }
                          navigation.navigate('MainTabs', { screen: 'ChatsTab' });
                        } catch (err) {
                          console.warn('Error deleting conversation:', err);
                        }
                      },
                    },
                  ]
                );
              }}
            >
              <View style={[styles.optionIconBox, { backgroundColor: '#FEF2F2' }]}>
                <Icon source="trash-can-outline" size={20} color="#DC2626" />
              </View>
              <View style={styles.optionTextCol}>
                <Text style={[styles.optionItemText, { color: '#DC2626' }]}>
                  {translateDynamic('Delete Conversation')}
                </Text>
                <Text style={styles.optionItemSub}>{translateDynamic('Hide and remove conversation')}</Text>
              </View>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.optionItem}
              onPress={() => {
                setShowOptionsMenu(false);
                Alert.alert(
                  'Report or Block',
                  `Do you want to report or block ${partnerName}?`,
                  [
                    { text: 'Cancel', style: 'cancel' },
                    {
                      text: 'Block User',
                      style: 'destructive',
                      onPress: () => Alert.alert('User Blocked', 'You will no longer receive messages from this user.'),
                    },
                  ]
                );
              }}
            >
              <View style={[styles.optionIconBox, { backgroundColor: '#FEF2F2' }]}>
                <Icon source="alert-octagon-outline" size={20} color="#EF4444" />
              </View>
              <View style={styles.optionTextCol}>
                <Text style={[styles.optionItemText, { color: '#EF4444' }]}>
                  {translateDynamic('Block / Report User')}
                </Text>
                <Text style={styles.optionItemSub}>{translateDynamic('Flag safety or spam issues')}</Text>
              </View>
            </TouchableOpacity>
          </View>
        </TouchableOpacity>
      </Modal>

      {/* Fullscreen Image Preview Modal */}
      <Modal
        visible={!!selectedPreviewImage}
        transparent={true}
        animationType="fade"
        onRequestClose={() => setSelectedPreviewImage(null)}
      >
        <View style={styles.imageModalContainer}>
          <StatusBar barStyle="light-content" backgroundColor="#000000" />
          <TouchableOpacity
            style={styles.closeImageModalBtn}
            onPress={() => setSelectedPreviewImage(null)}
          >
            <Icon source="close" size={24} color="#FFFFFF" />
          </TouchableOpacity>
          {selectedPreviewImage && (
            <Image
              source={{ uri: selectedPreviewImage }}
              style={styles.fullscreenImage}
              resizeMode="contain"
            />
          )}
        </View>
      </Modal>

      {/* Language Selector Modal */}
      <LanguageSelectorModal
        visible={showLanguageModal}
        onDismiss={() => setShowLanguageModal(false)}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  outerContainer: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  contentFlex: {
    flex: 1,
  },
  headerBar: {
    backgroundColor: '#FFFFFF',
    paddingBottom: 10,
    paddingHorizontal: 12,
    flexDirection: 'row',
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 3,
  },
  backBtn: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: '#F8FAFC',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 8,
  },
  partnerHeaderInfo: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
  },
  partnerHeaderAvatarWrapper: {
    position: 'relative',
    marginRight: 10,
  },
  partnerHeaderAvatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    borderWidth: 1.5,
    borderColor: '#E2E8F0',
  },
  partnerHeaderAvatarPlaceholder: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#0066FF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  partnerHeaderAvatarInitial: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '700',
  },
  avatarOnlineBadge: {
    position: 'absolute',
    bottom: 0,
    right: 0,
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: '#10B981',
    borderWidth: 2,
    borderColor: '#FFFFFF',
  },
  partnerTextCol: {
    flex: 1,
    justifyContent: 'center',
  },
  partnerHeaderName: {
    color: '#0F172A',
    fontWeight: '700',
    fontSize: 15.5,
  },
  statusIndicatorRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 2,
  },
  typingStatusText: {
    color: '#0066FF',
    fontSize: 11.5,
    fontWeight: '600',
  },
  onlineStatusText: {
    color: '#10B981',
    fontSize: 11.5,
    fontWeight: '500',
  },
  offlineStatusText: {
    color: '#64748B',
    fontSize: 11.5,
    fontWeight: '400',
  },
  headerRightActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  headerRightBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#F1F5F9',
    justifyContent: 'center',
    alignItems: 'center',
  },
  productBannerCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    marginHorizontal: 12,
    marginTop: 8,
    marginBottom: 4,
    paddingHorizontal: 10,
    paddingVertical: 8,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    elevation: 1,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 2,
  },
  productBannerTouch: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
  },
  productBannerImage: {
    width: 48,
    height: 48,
    borderRadius: 10,
    backgroundColor: '#F8FAFC',
    marginRight: 10,
  },
  productBannerInfo: {
    flex: 1,
    justifyContent: 'center',
  },
  productBannerBadgeRow: {
    marginBottom: 2,
  },
  productBannerCategoryBadge: {
    fontSize: 9.5,
    fontWeight: '700',
    color: '#64748B',
    letterSpacing: 0.4,
  },
  productBannerTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: '#0F172A',
  },
  productBannerPrice: {
    fontSize: 15,
    fontWeight: '800',
    color: '#0066FF',
    marginTop: 1,
  },
  makeOfferHeaderBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#EFF6FF',
    borderWidth: 1,
    borderColor: '#BFDBFE',
    paddingHorizontal: 11,
    paddingVertical: 7,
    borderRadius: 18,
    gap: 4,
    marginLeft: 8,
  },
  makeOfferHeaderBtnText: {
    color: '#0066FF',
    fontSize: 12,
    fontWeight: '700',
  },
  messageListContainer: {
    paddingHorizontal: 12,
    paddingVertical: 12,
    flexGrow: 1,
    backgroundColor: '#F8FAFC',
  },
  dateSeparatorWrap: {
    alignItems: 'center',
    marginVertical: 12,
  },
  dateSeparatorPill: {
    backgroundColor: '#E2E8F0',
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 12,
  },
  dateSeparatorText: {
    fontSize: 11,
    fontWeight: '600',
    color: '#64748B',
  },
  messageRow: {
    marginVertical: 3,
    flexDirection: 'row',
    maxWidth: '82%',
  },
  myMessageRow: {
    alignSelf: 'flex-end',
    flexDirection: 'row-reverse',
  },
  theirMessageRow: {
    alignSelf: 'flex-start',
    alignItems: 'flex-end',
  },
  messageSenderAvatarWrap: {
    marginRight: 6,
    marginBottom: 4,
    alignSelf: 'flex-end',
  },
  messageSenderAvatar: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: '#E2E8F0',
  },
  messageSenderAvatarPlaceholder: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: '#0066FF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  messageSenderAvatarInitial: {
    fontSize: 11,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  bubbleWrapper: {
    maxWidth: '100%',
  },
  myBubbleWrapper: {
    alignItems: 'flex-end',
  },
  theirBubbleWrapper: {
    alignItems: 'flex-start',
  },
  bubbleBox: {
    paddingVertical: 9,
    paddingHorizontal: 13,
    borderRadius: 18,
  },
  myBubble: {
    backgroundColor: '#0066FF',
    borderTopLeftRadius: 18,
    borderTopRightRadius: 18,
    borderBottomLeftRadius: 18,
    borderBottomRightRadius: 4,
    elevation: 1,
    shadowColor: '#0066FF',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.18,
    shadowRadius: 2,
  },
  imageOnlyBubble: {
    backgroundColor: 'transparent',
    padding: 0,
  },
  failedBubble: {
    backgroundColor: '#EF4444',
    borderTopLeftRadius: 18,
    borderTopRightRadius: 18,
    borderBottomLeftRadius: 18,
    borderBottomRightRadius: 4,
  },
  theirBubble: {
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 18,
    borderTopRightRadius: 18,
    borderBottomRightRadius: 18,
    borderBottomLeftRadius: 4,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    elevation: 1,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 2,
  },
  deletedBubble: {
    backgroundColor: '#F1F5F9',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  deletedMessageRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingVertical: 2,
    paddingHorizontal: 2,
  },
  deletedMessageText: {
    fontSize: 13.5,
    fontStyle: 'italic',
    color: '#64748B',
  },
  imageAttachmentContainer: {
    borderRadius: 12,
    overflow: 'hidden',
    marginBottom: 6,
    position: 'relative',
  },
  messageImage: {
    width: 230,
    maxWidth: '100%',
    height: 175,
    borderRadius: 12,
  },
  zoomOverlayIcon: {
    position: 'absolute',
    bottom: 8,
    right: 8,
    backgroundColor: 'rgba(0,0,0,0.55)',
    borderRadius: 12,
    padding: 4,
  },
  messageText: {
    fontSize: 15,
    lineHeight: 21,
  },
  myMessageText: {
    color: '#FFFFFF',
    fontWeight: '400',
  },
  theirMessageText: {
    color: '#0F172A',
    fontWeight: '400',
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 4,
    gap: 4,
  },
  myMetaRow: {
    justifyContent: 'flex-end',
  },
  theirMetaRow: {
    justifyContent: 'flex-start',
  },
  timeText: {
    fontSize: 11,
    fontWeight: '500',
  },
  myTimeText: {
    color: 'rgba(255,255,255,0.75)',
  },
  theirTimeText: {
    color: '#94A3B8',
  },
  statusTickContainer: {
    marginLeft: 2,
  },
  retryBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
  },
  retryText: {
    color: '#EF4444',
    fontSize: 11.5,
    fontWeight: '700',
  },
  offerCardInsideBubble: {
    paddingVertical: 6,
    paddingHorizontal: 4,
    minWidth: 190,
  },
  myOfferCard: {
    backgroundColor: 'rgba(255,255,255,0.12)',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.22)',
    padding: 10,
  },
  theirOfferCard: {
    backgroundColor: '#F8FAFC',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 10,
  },
  offerHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 4,
  },
  offerIconPill: {
    width: 22,
    height: 22,
    borderRadius: 11,
    justifyContent: 'center',
    alignItems: 'center',
  },
  myOfferIconPill: {
    backgroundColor: 'rgba(255,255,255,0.2)',
  },
  theirOfferIconPill: {
    backgroundColor: '#EFF6FF',
  },
  offerHeaderTitle: {
    fontSize: 11.5,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
  offerPriceMain: {
    fontSize: 22,
    fontWeight: '900',
    marginBottom: 8,
  },
  offerStatusBadgeSuccess: {
    backgroundColor: '#10B981',
    paddingVertical: 5,
    paddingHorizontal: 10,
    borderRadius: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    alignSelf: 'flex-start',
  },
  offerStatusBadgeSuccessText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '800',
  },
  offerStatusBadgeDanger: {
    backgroundColor: '#EF4444',
    paddingVertical: 5,
    paddingHorizontal: 10,
    borderRadius: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    alignSelf: 'flex-start',
  },
  offerStatusBadgeDangerText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '800',
  },
  offerActionsRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 4,
  },
  offerAcceptBtn: {
    backgroundColor: '#10B981',
    paddingVertical: 7,
    paddingHorizontal: 14,
    borderRadius: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  offerAcceptBtnText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '800',
  },
  offerDeclineBtn: {
    backgroundColor: '#FEE2E2',
    borderWidth: 1,
    borderColor: '#FECACA',
    paddingVertical: 7,
    paddingHorizontal: 12,
    borderRadius: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  offerDeclineBtnText: {
    color: '#DC2626',
    fontSize: 12,
    fontWeight: '800',
  },
  offerAwaitingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  offerPendingSubText: {
    fontSize: 11.5,
    fontStyle: 'italic',
  },
  typingIndicatorBubble: {
    alignSelf: 'flex-start',
    backgroundColor: '#FFFFFF',
    paddingVertical: 7,
    paddingHorizontal: 12,
    borderRadius: 14,
    borderTopLeftRadius: 2,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginVertical: 4,
    elevation: 1,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 1,
  },
  typingBubbleText: {
    fontSize: 11.5,
    color: '#64748B',
    fontWeight: '600',
  },
  uploadingImageCard: {
    alignSelf: 'flex-end',
    width: 140,
    height: 140,
    borderRadius: 14,
    borderTopRightRadius: 2,
    marginVertical: 4,
    overflow: 'hidden',
    backgroundColor: '#F1F5F9',
  },
  uploadingImageThumb: {
    width: '100%',
    height: '100%',
    opacity: 0.6,
  },
  uploadingImageOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0,0,0,0.3)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  uploadingSpinnerCircle: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  uploadingImageOverlayText: {
    fontSize: 11,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  emptyFeedContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 40,
    paddingHorizontal: 24,
  },
  emptyFeedIconCircle: {
    width: 68,
    height: 68,
    borderRadius: 34,
    backgroundColor: '#EFF6FF',
    borderWidth: 1,
    borderColor: '#DBEAFE',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 14,
  },
  emptyFeedTitle: {
    fontSize: 16.5,
    fontWeight: '800',
    color: '#0F172A',
    textAlign: 'center',
  },
  emptyFeedSub: {
    fontSize: 13,
    color: '#64748B',
    textAlign: 'center',
    marginTop: 6,
    lineHeight: 19,
  },
  quickRepliesBar: {
    backgroundColor: '#FFFFFF',
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
    paddingVertical: 8,
  },
  quickRepliesScroll: {
    paddingLeft: 12,
    paddingRight: 24,
    paddingVertical: 2,
    alignItems: 'center',
    gap: 8,
  },
  zapIconContainer: {
    paddingRight: 2,
  },
  quickReplyChip: {
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 20,
    paddingVertical: 6,
    paddingHorizontal: 13,
    elevation: 1,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 1,
  },
  quickReplyChipText: {
    color: '#1E293B',
    fontSize: 12.5,
    fontWeight: '600',
  },
  emojiPickerBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around',
    backgroundColor: '#F8FAFC',
    borderTopWidth: 1,
    borderTopColor: '#E2E8F0',
    paddingVertical: 8,
    paddingHorizontal: 6,
  },
  emojiItem: {
    padding: 6,
  },
  emojiText: {
    fontSize: 22,
  },
  composerContainer: {
    backgroundColor: '#FFFFFF',
    borderTopWidth: 1,
    borderTopColor: '#E2E8F0',
    paddingHorizontal: 10,
    paddingTop: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  attachBtn: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: '#F1F5F9',
    justifyContent: 'center',
    alignItems: 'center',
  },
  inputBubbleWrap: {
    flex: 1,
    backgroundColor: '#F1F5F9',
    borderRadius: 22,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    paddingHorizontal: 14,
    paddingVertical: Platform.OS === 'ios' ? 8 : 4,
    flexDirection: 'row',
    alignItems: 'center',
    maxHeight: 100,
  },
  nativeInput: {
    flex: 1,
    fontSize: 15,
    color: '#0F172A',
    padding: 0,
    margin: 0,
  },
  emojiBtn: {
    padding: 4,
    marginLeft: 4,
  },
  sendButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  sendButtonActive: {
    backgroundColor: '#0066FF',
    shadowColor: '#0066FF',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.28,
    shadowRadius: 3,
    elevation: 3,
  },
  sendButtonDisabled: {
    backgroundColor: '#CBD5E1',
  },
  cancelRecBtn: {
    padding: 4,
  },
  trashCircleBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#FEE2E2',
    justifyContent: 'center',
    alignItems: 'center',
  },
  recordingComposerBar: {
    backgroundColor: '#FFF5F5',
    borderTopColor: '#FECACA',
  },
  recordingStatusWrap: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#FCA5A5',
    gap: 8,
  },
  recordingRedDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: '#EF4444',
  },
  recordingTimerText: {
    color: '#DC2626',
    fontSize: 13.5,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
    minWidth: 34,
  },
  liveRecordWaveRow: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-evenly',
    height: 18,
    paddingHorizontal: 4,
  },
  liveWaveBar: {
    width: 3,
    backgroundColor: '#EF4444',
    borderRadius: 1.5,
  },
  recordingActionsGroup: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  stopRecordingBtn: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: '#DC2626',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#DC2626',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 3,
    elevation: 3,
  },
  directSendRecBtn: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: '#0066FF',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#0066FF',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.28,
    shadowRadius: 3,
    elevation: 3,
  },
  previewComposerBar: {
    backgroundColor: '#F8FAFC',
    borderTopColor: '#E2E8F0',
  },
  previewDiscardBtn: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: '#FEE2E2',
    justifyContent: 'center',
    alignItems: 'center',
  },
  previewAudioPlayerWrap: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 22,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    gap: 8,
  },
  previewPlayBtn: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#EFF6FF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  previewWaveContainer: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-evenly',
    height: 20,
    paddingHorizontal: 4,
  },
  previewWaveBar: {
    width: 3,
    borderRadius: 1.5,
  },
  previewDurationText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#3B82F6',
    minWidth: 32,
    textAlign: 'right',
  },
  sendRecBtn: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: '#0066FF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.45)',
    justifyContent: 'flex-end',
  },
  optionsCard: {
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    paddingHorizontal: 20,
    paddingTop: 12,
    paddingBottom: 28,
  },
  sheetHandle: {
    width: 38,
    height: 4,
    borderRadius: 2,
    backgroundColor: '#CBD5E1',
    alignSelf: 'center',
    marginBottom: 14,
  },
  optionsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingBottom: 14,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
    marginBottom: 8,
  },
  optionsTitle: {
    fontSize: 16.5,
    fontWeight: '700',
    color: '#0F172A',
  },
  optionsSubtitle: {
    fontSize: 12,
    color: '#64748B',
    marginTop: 2,
  },
  closeOptionsBtn: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#F1F5F9',
    justifyContent: 'center',
    alignItems: 'center',
  },
  optionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 11,
  },
  optionIconBox: {
    width: 38,
    height: 38,
    borderRadius: 19,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  optionTextCol: {
    flex: 1,
  },
  optionItemText: {
    fontSize: 15,
    fontWeight: '600',
    color: '#0F172A',
  },
  optionItemSub: {
    fontSize: 11.5,
    color: '#64748B',
    marginTop: 1,
  },
  optionsDivider: {
    height: 1,
    backgroundColor: '#F1F5F9',
    marginVertical: 6,
  },
  imageModalContainer: {
    flex: 1,
    backgroundColor: '#000000',
    justifyContent: 'center',
    alignItems: 'center',
  },
  closeImageModalBtn: {
    position: 'absolute',
    top: 40,
    right: 20,
    zIndex: 10,
    backgroundColor: 'rgba(255,255,255,0.2)',
    borderRadius: 20,
    padding: 8,
  },
  fullscreenImage: {
    width: '100%',
    height: '80%',
  },
});
