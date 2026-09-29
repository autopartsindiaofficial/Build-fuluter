import React, { useEffect, useRef } from 'react';
import { View, StyleSheet, TouchableOpacity, Animated, PanResponder } from 'react-native';
import { Text, IconButton, Surface } from 'react-native-paper';

export interface InAppNotificationData {
  id: string;
  senderName: string;
  text: string;
  partTitle?: string;
  partPrice?: number;
  chatId?: string;
}

interface InAppNotificationProps {
  notification: InAppNotificationData | null;
  onClose: () => void;
  onPress: (item: InAppNotificationData) => void;
}

export const InAppNotification: React.FC<InAppNotificationProps> = ({
  notification,
  onClose,
  onPress,
}) => {
  const translateY = useRef(new Animated.Value(-120)).current;
  const translateX = useRef(new Animated.Value(0)).current;
  const opacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (notification) {
      translateY.setValue(-120);
      translateX.setValue(0);
      opacity.setValue(0);

      Animated.parallel([
        Animated.spring(translateY, {
          toValue: 0,
          useNativeDriver: true,
          damping: 15,
          stiffness: 130,
        }),
        Animated.timing(opacity, {
          toValue: 1,
          duration: 220,
          useNativeDriver: true,
        }),
      ]).start();

      const timer = setTimeout(() => {
        handleDismissUp();
      }, 5500);

      return () => clearTimeout(timer);
    } else {
      translateY.setValue(-120);
      opacity.setValue(0);
    }
  }, [notification]);

  const handleDismissUp = () => {
    Animated.parallel([
      Animated.timing(translateY, {
        toValue: -150,
        duration: 200,
        useNativeDriver: true,
      }),
      Animated.timing(opacity, {
        toValue: 0,
        duration: 180,
        useNativeDriver: true,
      }),
    ]).start(() => {
      onClose();
    });
  };

  const handleDismissHorizontal = (direction: 'left' | 'right') => {
    Animated.parallel([
      Animated.timing(translateX, {
        toValue: direction === 'left' ? -400 : 400,
        duration: 200,
        useNativeDriver: true,
      }),
      Animated.timing(opacity, {
        toValue: 0,
        duration: 180,
        useNativeDriver: true,
      }),
    ]).start(() => {
      onClose();
    });
  };

  const panResponder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => false,
      onMoveShouldSetPanResponder: (_, gestureState) => {
        return Math.abs(gestureState.dy) > 6 || Math.abs(gestureState.dx) > 10;
      },
      onPanResponderMove: (_, gestureState) => {
        if (gestureState.dy < 0) {
          translateY.setValue(gestureState.dy);
        } else {
          translateY.setValue(gestureState.dy * 0.25);
        }
        translateX.setValue(gestureState.dx);
      },
      onPanResponderRelease: (_, gestureState) => {
        if (gestureState.dy < -25 || gestureState.vy < -0.3) {
          handleDismissUp();
        } else if (gestureState.dx < -50 || gestureState.vx < -0.3) {
          handleDismissHorizontal('left');
        } else if (gestureState.dx > 50 || gestureState.vx > 0.3) {
          handleDismissHorizontal('right');
        } else {
          Animated.parallel([
            Animated.spring(translateY, {
              toValue: 0,
              useNativeDriver: true,
              friction: 7,
            }),
            Animated.spring(translateX, {
              toValue: 0,
              useNativeDriver: true,
              friction: 7,
            }),
          ]).start();
        }
      },
    })
  ).current;

  if (!notification) return null;

  return (
    <Animated.View
      {...panResponder.panHandlers}
      style={[
        styles.wrapper,
        {
          opacity,
          transform: [
            { translateY },
            { translateX },
          ],
        },
      ]}
    >
      <TouchableOpacity
        activeOpacity={0.9}
        onPress={() => {
          onPress(notification);
          handleDismissUp();
        }}
      >
        <Surface style={styles.card} elevation={5}>
          {/* Bell Icon Circle */}
          <View style={styles.iconCircle}>
            <IconButton icon="bell-ring" size={20} iconColor="#6366F1" style={{ margin: 0 }} />
          </View>

          {/* Text Col */}
          <View style={styles.textCol}>
            <View style={styles.topRow}>
              <Text style={styles.tag}>NEW INQUIRY</Text>
              <Text style={styles.timeTag}>Just now</Text>
            </View>

            <Text style={styles.sender} numberOfLines={1}>
              {notification.senderName || 'Buyer/Seller'}
            </Text>

            <Text style={styles.message} numberOfLines={1}>
              "{notification.text}"
            </Text>

            {notification.partTitle && (
              <View style={styles.partTagRow}>
                <Text style={styles.partTagText} numberOfLines={1}>
                  Regarding: {notification.partTitle}{' '}
                  {notification.partPrice ? `(₹${notification.partPrice})` : ''}
                </Text>
              </View>
            )}
          </View>

          {/* Close button */}
          <TouchableOpacity style={styles.closeBtn} onPress={handleDismissUp}>
            <IconButton icon="close" size={16} iconColor="#94A3B8" style={{ margin: 0 }} />
          </TouchableOpacity>
        </Surface>
      </TouchableOpacity>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  wrapper: {
    position: 'absolute',
    top: 45,
    left: 16,
    right: 16,
    zIndex: 9999,
  },
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 12,
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    gap: 10,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.12,
    shadowRadius: 10,
    elevation: 8,
  },
  iconCircle: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#EFF6FF',
    borderWidth: 1,
    borderColor: '#DBEAFE',
    justifyContent: 'center',
    alignItems: 'center',
  },
  textCol: {
    flex: 1,
  },
  topRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  tag: {
    fontSize: 11,
    fontWeight: '800',
    color: '#0066FF',
    letterSpacing: 0.5,
  },
  timeTag: {
    fontSize: 11,
    fontWeight: '600',
    color: '#64748B',
  },
  sender: {
    fontSize: 14.5,
    fontWeight: '800',
    color: '#0F172A',
    marginTop: 2,
  },
  message: {
    fontSize: 13,
    color: '#1E293B',
    marginTop: 2,
    fontWeight: '600',
  },
  partTagRow: {
    backgroundColor: '#E0F2FE',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
    marginTop: 5,
    alignSelf: 'flex-start',
  },
  partTagText: {
    fontSize: 11,
    color: '#0369A1',
    fontWeight: '700',
  },
  closeBtn: {
    padding: 2,
  },
});
