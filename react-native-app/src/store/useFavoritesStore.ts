import { create } from 'zustand';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { getFirebaseFirestore, getCurrentUser } from '../services/firebase';

const STORAGE_KEY = 'autoparts_user_favorites';

interface FavoritesState {
  favorites: string[];
  isLoading: boolean;
  loadFavorites: () => Promise<void>;
  toggleFavorite: (partId: string) => Promise<boolean>;
  isFavorite: (partId: string) => boolean;
  setFavorites: (favorites: string[]) => void;
}

export const useFavoritesStore = create<FavoritesState>((set, get) => ({
  favorites: [],
  isLoading: false,

  loadFavorites: async () => {
    set({ isLoading: true });
    try {
      // 1. First hydrate quickly from local storage
      const stored = await AsyncStorage.getItem(STORAGE_KEY);
      if (stored) {
        try {
          const parsed = JSON.parse(stored);
          if (Array.isArray(parsed)) {
            set({ favorites: parsed });
          }
        } catch (_) {}
      }

      // 2. If user is authenticated, sync with cloud Firestore
      const user = getCurrentUser();
      const userId = user?.uid || user?.id;
      if (userId) {
        const db = getFirebaseFirestore();
        if (db) {
          const docRef = db.collection('user_favorites').doc(userId);
          const doc = await docRef.get();
          if (doc.exists) {
            const data = doc.data();
            if (data && Array.isArray(data.partIds)) {
              const merged = Array.from(new Set([...get().favorites, ...data.partIds]));
              set({ favorites: merged });
              await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(merged));
            }
          }
        }
      }
    } catch (err) {
      console.warn('[FavoritesStore] Error loading favorites:', err);
    } finally {
      set({ isLoading: false });
    }
  },

  toggleFavorite: async (partId: string): Promise<boolean> => {
    if (!partId) return false;
    const current = get().favorites;
    const exists = current.includes(partId);
    const updated = exists
      ? current.filter(id => id !== partId)
      : [...current, partId];

    // Optimistic state update
    set({ favorites: updated });

    try {
      await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
      const user = getCurrentUser();
      const userId = user?.uid || user?.id;
      if (userId) {
        const db = getFirebaseFirestore();
        if (db) {
          await db.collection('user_favorites').doc(userId).set({
            partIds: updated,
            updatedAt: new Date().toISOString(),
          }, { merge: true });
        }
      }
    } catch (err) {
      console.warn('[FavoritesStore] Error syncing toggle:', err);
    }

    return !exists;
  },

  isFavorite: (partId: string) => {
    return get().favorites.includes(partId);
  },

  setFavorites: (favorites: string[]) => {
    set({ favorites });
    AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(favorites)).catch(() => {});
  },
}));

// Initialize store immediately on module load
useFavoritesStore.getState().loadFavorites();
