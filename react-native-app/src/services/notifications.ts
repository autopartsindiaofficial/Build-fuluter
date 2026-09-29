import AsyncStorage from '@react-native-async-storage/async-storage';
import { getFirebaseFirestore, getCurrentUser } from './firebase';

const READ_ANNOUNCEMENTS_STORAGE_KEY = '@autoparts_read_announcements';
const HIDDEN_CHATS_MAP_STORAGE_KEY = '@autoparts_hidden_chats_map_v2';
const DELETED_NOTIFS_STORAGE_KEY = '@autoparts_deleted_notifs_v2';
const DELETED_ANNOUNCEMENTS_STORAGE_KEY = '@autoparts_deleted_announcements_v2';

/**
 * Parses any timestamp format (Firestore timestamp object, seconds, ISO string, or number) into epoch millis
 */
export function parseNotificationTime(ts: any): number {
  if (!ts) return 0;
  if (typeof ts === 'number') return ts;
  if (typeof ts === 'string') {
    const parsed = Date.parse(ts);
    return isNaN(parsed) ? 0 : parsed;
  }
  if (typeof ts === 'object') {
    if (typeof ts.toMillis === 'function') return ts.toMillis();
    if (typeof ts.seconds === 'number') return ts.seconds * 1000 + (ts.nanoseconds ? Math.floor(ts.nanoseconds / 1000000) : 0);
  }
  return 0;
}

// ----------------------------------------------------
// 1. HIDDEN CHATS MANAGEMENT (Time-Aware)
// ----------------------------------------------------

/**
 * Returns map of { [chatId]: hiddenAtTimestamp }
 */
export async function getLocalHiddenChatsMap(): Promise<Record<string, number>> {
  try {
    const raw = await AsyncStorage.getItem(HIDDEN_CHATS_MAP_STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
        return parsed;
      }
    }
  } catch (_) {}
  return {};
}

/**
 * Legacy compatibility: returns a Set of hidden chat IDs
 */
export async function getLocalHiddenChatIds(): Promise<Set<string>> {
  const map = await getLocalHiddenChatsMap();
  return new Set(Object.keys(map));
}

/**
 * Marks a chat as hidden locally with deletion timestamp
 */
export async function addLocalHiddenChatId(chatId: string, timestamp?: number): Promise<void> {
  if (!chatId) return;
  try {
    const map = await getLocalHiddenChatsMap();
    map[chatId] = timestamp || Date.now();
    await AsyncStorage.setItem(HIDDEN_CHATS_MAP_STORAGE_KEY, JSON.stringify(map));
  } catch (err) {
    console.warn('[notifications] addLocalHiddenChatId error:', err);
  }
}

/**
 * Unhides a chat when new message arrives or user opens the chat
 */
export async function removeLocalHiddenChatId(chatId: string): Promise<void> {
  if (!chatId) return;
  try {
    const map = await getLocalHiddenChatsMap();
    if (map[chatId]) {
      delete map[chatId];
      await AsyncStorage.setItem(HIDDEN_CHATS_MAP_STORAGE_KEY, JSON.stringify(map));
    }
  } catch (err) {
    console.warn('[notifications] removeLocalHiddenChatId error:', err);
  }
}

/**
 * Determines if a chat should be hidden from UI
 * If a new message arrived AFTER the deletion timestamp, it automatically unhides!
 */
export function isChatLocallyHidden(chatId: string, lastMessageTime: any, hiddenMap: Record<string, number>): boolean {
  if (!chatId || !hiddenMap || !hiddenMap[chatId]) return false;
  const hiddenAt = hiddenMap[chatId];
  const msgTime = parseNotificationTime(lastMessageTime);
  // If the chat has activity strictly after it was hidden, do not hide
  if (msgTime > hiddenAt) {
    return false;
  }
  return true;
}

// ----------------------------------------------------
// 2. ANNOUNCEMENTS READ & DELETED STATE
// ----------------------------------------------------

export async function getLocalReadAnnouncementIds(): Promise<Set<string>> {
  try {
    const raw = await AsyncStorage.getItem(READ_ANNOUNCEMENTS_STORAGE_KEY);
    if (raw) {
      const arr = JSON.parse(raw);
      if (Array.isArray(arr)) return new Set<string>(arr);
    }
  } catch (_) {}
  return new Set<string>();
}

export async function markAnnouncementsAsRead(announcementIds: string[]): Promise<void> {
  if (!announcementIds || announcementIds.length === 0) return;
  try {
    const existingSet = await getLocalReadAnnouncementIds();
    announcementIds.forEach((id) => id && existingSet.add(id));
    await AsyncStorage.setItem(READ_ANNOUNCEMENTS_STORAGE_KEY, JSON.stringify(Array.from(existingSet)));

    const user = getCurrentUser();
    const uid = user?.uid || user?.id;
    if (uid) {
      const db = getFirebaseFirestore();
      if (db && typeof db.collection === 'function') {
        const batchPromises = announcementIds.map((id) =>
          db
            .collection('users')
            .doc(uid)
            .collection('read_announcements')
            .doc(id)
            .set({ readAt: Date.now() }, { merge: true })
            .catch(() => {})
        );
        await Promise.all(batchPromises);
      }
    }
  } catch (err) {
    console.warn('[notifications] Error marking announcements as read:', err);
  }
}

export async function getLocalDeletedAnnouncementIds(): Promise<Set<string>> {
  try {
    const raw = await AsyncStorage.getItem(DELETED_ANNOUNCEMENTS_STORAGE_KEY);
    if (raw) {
      const arr = JSON.parse(raw);
      if (Array.isArray(arr)) return new Set<string>(arr);
    }
  } catch (_) {}
  return new Set<string>();
}

export async function deleteAnnouncementForUser(announcementId: string): Promise<void> {
  if (!announcementId) return;
  try {
    const set = await getLocalDeletedAnnouncementIds();
    set.add(announcementId);
    await AsyncStorage.setItem(DELETED_ANNOUNCEMENTS_STORAGE_KEY, JSON.stringify(Array.from(set)));

    const user = getCurrentUser();
    const uid = user?.uid || user?.id;
    if (uid) {
      const db = getFirebaseFirestore();
      if (db && typeof db.collection === 'function') {
        await db
          .collection('users')
          .doc(uid)
          .collection('deleted_announcements')
          .doc(announcementId)
          .set({ deletedAt: Date.now() }, { merge: true })
          .catch(() => {});
      }
    }
  } catch (err) {
    console.warn('[notifications] Error deleting announcement for user:', err);
  }
}

export async function deleteMultipleAnnouncementsForUser(announcementIds: string[]): Promise<void> {
  if (!announcementIds || announcementIds.length === 0) return;
  try {
    const set = await getLocalDeletedAnnouncementIds();
    announcementIds.forEach((id) => id && set.add(id));
    await AsyncStorage.setItem(DELETED_ANNOUNCEMENTS_STORAGE_KEY, JSON.stringify(Array.from(set)));

    const user = getCurrentUser();
    const uid = user?.uid || user?.id;
    if (uid) {
      const db = getFirebaseFirestore();
      if (db && typeof db.collection === 'function') {
        const promises = announcementIds.map((annId) =>
          db
            .collection('users')
            .doc(uid)
            .collection('deleted_announcements')
            .doc(annId)
            .set({ deletedAt: Date.now() }, { merge: true })
            .catch(() => {})
        );
        await Promise.all(promises);
      }
    }
  } catch (err) {
    console.warn('[notifications] Error deleting multiple announcements:', err);
  }
}

// ----------------------------------------------------
// 3. PERSONAL NOTIFICATIONS DELETION (Strictly Per-User Isolated)
// ----------------------------------------------------

interface DeletedNotifsData {
  deletedDocIds: string[];
  deletedChatTimestamps: Record<string, number>; // chatId -> deletedAt
}

export function getUserDeletedNotifsStorageKey(uid?: string): string {
  const user = uid || getCurrentUser()?.uid || getCurrentUser()?.id || 'guest';
  return `@autoparts_deleted_notifs_v3_${user}`;
}

export async function getLocalDeletedNotifsData(uid?: string): Promise<DeletedNotifsData> {
  const targetUid = uid || getCurrentUser()?.uid || getCurrentUser()?.id;
  const storageKey = getUserDeletedNotifsStorageKey(targetUid);
  
  let result: DeletedNotifsData = { deletedDocIds: [], deletedChatTimestamps: {} };

  try {
    const raw = await AsyncStorage.getItem(storageKey);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (parsed) {
        result = {
          deletedDocIds: Array.isArray(parsed.deletedDocIds) ? parsed.deletedDocIds : [],
          deletedChatTimestamps: parsed.deletedChatTimestamps && typeof parsed.deletedChatTimestamps === 'object'
            ? parsed.deletedChatTimestamps
            : {},
        };
      }
    }
  } catch (_) {}

  // Also sync remote per-user deleted notifications from Firestore if logged in
  if (targetUid) {
    try {
      const db = getFirebaseFirestore();
      if (db && typeof db.collection === 'function') {
        const snap = await db
          .collection('users')
          .doc(targetUid)
          .collection('deleted_notifications')
          .get()
          .catch(() => null);

        if (snap && snap.docs) {
          snap.docs.forEach((doc: any) => {
            const docId = doc.id;
            if (docId && !result.deletedDocIds.includes(docId)) {
              result.deletedDocIds.push(docId);
            }
            const data = doc.data ? doc.data() : doc;
            if (data?.chatId && data?.deletedAt) {
              const existingTs = result.deletedChatTimestamps[data.chatId] || 0;
              if (data.deletedAt > existingTs) {
                result.deletedChatTimestamps[data.chatId] = data.deletedAt;
              }
            }
          });
        }
      }
    } catch (_) {}
  }

  return result;
}

export async function getLocalDeletedNotificationIds(uid?: string): Promise<Set<string>> {
  const data = await getLocalDeletedNotifsData(uid);
  return new Set(data.deletedDocIds);
}

/**
 * Checks if a specific notification item is deleted for the current user
 */
export function isNotificationLocallyDeleted(notif: any, deletedData: DeletedNotifsData, currentUid?: string): boolean {
  if (!notif) return true;
  const docId = notif.id;

  // Check if current user explicitly deleted it (via deletedFor array on the doc)
  if (currentUid && Array.isArray(notif.deletedFor)) {
    const isUserInDeletedFor = notif.deletedFor.some(
      (id: any) => String(id).trim().toLowerCase() === String(currentUid).trim().toLowerCase()
    );
    if (isUserInDeletedFor) return true;
  }

  // Check if deleted globally ONLY IF recipientId matches current user or is user-owned
  if (notif.deleted === true) {
    if (currentUid && notif.recipientId) {
      if (String(notif.recipientId).trim().toLowerCase() === String(currentUid).trim().toLowerCase()) {
        return true;
      }
    }
  }

  // Check timestamp for the chat
  if (notif.chatId && deletedData.deletedChatTimestamps && deletedData.deletedChatTimestamps[notif.chatId]) {
    const deletedAt = deletedData.deletedChatTimestamps[notif.chatId];
    const notifCreatedAt = parseNotificationTime(notif.createdAt || notif.timestamp);
    if (notifCreatedAt <= deletedAt) {
      return true;
    }
    // If newer than deletedAt, this is an active recent notification for the chat
    return false;
  }

  if (docId && deletedData.deletedDocIds.includes(docId)) {
    return true;
  }

  return false;
}

/**
 * Deletes a single notification strictly for the current user (does NOT delete globally for other users)
 */
export async function deleteNotification(notificationId: string, chatId?: string, uidOverride?: string): Promise<void> {
  if (!notificationId) return;
  const now = Date.now();
  const user = getCurrentUser();
  const uid = uidOverride || user?.uid || user?.id;
  const storageKey = getUserDeletedNotifsStorageKey(uid);

  try {
    const data = await getLocalDeletedNotifsData(uid);
    if (!data.deletedDocIds.includes(notificationId)) {
      data.deletedDocIds.push(notificationId);
    }
    if (chatId) {
      data.deletedChatTimestamps[chatId] = now;
      data.deletedDocIds.push(`chat_inq_${chatId}`);
    }
    await AsyncStorage.setItem(storageKey, JSON.stringify(data));

    const db = getFirebaseFirestore();

    if (db && typeof db.collection === 'function' && uid) {
      // 1. Store in user's private deleted_notifications collection in Firestore
      await db
        .collection('users')
        .doc(uid)
        .collection('deleted_notifications')
        .doc(notificationId)
        .set({
          deletedAt: now,
          chatId: chatId || null,
          notificationId,
        }, { merge: true })
        .catch(() => {});

      // 2. Mark deletedFor array on the notification doc WITHOUT deleting the doc globally for other users
      try {
        const notifRef = db.collection('notifications').doc(notificationId);
        const docSnap = await notifRef.get().catch(() => null);
        if (docSnap && docSnap.exists) {
          const docData = docSnap.data ? docSnap.data() : docSnap;
          const currentDeletedFor = Array.isArray(docData?.deletedFor) ? docData.deletedFor : [];
          if (!currentDeletedFor.includes(uid)) {
            currentDeletedFor.push(uid);
          }
          await notifRef.set({
            deletedFor: currentDeletedFor,
            updatedAt: now,
          }, { merge: true }).catch(() => {});
        }
      } catch (_) {}
    }
  } catch (e) {
    console.warn('[notifications] Error deleting notification for user:', e);
  }
}

/**
 * Deletes all personal notifications for a user (strictly per-user scope)
 */
export async function deleteAllPersonalNotifications(userId: string, currentNotificationIds: string[] = []): Promise<void> {
  if (!userId) return;
  const now = Date.now();
  const storageKey = getUserDeletedNotifsStorageKey(userId);

  try {
    const data = await getLocalDeletedNotifsData(userId);
    currentNotificationIds.forEach((id) => {
      if (id && !data.deletedDocIds.includes(id)) {
        data.deletedDocIds.push(id);
      }
    });

    const db = getFirebaseFirestore();
    if (db && typeof db.collection === 'function') {
      const batchPromises = currentNotificationIds.map(async (notifId) => {
        if (!notifId) return;
        // Record in user's private deleted_notifications
        db.collection('users')
          .doc(userId)
          .collection('deleted_notifications')
          .doc(notifId)
          .set({ deletedAt: now, notificationId: notifId }, { merge: true })
          .catch(() => {});

        // Add userId to deletedFor array on notification document
        try {
          const notifRef = db.collection('notifications').doc(notifId);
          const docSnap = await notifRef.get().catch(() => null);
          if (docSnap && docSnap.exists) {
            const docData = docSnap.data ? docSnap.data() : docSnap;
            const currentDeletedFor = Array.isArray(docData?.deletedFor) ? docData.deletedFor : [];
            if (!currentDeletedFor.includes(userId)) {
              currentDeletedFor.push(userId);
            }
            await notifRef.set({ deletedFor: currentDeletedFor, updatedAt: now }, { merge: true }).catch(() => {});
          }
        } catch (_) {}
      });

      await Promise.all(batchPromises);
    }

    await AsyncStorage.setItem(storageKey, JSON.stringify(data));
  } catch (e) {
    console.warn('[notifications] Error deleting all personal notifications:', e);
  }
}

// ----------------------------------------------------
// 4. SEND REAL-TIME CHAT NOTIFICATION
// ----------------------------------------------------

export async function sendChatMessageNotification(params: {
  chatId: string;
  recipientId: string;
  senderId: string;
  senderName: string;
  senderPhoto?: string;
  text: string;
  partId?: string;
  partTitle?: string;
  partPrice?: number;
  partImageUrl?: string;
  buyerId?: string;
  buyerName?: string;
  sellerId?: string;
  sellerName?: string;
}): Promise<void> {
  const {
    chatId,
    recipientId,
    senderId,
    senderName,
    senderPhoto,
    text,
    partId,
    partTitle,
    partPrice,
    partImageUrl,
    buyerId,
    buyerName,
    sellerId,
    sellerName,
  } = params;

  if (!chatId || !recipientId || !senderId) return;
  const cleanRecipient = String(recipientId).trim().toLowerCase();
  const cleanSender = String(senderId).trim().toLowerCase();
  if (cleanRecipient === cleanSender) return;

  const now = Date.now();
  // Single deterministic conversation document ID per recipient per chat to avoid duplicate count inflation
  const conversationNotificationId = `chat_notif_${chatId}_${recipientId}`;

  try {
    const db = getFirebaseFirestore();
    if (db && typeof db.collection === 'function') {
      const payload = {
        id: conversationNotificationId,
        notificationId: conversationNotificationId,
        chatId,
        recipientId,
        senderId,
        senderName: senderName || 'User',
        senderPhoto: senderPhoto || '',
        text: text || 'Sent a message',
        createdAt: now,
        timestamp: now,
        read: false,
        deleted: false,
        deletedFor: [],
        type: 'chat_message',
        partId: partId || '',
        partTitle: partTitle || 'Spare Part',
        partPrice: Number(partPrice) || 0,
        partImageUrl: partImageUrl || '',
        buyerId: buyerId || '',
        buyerName: buyerName || '',
        sellerId: sellerId || '',
        sellerName: sellerName || '',
      };

      await db.collection('notifications').doc(conversationNotificationId).set(payload, { merge: true });
    }
  } catch (e) {
    console.warn('[notifications] Error saving chat notification to Firestore:', e);
  }
}

// ----------------------------------------------------
// 5. READ STATUS MANAGEMENT
// ----------------------------------------------------

export async function markNotificationAsRead(notificationId: string): Promise<void> {
  if (!notificationId) return;
  try {
    const db = getFirebaseFirestore();
    if (db && typeof db.collection === 'function') {
      await db.collection('notifications').doc(notificationId).set({
        read: true,
        readAt: Date.now(),
      }, { merge: true }).catch(() => {});

      if (notificationId.startsWith('chat_inq_')) {
        const cId = notificationId.replace('chat_inq_', '');
        const user = getCurrentUser();
        const uid = user?.uid || user?.id;
        if (uid) {
          await db.collection('notifications').doc(`${cId}_${uid}`).set({
            read: true,
            readAt: Date.now(),
          }, { merge: true }).catch(() => {});
        }
      }
    }
  } catch (e) {
    console.warn('[notifications] Error marking notification as read:', e);
  }
}

export async function markChatNotificationsAsRead(chatId: string, recipientId: string): Promise<void> {
  if (!chatId || !recipientId) return;
  try {
    const db = getFirebaseFirestore();
    if (db && typeof db.collection === 'function') {
      const deterministicIds = [
        `chat_notif_${chatId}_${recipientId}`,
        `${chatId}_${recipientId}`,
        `chat_inq_${chatId}`,
      ];
      deterministicIds.forEach((docId) => {
        db.collection('notifications').doc(docId).set({
          read: true,
          readAt: Date.now(),
        }, { merge: true }).catch(() => {});
      });

      const snap = await db
        .collection('notifications')
        .where('chatId', '==', chatId)
        .where('recipientId', '==', recipientId)
        .where('read', '==', false)
        .get()
        .catch(() => null);

      if (snap && snap.docs && snap.docs.length > 0) {
        snap.docs.forEach((d: any) => {
          d.ref.set({ read: true, readAt: Date.now() }, { merge: true }).catch(() => {});
        });
      }
    }
  } catch (e) {
    console.warn('[notifications] Error marking chat notifications as read:', e);
  }
}

export async function markAllUserNotificationsAsRead(userId: string): Promise<void> {
  if (!userId) return;
  try {
    const db = getFirebaseFirestore();
    if (db && typeof db.collection === 'function') {
      const snap = await db.collection('notifications')
        .where('recipientId', '==', userId)
        .where('read', '==', false)
        .get()
        .catch(() => null);

      if (snap && snap.docs) {
        const promises = snap.docs.map((docSnap: any) =>
          docSnap.ref.update({ read: true, readAt: Date.now() }).catch(() => {})
        );
        await Promise.all(promises);
      }
    }
  } catch (e) {
    console.warn('[notifications] Error marking all notifications as read:', e);
  }
}

// ----------------------------------------------------
// 6. REAL-TIME UNREAD COUNTS & BANNER NOTIFICATION FEED
// ----------------------------------------------------

export function subscribeToUserUnreadCounts(
  userId: string | null | undefined,
  callback: (counts: {
    unreadChats: number;
    unreadNotifications: number;
    totalUnread: number;
    latestNotification?: any;
  }) => void
): () => void {
  if (!userId) {
    callback({ unreadChats: 0, unreadNotifications: 0, totalUnread: 0 });
    return () => {};
  }

  let isMounted = true;
  let unreadChatCount = 0;
  let unreadNotifCount = 0;
  let unreadAnnounceCount = 0;
  let latestNotifItem: any = null;

  let unsubChats = () => {};
  let unsubNotifs = () => {};
  let unsubAnnouncements = () => {};

  const emit = () => {
    if (!isMounted) return;
    const totalNotifs = unreadNotifCount + unreadAnnounceCount;
    callback({
      unreadChats: unreadChatCount,
      unreadNotifications: totalNotifs,
      totalUnread: unreadChatCount + totalNotifs,
      latestNotification: latestNotifItem,
    });
  };

  try {
    const db = getFirebaseFirestore();
    if (!db || typeof db.collection !== 'function') {
      callback({ unreadChats: 0, unreadNotifications: 0, totalUnread: 0 });
      return () => {};
    }

    // 1. Listen to unread chats
    let buyerChats: any[] = [];
    let sellerChats: any[] = [];
    let partChats: any[] = [];

    const computeUnread = async () => {
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
          if (Array.isArray(data.hiddenFor) && data.hiddenFor.includes(userId)) {
            const clearedTime = parseNotificationTime(data.clearedAt?.[userId]);
            if (clearedTime && msgTime <= clearedTime) return;
          }
          chatsMap.set(docId, data);
        });

        let count = 0;
        chatsMap.forEach((data) => {
          const isSenderMe = data && data.lastSenderId && data.lastSenderId === userId;
          if (isSenderMe) return;

          const unreadFromMap = typeof data?.unreadCount?.[userId] === 'number' 
            ? data.unreadCount[userId] 
            : 0;
          const hasUnreadFlag = data && data.lastSenderId && data.lastSenderId !== userId && data.unread === true;
          if (unreadFromMap > 0 || hasUnreadFlag) {
            count += 1;
          }
        });
        unreadChatCount = count;
        emit();
      } catch (_) {
        unreadChatCount = 0;
        emit();
      }
    };

    const unsubBuyer = db.collection('chats').where('buyerId', '==', userId).onSnapshot(
      (snapshot: any) => {
        buyerChats = [];
        if (snapshot && typeof snapshot.forEach === 'function') {
          snapshot.forEach((doc: any) => buyerChats.push(doc));
        }
        computeUnread();
      },
      () => computeUnread()
    );

    const unsubSeller = db.collection('chats').where('sellerId', '==', userId).onSnapshot(
      (snapshot: any) => {
        sellerChats = [];
        if (snapshot && typeof snapshot.forEach === 'function') {
          snapshot.forEach((doc: any) => sellerChats.push(doc));
        }
        computeUnread();
      },
      () => computeUnread()
    );

    const unsubPart = db.collection('chats').where('participants', 'array-contains', userId).onSnapshot(
      (snapshot: any) => {
        partChats = [];
        if (snapshot && typeof snapshot.forEach === 'function') {
          snapshot.forEach((doc: any) => partChats.push(doc));
        }
        computeUnread();
      },
      () => computeUnread()
    );

    unsubChats = () => {
      unsubBuyer();
      unsubSeller();
      unsubPart();
    };

    // 2. Listen to unread personal notifications
    unsubNotifs = db
      .collection('notifications')
      .where('recipientId', '==', userId)
      .where('read', '==', false)
      .onSnapshot(
        async (snapshot: any) => {
          let count = 0;
          let newest: any = null;
          try {
            const deletedData = await getLocalDeletedNotifsData();
            const seenChatIds = new Set<string>();
            if (snapshot && typeof snapshot.forEach === 'function') {
              snapshot.forEach((doc: any) => {
                const data = { id: doc.id, ...(doc.data ? doc.data() : doc) };
                if (isNotificationLocallyDeleted(data, deletedData, userId)) return;
                // Ignore self-sent messages
                if (data?.senderId && String(data.senderId).trim().toLowerCase() === String(userId).trim().toLowerCase()) {
                  return;
                }
                const cKey = data.chatId || data.id;
                if (cKey && seenChatIds.has(cKey)) return;
                if (cKey) seenChatIds.add(cKey);
                count += 1;
                const notifTime = parseNotificationTime(data.createdAt || data.timestamp);
                const newestTime = newest ? parseNotificationTime(newest.createdAt || newest.timestamp) : 0;
                if (data?.senderId !== userId && (!newest || notifTime > newestTime)) {
                  newest = data;
                }
              });
            }
          } catch (_) {}
          unreadNotifCount = count;
          latestNotifItem = newest;
          emit();
        },
        () => {
          unreadNotifCount = 0;
          emit();
        }
      );

    // 3. Listen to announcements
    unsubAnnouncements = db
      .collection('announcements')
      .limit(20)
      .onSnapshot(
        async (snapshot: any) => {
          try {
            const readSet = await getLocalReadAnnouncementIds();
            const deletedSet = await getLocalDeletedAnnouncementIds();
            let count = 0;
            if (snapshot && typeof snapshot.forEach === 'function') {
              snapshot.forEach((doc: any) => {
                const docId = doc.id;
                if (docId && (deletedSet.has(docId) || readSet.has(docId))) return;
                count += 1;
              });
            }
            unreadAnnounceCount = count;
            emit();
          } catch (_) {
            unreadAnnounceCount = 0;
            emit();
          }
        },
        () => {
          unreadAnnounceCount = 0;
          emit();
        }
      );
  } catch (err) {
    console.warn('[notifications] Error in subscribeToUserUnreadCounts:', err);
    callback({ unreadChats: 0, unreadNotifications: 0, totalUnread: 0 });
  }

  return () => {
    isMounted = false;
    try { unsubChats(); } catch (_) {}
    try { unsubNotifs(); } catch (_) {}
    try { unsubAnnouncements(); } catch (_) {}
  };
}

export function subscribeToUnreadNotificationCount(
  callback: (unreadCount: number) => void
): () => void {
  const user = getCurrentUser();
  const uid = user?.uid || user?.id;

  return subscribeToUserUnreadCounts(uid, (res) => {
    callback(res.totalUnread);
  });
}
