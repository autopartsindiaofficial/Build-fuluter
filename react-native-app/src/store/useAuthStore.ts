import { create } from 'zustand';
import { getCurrentUser, getFirebaseAuth, getFirebaseFirestore } from '../services/firebase';

export interface UserProfile {
  uid: string;
  email?: string | null;
  displayName?: string | null;
  phoneNumber?: string | null;
  photoURL?: string | null;
  city?: string;
  role?: 'buyer' | 'seller' | 'admin';
  sellerBadge?: boolean;
}

interface AuthState {
  user: UserProfile | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  setUser: (user: UserProfile | null) => void;
  updateProfile: (updates: Partial<UserProfile>) => void;
  syncWithFirebase: () => void;
  logout: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  isAuthenticated: false,
  isLoading: true,

  setUser: (user) => {
    set({
      user,
      isAuthenticated: !!user,
      isLoading: false,
    });
  },

  updateProfile: (updates) => {
    const current = get().user;
    if (!current) return;
    set({
      user: { ...current, ...updates },
    });
  },

  syncWithFirebase: () => {
    try {
      const auth = getFirebaseAuth();
      if (auth && typeof auth.onAuthStateChanged === 'function') {
        auth.onAuthStateChanged((fbUser: any) => {
          if (fbUser) {
            const profile: UserProfile = {
              uid: fbUser.uid || fbUser.id,
              email: fbUser.email,
              displayName: fbUser.displayName,
              phoneNumber: fbUser.phoneNumber,
              photoURL: fbUser.photoURL,
            };
            set({ user: profile, isAuthenticated: true, isLoading: false });

            // Fetch extra profile data from firestore
            const db = getFirebaseFirestore();
            if (db) {
              db.collection('users').doc(profile.uid).get().then((doc: any) => {
                if (doc && doc.exists) {
                  const data = doc.data();
                  set((state) => ({
                    user: state.user ? { ...state.user, ...data } : profile,
                  }));
                }
              }).catch(() => {});
            }
          } else {
            set({ user: null, isAuthenticated: false, isLoading: false });
          }
        });
      } else {
        const current = getCurrentUser();
        if (current) {
          set({
            user: {
              uid: current.uid || current.id,
              email: current.email,
              displayName: current.displayName,
            },
            isAuthenticated: true,
            isLoading: false,
          });
        } else {
          set({ user: null, isAuthenticated: false, isLoading: false });
        }
      }
    } catch (_) {
      set({ isLoading: false });
    }
  },

  logout: async () => {
    try {
      const auth = getFirebaseAuth();
      if (auth && typeof auth.signOut === 'function') {
        await auth.signOut();
      }
    } catch (_) {}
    set({ user: null, isAuthenticated: false, isLoading: false });
  },
}));

// Sync auth state
useAuthStore.getState().syncWithFirebase();
