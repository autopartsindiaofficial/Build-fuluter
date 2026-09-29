import React, { useRef } from 'react';
import {
  View,
  StyleSheet,
  Animated,
  PanResponder,
  TouchableOpacity,
  Dimensions,
  StyleProp,
  ViewStyle,
} from 'react-native';
import MaterialCommunityIcons from 'react-native-vector-icons/MaterialCommunityIcons';

interface SwipeableCardProps {
  children: React.ReactNode;
  onDelete: () => void;
  deleteButtonWidth?: number;
  containerStyle?: StyleProp<ViewStyle>;
}

export const SwipeableCard: React.FC<SwipeableCardProps> = ({
  children,
  onDelete,
  deleteButtonWidth = 80,
  containerStyle,
}) => {
  const panX = useRef(new Animated.Value(0)).current;

  const panResponder = useRef(
    PanResponder.create({
      onMoveShouldSetPanResponder: (_, gestureState) => {
        return Math.abs(gestureState.dx) > 10 && Math.abs(gestureState.dy) < 15;
      },
      onPanResponderMove: (_, gestureState) => {
        if (gestureState.dx < 0) {
          // Swipe left limit
          const limitedDx = Math.max(gestureState.dx, -deleteButtonWidth - 20);
          panX.setValue(limitedDx);
        } else if (gestureState.dx > 0) {
          // Swipe right limit back to 0
          panX.setValue(Math.min(gestureState.dx, 0));
        }
      },
      onPanResponderRelease: (_, gestureState) => {
        if (gestureState.dx < -deleteButtonWidth / 2) {
          // Snap open
          Animated.spring(panX, {
            toValue: -deleteButtonWidth,
            friction: 7,
            useNativeDriver: true,
          }).start();
        } else {
          // Snap close
          Animated.spring(panX, {
            toValue: 0,
            friction: 7,
            useNativeDriver: true,
          }).start();
        }
      },
    })
  ).current;

  const handleDeletePress = () => {
    Animated.timing(panX, {
      toValue: -Dimensions.get('window').width,
      duration: 200,
      useNativeDriver: true,
    }).start(() => {
      onDelete();
    });
  };

  return (
    <View style={[styles.wrapper, containerStyle]}>
      {/* Background Delete Action */}
      <View style={[styles.deleteContainer, { width: deleteButtonWidth }]}>
        <TouchableOpacity style={styles.deleteButton} onPress={handleDeletePress} activeOpacity={0.8}>
          <MaterialCommunityIcons name="trash-can-outline" size={24} color="#FFFFFF" />
        </TouchableOpacity>
      </View>

      {/* ForeGround Card */}
      <Animated.View
        {...panResponder.panHandlers}
        style={[
          styles.foreground,
          {
            transform: [{ translateX: panX }],
          },
        ]}
      >
        {children}
      </Animated.View>
    </View>
  );
};

const styles = StyleSheet.create({
  wrapper: {
    position: 'relative',
    marginVertical: 4,
    overflow: 'hidden',
  },
  deleteContainer: {
    position: 'absolute',
    right: 0,
    top: 0,
    bottom: 0,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#EF4444',
    borderRadius: 14,
  },
  deleteButton: {
    width: '100%',
    height: '100%',
    justifyContent: 'center',
    alignItems: 'center',
  },
  foreground: {
    backgroundColor: 'transparent',
  },
});
