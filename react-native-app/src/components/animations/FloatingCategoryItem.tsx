import React, { useEffect, useRef } from 'react';
import {
  TouchableOpacity,
  StyleSheet,
  Animated,
  ViewStyle,
  StyleProp,
} from 'react-native';

interface FloatingCategoryItemProps {
  isSelected?: boolean;
  onPress: () => void;
  children: React.ReactNode;
  style?: StyleProp<ViewStyle>;
  activeScale?: number;
}

export const FloatingCategoryItem: React.FC<FloatingCategoryItemProps> = ({
  isSelected = false,
  onPress,
  children,
  style,
  activeScale = 1.05,
}) => {
  const anim = useRef(new Animated.Value(isSelected ? 1 : 0)).current;

  useEffect(() => {
    Animated.spring(anim, {
      toValue: isSelected ? 1 : 0,
      friction: 7,
      tension: 60,
      useNativeDriver: true,
    }).start();
  }, [isSelected]);

  const translateY = anim.interpolate({
    inputRange: [0, 1],
    outputRange: [0, -4],
  });

  const scale = anim.interpolate({
    inputRange: [0, 1],
    outputRange: [1, activeScale],
  });

  const handlePressIn = () => {
    Animated.spring(anim, {
      toValue: 0.8,
      friction: 8,
      tension: 100,
      useNativeDriver: true,
    }).start();
  };

  const handlePressOut = () => {
    Animated.spring(anim, {
      toValue: isSelected ? 1 : 0,
      friction: 6,
      tension: 70,
      useNativeDriver: true,
    }).start();
  };

  return (
    <TouchableOpacity
      activeOpacity={0.9}
      onPress={onPress}
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
    >
      <Animated.View
        style={[
          style,
          {
            transform: [{ translateY }, { scale }],
          },
        ]}
      >
        {children}
      </Animated.View>
    </TouchableOpacity>
  );
};
