import { Vibration } from 'react-native';

export const Haptics = {
  light: () => {
    try {
      Vibration.vibrate(10);
    } catch (_) {}
  },
  medium: () => {
    try {
      Vibration.vibrate(20);
    } catch (_) {}
  },
  heavy: () => {
    try {
      Vibration.vibrate(40);
    } catch (_) {}
  },
  success: () => {
    try {
      Vibration.vibrate([0, 15, 50, 15]);
    } catch (_) {}
  },
  warning: () => {
    try {
      Vibration.vibrate([0, 30, 100, 30]);
    } catch (_) {}
  },
  error: () => {
    try {
      Vibration.vibrate([0, 50, 100, 50, 100, 50]);
    } catch (_) {}
  },
  selection: () => {
    try {
      Vibration.vibrate(8);
    } catch (_) {}
  }
};
