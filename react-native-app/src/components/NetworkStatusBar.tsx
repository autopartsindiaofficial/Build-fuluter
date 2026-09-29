import React, { useEffect, useState, useRef } from 'react';
import { View, Text, StyleSheet, Animated, Platform } from 'react-native';
import { Icon } from 'react-native-paper';
import { networkManager } from '../services/networkManager';

export const NetworkStatusBar: React.FC = () => {
  const [isOffline, setIsOffline] = useState(false);
  const [showRestored, setShowRestored] = useState(false);
  const slideAnim = useRef(new Animated.Value(-50)).current;

  useEffect(() => {
    let timeout: any = null;

    const unsubscribe = networkManager.subscribe((isConnected) => {
      if (!isConnected) {
        setIsOffline(true);
        setShowRestored(false);
        Animated.spring(slideAnim, {
          toValue: 0,
          useNativeDriver: true,
          bounciness: 4,
        }).start();
      } else {
        if (isOffline) {
          // Was offline and now restored
          setIsOffline(false);
          setShowRestored(true);
          timeout = setTimeout(() => {
            Animated.timing(slideAnim, {
              toValue: -50,
              duration: 300,
              useNativeDriver: true,
            }).start(() => {
              setShowRestored(false);
            });
          }, 2500);
        }
      }
    });

    return () => {
      unsubscribe();
      if (timeout) clearTimeout(timeout);
    };
  }, [isOffline]);

  if (!isOffline && !showRestored) return null;

  return (
    <Animated.View
      style={[
        styles.container,
        isOffline ? styles.offlineBg : styles.onlineBg,
        {
          transform: [{ translateY: slideAnim }],
        },
      ]}
    >
      <Icon
        source={isOffline ? 'wifi-off' : 'wifi-check'}
        size={15}
        color="#FFFFFF"
      />
      <Text style={styles.text}>
        {isOffline
          ? 'No Internet Connection • Reconnecting...'
          : 'Back Online • Connected to Server'}
      </Text>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    top: Platform.OS === 'ios' ? 44 : 0,
    left: 0,
    right: 0,
    zIndex: 99999,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 7,
    paddingHorizontal: 12,
    gap: 6,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 3,
    elevation: 6,
  },
  offlineBg: {
    backgroundColor: '#DC2626',
  },
  onlineBg: {
    backgroundColor: '#16A34A',
  },
  text: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '700',
  },
});
