import React, { useEffect, useRef } from 'react';
import {
  Modal,
  View,
  Text,
  StyleSheet,
  Animated,
  Easing,
  TouchableOpacity,
} from 'react-native';
import MaterialCommunityIcons from 'react-native-vector-icons/MaterialCommunityIcons';

interface SuccessConfettiModalProps {
  visible: boolean;
  title?: string;
  message?: string;
  buttonText?: string;
  onClose: () => void;
}

const CONFETTI_COLORS = [
  '#3B82F6', '#10B981', '#F59E0B', '#EF4444',
  '#8B5CF6', '#EC4899', '#06B6D4', '#84CC16',
];

export const SuccessConfettiModal: React.FC<SuccessConfettiModalProps> = ({
  visible,
  title = 'Successfully Posted!',
  message = 'Your spare part ad is now live and visible to buyers across India.',
  buttonText = 'Awesome!',
  onClose,
}) => {
  const scaleAnim = useRef(new Animated.Value(0)).current;
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const confettiAnim = useRef(new Animated.Value(0)).current;

  // Generate 12 confetti particles
  const particles = useRef(
    Array.from({ length: 12 }).map((_, i) => {
      const angle = (i * 30 * Math.PI) / 180;
      const distance = 70 + (i % 3) * 20;
      return {
        x: Math.cos(angle) * distance,
        y: Math.sin(angle) * distance,
        color: CONFETTI_COLORS[i % CONFETTI_COLORS.length],
        size: 8 + (i % 3) * 4,
        rotate: `${(i * 45) % 360}deg`,
      };
    })
  ).current;

  useEffect(() => {
    if (visible) {
      scaleAnim.setValue(0);
      fadeAnim.setValue(0);
      confettiAnim.setValue(0);

      Animated.parallel([
        Animated.timing(fadeAnim, {
          toValue: 1,
          duration: 250,
          useNativeDriver: true,
        }),
        Animated.spring(scaleAnim, {
          toValue: 1,
          friction: 6,
          tension: 80,
          useNativeDriver: true,
        }),
        Animated.timing(confettiAnim, {
          toValue: 1,
          duration: 800,
          easing: Easing.out(Easing.back(1.5)),
          useNativeDriver: true,
        }),
      ]).start();
    }
  }, [visible]);

  if (!visible) return null;

  return (
    <Modal transparent visible={visible} animationType="fade" onRequestClose={onClose}>
      <View style={styles.overlay}>
        <Animated.View style={[styles.modalCard, { opacity: fadeAnim, transform: [{ scale: scaleAnim }] }]}>
          {/* Confetti Particles */}
          <View style={styles.confettiContainer}>
            {particles.map((p, idx) => {
              const translateX = confettiAnim.interpolate({
                inputRange: [0, 1],
                outputRange: [0, p.x],
              });
              const translateY = confettiAnim.interpolate({
                inputRange: [0, 1],
                outputRange: [0, p.y],
              });
              const opacity = confettiAnim.interpolate({
                inputRange: [0, 0.7, 1],
                outputRange: [1, 1, 0],
              });
              const scale = confettiAnim.interpolate({
                inputRange: [0, 0.5, 1],
                outputRange: [0.2, 1.2, 0.8],
              });

              return (
                <Animated.View
                  key={`particle-${idx}`}
                  style={[
                    styles.particle,
                    {
                      width: p.size,
                      height: p.size,
                      backgroundColor: p.color,
                      transform: [
                        { translateX },
                        { translateY },
                        { scale },
                        { rotate: p.rotate },
                      ],
                      opacity,
                    },
                  ]}
                />
              );
            })}
          </View>

          {/* Success Checkmark Circle */}
          <View style={styles.iconCircle}>
            <MaterialCommunityIcons name="check-bold" size={42} color="#FFFFFF" />
          </View>

          <Text style={styles.title}>{title}</Text>
          <Text style={styles.message}>{message}</Text>

          <TouchableOpacity activeOpacity={0.85} onPress={onClose} style={styles.button}>
            <Text style={styles.buttonText}>{buttonText}</Text>
          </TouchableOpacity>
        </Animated.View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(5, 15, 35, 0.75)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  modalCard: {
    width: '100%',
    maxWidth: 340,
    backgroundColor: '#0F172A',
    borderRadius: 24,
    padding: 24,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#1E293B',
    elevation: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.35,
    shadowRadius: 12,
  },
  confettiContainer: {
    position: 'absolute',
    top: 60,
    alignItems: 'center',
    justifyContent: 'center',
  },
  particle: {
    position: 'absolute',
    borderRadius: 3,
  },
  iconCircle: {
    width: 76,
    height: 76,
    borderRadius: 38,
    backgroundColor: '#10B981',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
    elevation: 6,
    shadowColor: '#10B981',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.4,
    shadowRadius: 8,
  },
  title: {
    color: '#F8FAFC',
    fontSize: 20,
    fontWeight: '800',
    textAlign: 'center',
    marginBottom: 8,
  },
  message: {
    color: '#94A3B8',
    fontSize: 13.5,
    fontWeight: '500',
    textAlign: 'center',
    lineHeight: 20,
    marginBottom: 20,
  },
  button: {
    width: '100%',
    backgroundColor: '#0066FF',
    paddingVertical: 14,
    borderRadius: 14,
    alignItems: 'center',
  },
  buttonText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '700',
  },
});
