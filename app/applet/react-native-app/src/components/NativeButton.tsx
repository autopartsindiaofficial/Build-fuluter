import React from 'react';
import {
  Pressable,
  PressableProps,
  StyleProp,
  ViewStyle,
  Animated,
  Platform,
  View,
} from 'react-native';
import { Haptics } from '../utils/haptics';

interface NativeButtonProps extends PressableProps {
  children: React.ReactNode;
  style?: StyleProp<ViewStyle>;
  rippleColor?: string;
  useHaptic?: boolean;
  hapticStyle?: 'light' | 'medium' | 'heavy' | 'selection' | 'success';
}

/**
 * NativeButton provides authentic platform-specific touch feedback.
 * - Android: Native ripple effect
 * - iOS: Scale down animation with opacity
 */
export function NativeButton({
  children,
  style,
  rippleColor = 'rgba(0, 0, 0, 0.1)',
  useHaptic = true,
  hapticStyle = 'light',
  onPress,
  ...props
}: NativeButtonProps) {
  const scaleAnim = React.useRef(new Animated.Value(1)).current;

  const handlePressIn = (e: any) => {
    if (Platform.OS === 'ios') {
      Animated.timing(scaleAnim, {
        toValue: 0.96,
        duration: 100,
        useNativeDriver: true,
      }).start();
    }
    props.onPressIn?.(e);
  };

  const handlePressOut = (e: any) => {
    if (Platform.OS === 'ios') {
      Animated.timing(scaleAnim, {
        toValue: 1,
        duration: 150,
        useNativeDriver: true,
      }).start();
    }
    props.onPressOut?.(e);
  };

  const handlePress = (e: any) => {
    if (useHaptic) {
      if (hapticStyle === 'light') Haptics.light();
      if (hapticStyle === 'medium') Haptics.medium();
      if (hapticStyle === 'heavy') Haptics.heavy();
      if (hapticStyle === 'selection') Haptics.selection();
      if (hapticStyle === 'success') Haptics.success();
    }
    onPress?.(e);
  };

  return (
    <Animated.View style={[{ transform: [{ scale: scaleAnim }], overflow: 'hidden' }, style]}>
      <Pressable
        {...props}
        onPressIn={handlePressIn}
        onPressOut={handlePressOut}
        onPress={handlePress}
        android_ripple={{ color: rippleColor, borderless: false }}
        style={({ pressed }) => [
          { width: '100%', height: '100%', flex: 1 },
          Platform.OS === 'ios' && pressed ? { opacity: 0.8 } : null,
        ]}
      >
        <View style={{ flex: 1, width: '100%', height: '100%', alignItems: 'center', justifyContent: 'center' }}>
          {children}
        </View>
      </Pressable>
    </Animated.View>
  );
}
