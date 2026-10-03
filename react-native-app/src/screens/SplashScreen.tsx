import React, { useEffect, useRef, useState } from 'react';
import { 
  Animated, 
  View, 
  StatusBar, 
  StyleSheet, 
  SafeAreaView, 
  Image,
  useWindowDimensions,
  Alert,
  Linking
} from 'react-native';
import { Text } from 'react-native-paper';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { getCurrentUser, getFirebaseFirestore } from '../services/firebase';
import { AppLogo } from '../components/AppLogo';

const CURRENT_APP_VERSION = '1.0.0';

function isVersionLower(current: string, required: string) {
  const cParts = current.split('.').map(Number);
  const rParts = required.split('.').map(Number);
  for (let i = 0; i < Math.max(cParts.length, rParts.length); i++) {
    const c = cParts[i] || 0;
    const r = rParts[i] || 0;
    if (c < r) return true;
    if (c > r) return false;
  }
  return false;
}

export default function SplashScreen({ navigation }: any) {
  const { width: screenWidth } = useWindowDimensions();
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const scaleAnim = useRef(new Animated.Value(0.92)).current;
  const footerFade = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    let isMounted = true;
    let fallbackTimer: NodeJS.Timeout | null = null;
    let initialTimer: NodeJS.Timeout | null = null;

    // Smooth entry animation
    Animated.parallel([
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 500,
        useNativeDriver: true,
      }),
      Animated.spring(scaleAnim, {
        toValue: 1,
        friction: 8,
        tension: 45,
        useNativeDriver: true,
      }),
      Animated.timing(footerFade, {
        toValue: 1,
        duration: 700,
        delay: 200,
        useNativeDriver: true,
      }),
    ]).start();

    const proceedToApp = async () => {
      if (!isMounted) return;
      try {
        let user = getCurrentUser();
        if (!user || (!user.uid && !user.id)) {
          const rawStored = await AsyncStorage.getItem('@autoparts_current_user');
          if (rawStored) {
            try {
              user = JSON.parse(rawStored);
            } catch (_) {}
          }
        }

        const targetScreen = (user && (user.uid || user.id)) ? 'MainTabs' : 'Auth';

        if (!isMounted) return;
        if (navigation?.reset) {
          navigation.reset({ index: 0, routes: [{ name: targetScreen }] });
        } else if (navigation?.replace) {
          navigation.replace(targetScreen);
        } else if (navigation?.navigate) {
          navigation.navigate(targetScreen);
        }
      } catch (e) {
        if (isMounted) {
          try { navigation?.navigate('Auth'); } catch (_) {}
        }
      }
    };

    const checkAppUpdate = async () => {
      let hasProceeded = false;
      const safeProceed = () => {
        if (!hasProceeded && isMounted) {
          hasProceeded = true;
          proceedToApp();
        }
      };

      // Fallback timer in case network / Firestore check hangs indefinitely
      fallbackTimer = setTimeout(() => {
        safeProceed();
      }, 3500);

      try {
        const db = getFirebaseFirestore();
        if (!db) {
          if (fallbackTimer) clearTimeout(fallbackTimer);
          safeProceed();
          return;
        }

        const snap = await Promise.race([
          db.collection('app_version').doc('config').get(),
          new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout')), 3000))
        ]) as any;

        if (fallbackTimer) clearTimeout(fallbackTimer);

        if (snap && snap.exists && isMounted) {
          const config = snap.data();
          const minVersion = config?.minimumSupportedVersion || '1.0.0';
          const forceUpdate = config?.forceUpdate === true;
          const apkUrl = config?.apkDownloadUrl || config?.playStoreUrl || '';
          
          if (isVersionLower(CURRENT_APP_VERSION, minVersion)) {
            // Needs Update
            const promptUpdate = () => {
              if (!isMounted) return;
              Alert.alert(
                'Update Required',
                'A new version of the app is available. Please update to continue using the app.',
                [
                  {
                    text: 'Update Now',
                    onPress: () => {
                      if (apkUrl) Linking.openURL(apkUrl).catch(() => {});
                      if (forceUpdate) {
                        setTimeout(promptUpdate, 1000);
                      } else {
                        safeProceed();
                      }
                    }
                  },
                  ...(forceUpdate ? [] : [{ text: 'Later', onPress: safeProceed, style: 'cancel' as any }])
                ],
                { cancelable: !forceUpdate }
              );
            };
            promptUpdate();
            return;
          }
        }
      } catch (err) {
        console.warn('Update check failed or timed out:', err);
      }
      safeProceed();
    };

    initialTimer = setTimeout(() => {
      if (isMounted) {
        checkAppUpdate();
      }
    }, 1400);

    return () => {
      isMounted = false;
      if (initialTimer) clearTimeout(initialTimer);
      if (fallbackTimer) clearTimeout(fallbackTimer);
    };
  }, [navigation]);

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#25242E" translucent={false} />

      <SafeAreaView style={styles.safeArea}>
        <Animated.View 
          style={[
            styles.imageWrapper, 
            { opacity: fadeAnim, transform: [{ scale: scaleAnim }] }
          ]}
        >
          <Image 
            source={require('../assets/splash_reference.png')}
            style={styles.splashImage}
            resizeMode="contain"
          />
        </Animated.View>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#25242E', // Exact dark slate background from reference image
  },
  safeArea: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  imageWrapper: {
    width: '100%',
    height: '100%',
    alignItems: 'center',
    justifyContent: 'center',
  },
  splashImage: {
    width: '100%',
    height: '100%',
  },
});

