declare module 'react-native-haptic-feedback' {
  export interface HapticOptions {
    enableVibrateFallback?: boolean;
    ignoreAndroidSystemSettings?: boolean;
  }
  export default class ReactNativeHapticFeedback {
    static trigger(method: string, options?: HapticOptions): void;
  }
}
