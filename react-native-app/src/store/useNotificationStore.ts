import { create } from 'zustand';
import { Vibration, Platform } from 'react-native';
import { getFirebaseFirestore, getCurrentUser, getFirebaseAuth } from '../services/firebase';
import { 
  getLocalHiddenChatsMap, 
  isChatLocallyHidden, 
  parseNotificationTime,
  getLocalReadAnnouncementIds,
  getLocalDeletedAnnouncementIds,
  getLocalDeletedNotifsData,
  isNotificationLocallyDeleted,
  markNotificationAsRead as serviceMarkAsRead
} from '../services/notifications';
import { chatSounds } from '../utils/chatSoundEffects';
import { navigationRef } from '../navigation/navigationRef';

export interface BannerNotification {
  id: string;
  chatId?: string;
  partId?: string;
  partTitle?: string;
  partPrice?: number;
  partImageUrl?: string;
  senderId?: string;
  senderName?: string;
  senderPhoto?: string;
  buyerId?: string;
  buyerName?: string;
  sellerId?: string;
  sellerName?: string;
  text: string;
  createdAt: number;
  timestamp?: number;
  type?: 'chat_message' | 'announcement' | 'system' | 'inquiry';
}

interface NotificationStoreState {
  unreadCount: number;
  unreadChats: number;
  unreadNotifications: number;
  activeBanner: BannerNotification | null;
  latestNotification: BannerNotification | null;
  seenBannerKeys: Set<string>;

  // Actions
  showBanner: (notif: BannerNotification) => void;
  dismissBanner: () => void;
  setUnreadCounts: (counts: { unreadChats: number; unreadNotifications: number; totalUnread: number }) => void;
  markAsRead: (notificationId: string, chatId?: string) => Promise<void>;
  initNotificationListener: (userId?: string | null) => () => void;
}

let activeListenerCleanup: (() => void) | null = null;
let sessionStartTime = Date.now();

export const useNotificationStore = create<NotificationStoreState>((set, get) => ({
  unreadCount: 0,
  unreadChats: 0,
  unreadNotifications: 0,
  activeBanner: null,
  latestNotification: null,
  seenBannerKeys: new Set<string>(),

  showBanner: (notif: BannerNotification) => {
    if (!notif || !notif.text) return;

    // Deduplication key based on ID, timestamp, and text snippet
    const key = `${notif.id || 'notif'}_${notif.createdAt || notif.timestamp || 0}_${(notif.text || '').substring(0, 30)}`;
    const seen = get().seenBannerKeys;
    if (seen.has(key)) return;

    const nextSeen = new Set(seen);
    nextSeen.add(key);

    // Audio chime & vibration
    try {
      chatSounds.playReceive();
    } catch (_) {}

    try {
      if (Platform.OS !== 'web') {
        Vibration.vibrate([0, 70, 40, 70]);
      }
    } catch (_) {}

    set({
      activeBanner: notif,
      latestNotification: notif,
      seenBannerKeys: nextSeen,
    });
  },

  dismissBanner: () => {
    set({ activeBanner: null });
  },

  setUnreadCounts: ({ unreadChats, unreadNotifications, totalUnread }) => {
    set({
      unreadChats,
      unreadNotifications,
      unreadCount: totalUnread,
    });
  },

  markAsRead: async (notificationId: string, chatId?: string) => {
    try {
      if (notificationId) {
        await serviceMarkAsRead(notificationId);
      }
      set((state) => {
        const newUnreadNotifs = Math.max(0, state.unreadNotifications - 1);
        return {
          unreadNotifications: newUnreadNotifs,
          unreadCount: Math.max(0, state.unreadChats + newUnreadNotifs),
        };
      });
    } catch (e) {
      console.warn('[useNotificationStore] markAsRead error:', e);
    }
  },

  initNotificationListener: (userIdParam?: string | null) => {
    // Cleanup any existing active listener
    if (activeListenerCleanup) {
      try {
        activeListenerCleanup();
      } catch (_) {}
      activeListenerCleanup = null;
    }

    const currentU = getCurrentUser();
    const uid = userIdParam || currentU?.uid || currentU?.id || null;

    let unsubChats = () => {};
    let unsubNotifs = () => {};
    let unsubAnnouncements = () => {};
    let isMounted = true;

    try {
      const db = getFirebaseFirestore();
      if (!db || typeof db.collection !== 'function') {
        return () => {};
      }

      let unreadChatCount = 0;
      let unreadNotifCount = 0;
      let unreadAnnounceCount = 0;

      const emitCounts = (latestItem?: BannerNotification | null) => {
        if (!isMounted) return;
        const total = unreadChatCount + unreadNotifCount + unreadAnnounceCount;
        set((state) => ({
          unreadChats: unreadChatCount,
          unreadNotifications: unreadNotifCount + unreadAnnounceCount,
          unreadCount: total,
          latestNotification: latestItem || state.latestNotification,
        }));
      };

      // 1. Listen to announcements (works for both guests and authenticated users)
      try {
        unsubAnnouncements = db
          .collection('announcements')
          .limit(25)
          .onSnapshot(
            async (snapshot: any) => {
              if (!isMounted) return;
              try {
                const readSet = await getLocalReadAnnouncementIds();
                const deletedSet = await getLocalDeletedAnnouncementIds();
                let count = 0;
                let newestAnnounce: BannerNotification | null = null;

                if (snapshot && typeof snapshot.forEach === 'function') {
                  snapshot.forEach((doc: any) => {
                    const docId = doc.id;
                    const data = doc.data ? doc.data() : doc;
                    if (docId && (deletedSet.has(docId) || readSet.has(docId))) return;
                    count += 1;

                    const aTime = parseNotificationTime(data.createdAt || data.timestamp);
                    const newestTime = newestAnnounce ? newestAnnounce.createdAt : 0;
                    if (aTime > newestTime) {
                      newestAnnounce = {
                        id: `ann_${docId}`,
                        title: data.title || 'Official Announcement',
                        text: data.message || data.content || data.body || 'New announcement posted',
                        partTitle: data.title || 'Official Notice',
                        createdAt: aTime,
                        timestamp: aTime,
                        type: 'announcement',
                      };
                    }
                  });
                }
                unreadAnnounceCount = count;
                emitCounts(newestAnnounce);
              } catch (_) {
                unreadAnnounceCount = 0;
                emitCounts();
              }
            },
            () => {
              unreadAnnounceCount = 0;
              emitCounts();
            }
          );
      } catch (_) {}

      // If user is authenticated, also listen to their private chats and personal notifications
      if (uid) {
        let buyerChats: any[] = [];
        let sellerChats: any[] = [];
        let partChats: any[] = [];

        const computeChats = async () => {
          if (!isMounted) return;
          try {
            const chatsMap = new Map<string, any>();
            const hiddenMap = await getLocalHiddenChatsMap();

            [...buyerChats, ...sellerChats, ...partChats].forEach((c) => {
              const docId = c.id || (c.data && c.data().id);
              const data = c.data ? c.data() : c;
              if (!docId || !data) return;
              const msgTime = parseNotificationTime(data.lastMessageAt || data.updatedAt || data.createdAt);
              if (isChatLocallyHidden(docId, msgTime, hiddenMap)) return;
              if (Array.isArray(data.hiddenFor) && data.hiddenFor.includes(uid)) {
                const clearedTime = parseNotificationTime(data.clearedAt?.[uid]);
                if (clearedTime && msgTime <= clearedTime) return;
              }
              chatsMap.set(docId, data);
            });

            let count = 0;
            let newestChatNotif: BannerNotification | null = null;

            chatsMap.forEach((data, docId) => {
              const isSenderMe = data && data.lastSenderId && (data.lastSenderId === uid || String(data.lastSenderId).toLowerCase() === String(uid).toLowerCase());
              if (isSenderMe) return;

              const unreadFromMap = typeof data?.unreadCount?.[uid] === 'number' 
                ? data.unreadCount[uid] 
                : 0;
              const hasUnreadFlag = data && data.lastSenderId && data.lastSenderId !== uid && data.unread === true;

              if (unreadFromMap > 0 || hasUnreadFlag) {
                count += 1;
                const msgTime = parseNotificationTime(data.lastMessageAt || data.updatedAt || data.createdAt);
                const newestTime = newestChatNotif ? newestChatNotif.createdAt : 0;

                if (msgTime > newestTime) {
                  const isUserBuyer = String(uid).trim().toLowerCase() === String(data.buyerId).trim().toLowerCase();
                  newestChatNotif = {
                    id: `chat_msg_${docId}_${msgTime}`,
                    chatId: docId,
                    senderId: data.lastSenderId,
                    senderName: isUserBuyer ? (data.sellerName || 'Verified Seller') : (data.buyerName || 'Buyer'),
                    senderPhoto: isUserBuyer ? (data.sellerPhoto || '') : (data.buyerPhoto || ''),
                    text: data.lastMessageText || 'Sent you a message',
                    createdAt: msgTime,
                    timestamp: msgTime,
                    partId: data.partId || '',
                    partTitle: data.partTitle || 'Auto Spare Part',
                    partPrice: Number(data.partPrice) || 0,
                    partImageUrl: data.partImageUrl || '',
                    buyerId: data.buyerId,
                    buyerName: data.buyerName,
                    sellerId: data.sellerId,
                    sellerName: data.sellerName,
                    type: 'chat_message',
                  };
                }
              }
            });

            unreadChatCount = count;
            emitCounts(newestChatNotif);

            // Pop in-app banner for newest incoming chat message if recent & not currently viewing this chat
            if (newestChatNotif && (newestChatNotif.createdAt >= sessionStartTime - 30000 || Date.now() - newestChatNotif.createdAt < 180000)) {
              try {
                if (navigationRef.isReady()) {
                  const currentRoute = navigationRef.getCurrentRoute();
                  if (
                    currentRoute?.name === 'ChatRoom' &&
                    (currentRoute.params as any)?.chatId === newestChatNotif.chatId
                  ) {
                    return;
                  }
                }
              } catch (_) {}

              get().showBanner(newestChatNotif);
            }
          } catch (e) {
            console.warn('[useNotificationStore] computeChats error:', e);
            unreadChatCount = 0;
            emitCounts();
          }
        };

        const unsubBuyer = db.collection('chats').where('buyerId', '==', uid).onSnapshot(
          (snapshot: any) => {
            buyerChats = [];
            if (snapshot && typeof snapshot.forEach === 'function') {
              snapshot.forEach((doc: any) => buyerChats.push(doc));
            }
            computeChats();
          },
          () => computeChats()
        );

        const unsubSeller = db.collection('chats').where('sellerId', '==', uid).onSnapshot(
          (snapshot: any) => {
            sellerChats = [];
            if (snapshot && typeof snapshot.forEach === 'function') {
              snapshot.forEach((doc: any) => sellerChats.push(doc));
            }
            computeChats();
          },
          () => computeChats()
        );

        const unsubPart = db.collection('chats').where('participants', 'array-contains', uid).onSnapshot(
          (snapshot: any) => {
            partChats = [];
            if (snapshot && typeof snapshot.forEach === 'function') {
              snapshot.forEach((doc: any) => partChats.push(doc));
            }
            computeChats();
          },
          () => computeChats()
        );

        unsubChats = () => {
          try { unsubBuyer(); } catch (_) {}
          try { unsubSeller(); } catch (_) {}
          try { unsubPart(); } catch (_) {}
        };

        // 2. Listen to personal notifications collection (queries recipientId)
        unsubNotifs = db
          .collection('notifications')
          .where('recipientId', '==', uid)
          .onSnapshot(
            async (snapshot: any) => {
              if (!isMounted) return;
              let count = 0;
              let newestNotif: BannerNotification | null = null;
              try {
                const deletedData = await getLocalDeletedNotifsData();
                const seenChatIds = new Set<string>();

                if (snapshot && typeof snapshot.forEach === 'function') {
                  snapshot.forEach((doc: any) => {
                    const data = { id: doc.id, ...(doc.data ? doc.data() : doc) };
                    if (isNotificationLocallyDeleted(data, deletedData, uid)) return;
                    if (data.read === true) return;

                    // Ignore messages sent by oneself
                    if (data?.senderId && String(data.senderId).trim().toLowerCase() === String(uid).trim().toLowerCase()) {
                      return;
                    }

                    const cKey = data.chatId || data.id;
                    if (cKey && seenChatIds.has(cKey)) return;
                    if (cKey) seenChatIds.add(cKey);

                    count += 1;
                    const notifTime = parseNotificationTime(data.createdAt || data.timestamp);
                    const newestTime = newestNotif ? newestNotif.createdAt : 0;

                    if (notifTime > newestTime) {
                      newestNotif = {
                        id: doc.id,
                        chatId: data.chatId,
                        partId: data.partId,
                        partTitle: data.partTitle || 'Auto Spare Part',
                        partPrice: Number(data.partPrice) || 0,
                        partImageUrl: data.partImageUrl || '',
                        senderId: data.senderId,
                        senderName: data.senderName || 'Verified Seller',
                        senderPhoto: data.senderPhoto || '',
                        buyerId: data.buyerId,
                        buyerName: data.buyerName,
                        sellerId: data.sellerId,
                        sellerName: data.sellerName,
                        text: data.text || 'New message received',
                        createdAt: notifTime,
                        timestamp: notifTime,
                        type: data.type || 'chat_message',
                      };
                    }
                  });
                }
              } catch (_) {}

              unreadNotifCount = count;
              emitCounts(newestNotif);

              if (newestNotif && (newestNotif.createdAt >= sessionStartTime - 30000 || Date.now() - newestNotif.createdAt < 180000)) {
                try {
                  if (navigationRef.isReady()) {
                    const currentRoute = navigationRef.getCurrentRoute();
                    if (
                      currentRoute?.name === 'ChatRoom' &&
                      (currentRoute.params as any)?.chatId === newestNotif.chatId
                    ) {
                      return;
                    }
                  }
                } catch (_) {}

                get().showBanner(newestNotif);
              }
            },
            () => {
              unreadNotifCount = 0;
              emitCounts();
            }
          );
      }
    } catch (e) {
      console.warn('[useNotificationStore] Listener init exception:', e);
    }

    const cleanup = () => {
      isMounted = false;
      try { unsubChats(); } catch (_) {}
      try { unsubNotifs(); } catch (_) {}
      try { unsubAnnouncements(); } catch (_) {}
    };

    activeListenerCleanup = cleanup;
    return cleanup;
  },
}));
