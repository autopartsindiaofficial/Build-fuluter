import React, { useRef } from 'react';
import {
  Pressable,
  Animated,
  ViewStyle,
  StyleProp,
  GestureResponderEvent,
} from 'react-native';
// @ts-ignore
import ReactNativeHapticFeedback from 'react-native-haptic-feedback';

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

const hapticOptions = {
  enableVibrateFallback: true,
  ignoreAndroidSystemSettings: false,
};

interface ScalePressableProps {
  children: React.ReactNode;
  style?: StyleProp<ViewStyle>;
  onPress?: (event: GestureResponderEvent) => void;
  onLongPress?: (event: GestureResponderEvent) => void;
  scaleTo?: number;
  disabled?: boolean;
  activeOpacity?: number;
  rippleColor?: string;
  enableHaptic?: boolean;
  hitSlop?: { top?: number; bottom?: number; left?: number; right?: number };
}

/**
 * ScalePressable with tactile Animated Spring Scale, Haptic feedback & clean styling
 */
export function ScalePressable({
  children,
  style,
  onPress,
  onLongPress,
  scaleTo = 0.96,
  disabled = false,
  activeOpacity = 0.92,
  rippleColor = 'transparent',
  enableHaptic = true,
  hitSlop,
}: ScalePressableProps) {
  const scaleAnim = useRef(new Animated.Value(1)).current;
  const opacityAnim = useRef(new Animated.Value(1)).current;

  const handlePressIn = (e: GestureResponderEvent) => {
    if (enableHaptic) {
      try {
        ReactNativeHapticFeedback.trigger('impactLight', hapticOptions);
      } catch (err) {
        // fallback if haptics unavailable
      }
    }
    Animated.parallel([
      Animated.spring(scaleAnim, {
        toValue: scaleTo,
        friction: 8,
        tension: 140,
        useNativeDriver: true,
      }),
      Animated.timing(opacityAnim, {
        toValue: activeOpacity,
        duration: 80,
        useNativeDriver: true,
      }),
    ]).start();
  };

  const handlePressOut = (e: GestureResponderEvent) => {
    Animated.parallel([
      Animated.spring(scaleAnim, {
        toValue: 1,
        friction: 8,
        tension: 140,
        useNativeDriver: true,
      }),
      Animated.timing(opacityAnim, {
        toValue: 1,
        duration: 120,
        useNativeDriver: true,
      }),
    ]).start();
  };

  return (
    <AnimatedPressable
      onPress={onPress}
      onLongPress={onLongPress}
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      disabled={disabled}
      hitSlop={hitSlop}
      android_ripple={rippleColor !== 'transparent' ? { color: rippleColor, borderless: false } : undefined}
      style={[
        style,
        {
          transform: [{ scale: scaleAnim }],
          opacity: opacityAnim,
        },
      ]}
    >
      {children}
    </AnimatedPressable>
  );
}
