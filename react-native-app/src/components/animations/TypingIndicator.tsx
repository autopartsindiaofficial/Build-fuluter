import React, { useEffect, useRef } from 'react';
import { View, StyleSheet, Animated, Easing } from 'react-native';

interface TypingIndicatorProps {
  dotSize?: number;
  dotColor?: number | string;
  dotMargin?: number;
}

export const TypingIndicator: React.FC<TypingIndicatorProps> = ({
  dotSize = 7,
  dotColor = '#94A3B8',
  dotMargin = 3,
}) => {
  const dot1 = useRef(new Animated.Value(0)).current;
  const dot2 = useRef(new Animated.Value(0)).current;
  const dot3 = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    const createBouncingAnim = (anim: Animated.Value, delay: number) => {
      return Animated.loop(
        Animated.sequence([
          Animated.delay(delay),
          Animated.timing(anim, {
            toValue: -6,
            duration: 300,
            easing: Easing.ease,
            useNativeDriver: true,
          }),
          Animated.timing(anim, {
            toValue: 0,
            duration: 300,
            easing: Easing.ease,
            useNativeDriver: true,
          }),
          Animated.delay(400),
        ])
      );
    };

    const anim1 = createBouncingAnim(dot1, 0);
    const anim2 = createBouncingAnim(dot2, 150);
    const anim3 = createBouncingAnim(dot3, 300);

    anim1.start();
    anim2.start();
    anim3.start();

    return () => {
      anim1.stop();
      anim2.stop();
      anim3.stop();
    };
  }, []);

  return (
    <View style={styles.bubble}>
      <Animated.View
        style={[
          styles.dot,
          {
            width: dotSize,
            height: dotSize,
            borderRadius: dotSize / 2,
            backgroundColor: dotColor as any,
            marginHorizontal: dotMargin,
            transform: [{ translateY: dot1 }],
          },
        ]}
      />
      <Animated.View
        style={[
          styles.dot,
          {
            width: dotSize,
            height: dotSize,
            borderRadius: dotSize / 2,
            backgroundColor: dotColor as any,
            marginHorizontal: dotMargin,
            transform: [{ translateY: dot2 }],
          },
        ]}
      />
      <Animated.View
        style={[
          styles.dot,
          {
            width: dotSize,
            height: dotSize,
            borderRadius: dotSize / 2,
            backgroundColor: dotColor as any,
            marginHorizontal: dotMargin,
            transform: [{ translateY: dot3 }],
          },
        ]}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  bubble: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#1E293B',
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 16,
    borderBottomLeftRadius: 4,
    alignSelf: 'flex-start',
  },
  dot: {
    opacity: 0.85,
  },
});
