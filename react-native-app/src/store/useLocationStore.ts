import { create } from 'zustand';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { USER_SAVED_LOCATION_KEY, UserSavedLocation } from '../services/location';

interface LocationState {
  location: UserSavedLocation;
  isLoading: boolean;
  radiusKm: number;
  setLocation: (loc: Partial<UserSavedLocation>) => Promise<void>;
  setRadiusKm: (radius: number) => void;
  loadSavedLocation: () => Promise<void>;
  resetToAllIndia: () => Promise<void>;
}

const DEFAULT_LOCATION: UserSavedLocation = {
  city: 'All India',
  state: '',
  isGPS: false,
};

export const useLocationStore = create<LocationState>((set, get) => ({
  location: DEFAULT_LOCATION,
  isLoading: false,
  radiusKm: 50,

  loadSavedLocation: async () => {
    set({ isLoading: true });
    try {
      const raw = await AsyncStorage.getItem(USER_SAVED_LOCATION_KEY);
      if (raw) {
        const parsed = JSON.parse(raw);
        if (parsed && parsed.city) {
          set({ location: parsed });
        }
      }
    } catch (err) {
      console.warn('[LocationStore] Error loading saved location:', err);
    } finally {
      set({ isLoading: false });
    }
  },

  setLocation: async (loc: Partial<UserSavedLocation>) => {
    const updated: UserSavedLocation = {
      ...get().location,
      ...loc,
      city: loc.city || get().location.city || 'All India',
      timestamp: Date.now(),
    };
    set({ location: updated });
    try {
      await AsyncStorage.setItem(USER_SAVED_LOCATION_KEY, JSON.stringify(updated));
    } catch (err) {
      console.warn('[LocationStore] Error saving location:', err);
    }
  },

  setRadiusKm: (radiusKm: number) => {
    set({ radiusKm });
  },

  resetToAllIndia: async () => {
    set({ location: DEFAULT_LOCATION });
    try {
      await AsyncStorage.setItem(USER_SAVED_LOCATION_KEY, JSON.stringify(DEFAULT_LOCATION));
    } catch (_) {}
  },
}));

// Hydrate on import
useLocationStore.getState().loadSavedLocation();
