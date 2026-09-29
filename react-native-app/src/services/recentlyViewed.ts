import AsyncStorage from '@react-native-async-storage/async-storage';
import { useState, useEffect, useCallback } from 'react';
import { getCurrentUser, getFirebaseAuth, getFirebaseFirestore } from './firebase';

const OLD_STORAGE_KEY = '@autoparts_recently_viewed_v1';
const USER_STORAGE_PREFIX = '@autoparts_recently_viewed_user_v2_';
const GUEST_STORAGE_KEY = '@autoparts_recently_viewed_guest_v2';
const MAX_RECENT_ITEMS = 25;

// Clean up legacy shared key to prevent cross-account data leakage
AsyncStorage.removeItem(OLD_STORAGE_KEY).catch(() => {});

// Active listeners for reactive UI updates
const listeners = new Set<(items: any[], activeUid: string | null) => void>();

export function getActiveUserId(): string | null {
  try {
    const user = getCurrentUser();
    return user?.uid || user?.id || null;
  } catch (_) {
    return null;
  }
}

export function getRecentlyViewedStorageKey(userId?: string | null): string {
  const uid = userId !== undefined ? userId : getActiveUserId();
  return uid ? `${USER_STORAGE_PREFIX}${uid}` : GUEST_STORAGE_KEY;
}

export function subscribeRecentlyViewed(callback: (items: any[], activeUid: string | null) => void): () => void {
  listeners.add(callback);
  return () => {
    listeners.delete(callback);
  };
}

function notifyListeners(items: any[], uid: string | null) {
  listeners.forEach((listener) => {
    try {
      listener(items, uid);
    } catch (_) {}
  });
}

// Listen to auth state changes so when user switches or logs out,
// all screens immediately switch to that specific user's recently viewed list
try {
  const auth = getFirebaseAuth();
  if (auth && typeof auth.onAuthStateChanged === 'function') {
    let lastUid: string | null = getActiveUserId();
    auth.onAuthStateChanged((user: any) => {
      const currentUid = user?.uid || user?.id || null;
      if (currentUid !== lastUid) {
        lastUid = currentUid;
        getRecentlyViewedParts(currentUid).then((items) => {
          notifyListeners(items, currentUid);
        }).catch(() => {});
      }
    });
  }
} catch (_) {}

/**
 * Add a spare part to the active user's recently viewed list.
 * Completely scoped to current user ID (or explicitUserId).
 */
export async function addRecentlyViewedPart(part: any, explicitUserId?: string): Promise<void> {
  if (!part || !part.id) return;
  const targetUserId = explicitUserId !== undefined ? explicitUserId : getActiveUserId();
  const storageKey = getRecentlyViewedStorageKey(targetUserId);

  try {
    const raw = await AsyncStorage.getItem(storageKey);
    let items: any[] = raw ? JSON.parse(raw) : [];

    // Filter out if already present to move to top
    items = items.filter((item: any) => item && item.id !== part.id);

    // Create sanitized, lightweight recent item
    const recentItem = {
      id: part.id,
      title: part.title || part.name || part.partName || 'Spare Part',
      partName: part.partName || part.title || part.name || 'Spare Part',
      price: Number(part.price || part.partPrice || 0),
      carBrand: part.carBrand || part.brand || '',
      carModel: part.carModel || part.model || '',
      category: part.category || '',
      imageUrl: part.imageUrl || part.image || part.images?.[0] || part.imageUrls?.[0] || '',
      imageUrls: part.imageUrls || (part.imageUrl ? [part.imageUrl] : []),
      location: part.location || part.district || part.state || 'India',
      district: part.district || part.location || '',
      state: part.state || '',
      condition: part.condition || 'Used',
      viewedAt: Date.now(),
      sold: Boolean(part.sold),
    };

    items.unshift(recentItem);

    if (items.length > MAX_RECENT_ITEMS) {
      items = items.slice(0, MAX_RECENT_ITEMS);
    }

    // Save to user-specific local storage
    await AsyncStorage.setItem(storageKey, JSON.stringify(items));

    // Notify listeners so UI updates instantly
    notifyListeners(items, targetUserId);

    // Sync to user profile in Firestore if logged in
    if (targetUserId) {
      try {
        const db = getFirebaseFirestore();
        if (db && typeof db.collection === 'function') {
          db.collection('users').doc(targetUserId).set(
            {
              recentlyViewed: items,
              recentlyViewedUpdatedAt: Date.now(),
            },
            { merge: true }
          ).catch((err: any) => {
            console.warn('[RecentlyViewed] Firestore cloud sync warning:', err);
          });
        }
      } catch (_) {}
    }
  } catch (err) {
    console.warn('[RecentlyViewed] Error saving item for user:', targetUserId, err);
  }
}

/**
 * Get recently viewed parts for the current logged-in user ID (or explicitUserId).
 * Will not return parts viewed by other user IDs.
 */
export async function getRecentlyViewedParts(explicitUserId?: string | null): Promise<any[]> {
  const targetUserId = explicitUserId !== undefined ? explicitUserId : getActiveUserId();
  const storageKey = getRecentlyViewedStorageKey(targetUserId);

  try {
    const raw = await AsyncStorage.getItem(storageKey);
    let items: any[] = raw ? JSON.parse(raw) : [];

    // If local storage is empty and user is logged in, attempt to restore from Firestore user document
    if ((!items || items.length === 0) && targetUserId) {
      try {
        const db = getFirebaseFirestore();
        if (db && typeof db.collection === 'function') {
          const userDocSnap = await db.collection('users').doc(targetUserId).get();
          const data = typeof userDocSnap?.data === 'function' ? userDocSnap.data() : userDocSnap?.data;
          if (data && Array.isArray(data.recentlyViewed) && data.recentlyViewed.length > 0) {
            items = data.recentlyViewed;
            await AsyncStorage.setItem(storageKey, JSON.stringify(items));
          }
        }
      } catch (_) {}
    }

    return Array.isArray(items) ? items : [];
  } catch (err) {
    console.warn('[RecentlyViewed] Error reading items for user:', targetUserId, err);
    return [];
  }
}

/**
 * Clear recently viewed history for the active user only.
 */
export async function clearRecentlyViewedParts(explicitUserId?: string): Promise<void> {
  const targetUserId = explicitUserId !== undefined ? explicitUserId : getActiveUserId();
  const storageKey = getRecentlyViewedStorageKey(targetUserId);

  try {
    await AsyncStorage.removeItem(storageKey);
    notifyListeners([], targetUserId);

    if (targetUserId) {
      try {
        const db = getFirebaseFirestore();
        if (db && typeof db.collection === 'function') {
          db.collection('users').doc(targetUserId).set(
            {
              recentlyViewed: [],
              recentlyViewedUpdatedAt: Date.now(),
            },
            { merge: true }
          ).catch(() => {});
        }
      } catch (_) {}
    }
  } catch (err) {
    console.warn('[RecentlyViewed] Error clearing items for user:', targetUserId, err);
  }
}

/**
 * Remove a specific part from the active user's recently viewed list.
 */
export async function removeRecentlyViewedPart(partId: string, explicitUserId?: string): Promise<void> {
  if (!partId) return;
  const targetUserId = explicitUserId !== undefined ? explicitUserId : getActiveUserId();
  const storageKey = getRecentlyViewedStorageKey(targetUserId);

  try {
    const raw = await AsyncStorage.getItem(storageKey);
    if (!raw) return;
    let items: any[] = JSON.parse(raw);
    items = items.filter((item: any) => item && item.id !== partId);
    await AsyncStorage.setItem(storageKey, JSON.stringify(items));

    notifyListeners(items, targetUserId);

    if (targetUserId) {
      try {
        const db = getFirebaseFirestore();
        if (db && typeof db.collection === 'function') {
          db.collection('users').doc(targetUserId).set(
            {
              recentlyViewed: items,
              recentlyViewedUpdatedAt: Date.now(),
            },
            { merge: true }
          ).catch(() => {});
        }
      } catch (_) {}
    }
  } catch (err) {
    console.warn('[RecentlyViewed] Error removing item for user:', targetUserId, err);
  }
}

/**
 * React hook for consuming recently viewed parts with live reactive updates per user.
 */
export function useRecentlyViewed(customUserId?: string) {
  const [recentParts, setRecentParts] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const reload = useCallback(async () => {
    const list = await getRecentlyViewedParts(customUserId);
    setRecentParts(list);
    setLoading(false);
  }, [customUserId]);

  useEffect(() => {
    let isMounted = true;
    reload();

    const unsub = subscribeRecentlyViewed((items, activeUid) => {
      const currentTargetUid = customUserId !== undefined ? customUserId : getActiveUserId();
      if (activeUid === currentTargetUid && isMounted) {
        setRecentParts(items);
      }
    });

    return () => {
      isMounted = false;
      unsub();
    };
  }, [reload, customUserId]);

  return {
    recentParts,
    loading,
    reload,
    clear: () => clearRecentlyViewedParts(customUserId),
    remove: (partId: string) => removeRecentlyViewedPart(partId, customUserId),
  };
}

