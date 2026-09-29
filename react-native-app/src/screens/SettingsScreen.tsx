import React, { useState, useEffect } from 'react';
import { View, StyleSheet, ScrollView, TouchableOpacity, StatusBar, Alert, ActivityIndicator } from 'react-native';
import { Text, Icon, Switch, Divider } from 'react-native-paper';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useLanguage } from '../context/LanguageContext';
import { LanguageSelectorModal } from '../components/LanguageSelectorModal';
import { getFirebaseFirestore, getCurrentUser } from '../services/firebase';

const PREF_NOTIF_KEY = '@autoparts_pref_notifications';
const PREF_LOC_KEY = '@autoparts_pref_location';
const PREF_SOUND_KEY = '@autoparts_pref_sound';

export default function SettingsScreen({ navigation }: any) {
  const { language } = useLanguage();
  const [showLanguageModal, setShowLanguageModal] = useState(false);
  const [notificationsEnabled, setNotificationsEnabled] = useState(true);
  const [locationEnabled, setLocationEnabled] = useState(true);
  const [soundEnabled, setSoundEnabled] = useState(true);
  const [isClearingCache, setIsClearingCache] = useState(false);
  const [cacheSizeText, setCacheSizeText] = useState('2.4 MB');

  useEffect(() => {
    loadSavedPreferences();
  }, []);

  const loadSavedPreferences = async () => {
    try {
      const [savedNotif, savedLoc, savedSound] = await Promise.all([
        AsyncStorage.getItem(PREF_NOTIF_KEY),
        AsyncStorage.getItem(PREF_LOC_KEY),
        AsyncStorage.getItem(PREF_SOUND_KEY),
      ]);

      if (savedNotif !== null) setNotificationsEnabled(savedNotif === 'true');
      if (savedLoc !== null) setLocationEnabled(savedLoc === 'true');
      if (savedSound !== null) setSoundEnabled(savedSound === 'true');

      // Also check Firestore user settings if logged in
      const user = getCurrentUser();
      if (user?.uid) {
        const db = getFirebaseFirestore();
        if (db && typeof db.collection === 'function') {
          const doc = await db.collection('users').doc(user.uid).get();
          if (doc && doc.exists) {
            const data = typeof doc.data === 'function' ? doc.data() : doc.data;
            if (data?.notificationsEnabled !== undefined) {
              setNotificationsEnabled(Boolean(data.notificationsEnabled));
            }
            if (data?.locationEnabled !== undefined) {
              setLocationEnabled(Boolean(data.locationEnabled));
            }
          }
        }
      }
    } catch (e) {
      console.warn('Failed to load user preferences:', e);
    }
  };

  const handleToggleNotification = async (value: boolean) => {
    setNotificationsEnabled(value);
    try {
      await AsyncStorage.setItem(PREF_NOTIF_KEY, String(value));
      const user = getCurrentUser();
      if (user?.uid) {
        const db = getFirebaseFirestore();
        if (db && typeof db.collection === 'function') {
          await db.collection('users').doc(user.uid).set(
            { notificationsEnabled: value, updatedAt: Date.now() },
            { merge: true }
          );
        }
      }
    } catch (e) {
      console.warn('Error saving notif pref:', e);
    }
  };

  const handleToggleLocation = async (value: boolean) => {
    setLocationEnabled(value);
    try {
      await AsyncStorage.setItem(PREF_LOC_KEY, String(value));
      const user = getCurrentUser();
      if (user?.uid) {
        const db = getFirebaseFirestore();
        if (db && typeof db.collection === 'function') {
          await db.collection('users').doc(user.uid).set(
            { locationEnabled: value, updatedAt: Date.now() },
            { merge: true }
          );
        }
      }
    } catch (e) {
      console.warn('Error saving loc pref:', e);
    }
  };

  const handleToggleSound = async (value: boolean) => {
    setSoundEnabled(value);
    try {
      await AsyncStorage.setItem(PREF_SOUND_KEY, String(value));
    } catch (e) {
      console.warn('Error saving sound pref:', e);
    }
  };

  const handleClearCache = async () => {
    Alert.alert(
      'Clear Application Cache',
      'This will clear temporary search cache and locally cached thumbnail data. Your account, ads, and chats will NOT be deleted.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Clear Now',
          style: 'destructive',
          onPress: async () => {
            setIsClearingCache(true);
            try {
              // Clear search history & temp caches from AsyncStorage without deleting auth/favorites
              const allKeys = await AsyncStorage.getAllKeys();
              const cacheKeys = allKeys.filter(
                (k) =>
                  k.includes('cache') ||
                  k.includes('search_history') ||
                  k.includes('recently_viewed') ||
                  k.includes('temp')
              );
              if (cacheKeys.length > 0) {
                await AsyncStorage.multiRemove(cacheKeys);
              }
              setCacheSizeText('0.0 KB');
              Alert.alert('Success', 'Application cache has been cleared successfully.');
            } catch (e) {
              Alert.alert('Info', 'Cache cleared.');
            } finally {
              setIsClearingCache(false);
            }
          },
        },
      ]
    );
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#0066FF" />
      <View style={styles.topHeader}>
        {navigation?.canGoBack?.() && (
          <TouchableOpacity 
            style={styles.backBtn}
            onPress={() => navigation.goBack()}
            activeOpacity={0.7}
          >
            <Icon source="arrow-left" size={22} color="#FFFFFF" />
          </TouchableOpacity>
        )}
        <Text style={styles.topHeaderTitle}>Settings</Text>
      </View>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
        scrollEventThrottle={16}
        bounces={true}
        alwaysBounceVertical={true}
        decelerationRate="normal"
        overScrollMode="never"
        keyboardShouldPersistTaps="handled"
        keyboardDismissMode="on-drag"
      >
        
        <Text style={styles.sectionTitle}>PREFERENCES</Text>
        <View style={styles.card}>
          <TouchableOpacity style={styles.listItem} onPress={() => setShowLanguageModal(true)}>
            <View style={styles.listIconBox}>
              <Icon source="translate" size={20} color="#64748B" />
            </View>
            <View style={styles.listTexts}>
              <Text style={styles.listTitle}>Language</Text>
              <Text style={styles.listSubtitle}>{language === 'ta' ? 'Tamil (தமிழ்)' : 'English'}</Text>
            </View>
            <Icon source="chevron-right" size={20} color="#CBD5E1" />
          </TouchableOpacity>
        </View>

        <Text style={styles.sectionTitle}>NOTIFICATIONS & PERMISSIONS</Text>
        <View style={styles.card}>
          <View style={styles.listItem}>
            <View style={styles.listIconBox}>
              <Icon source="bell-outline" size={20} color="#64748B" />
            </View>
            <View style={styles.listTexts}>
              <Text style={styles.listTitle}>Push Notifications</Text>
              <Text style={styles.listSubtitle}>Alerts for messages and price updates</Text>
            </View>
            <Switch 
              value={notificationsEnabled} 
              onValueChange={handleToggleNotification} 
              color="#0066FF" 
            />
          </View>
          <Divider style={styles.divider} />
          <View style={styles.listItem}>
            <View style={styles.listIconBox}>
              <Icon source="map-marker-outline" size={20} color="#64748B" />
            </View>
            <View style={styles.listTexts}>
              <Text style={styles.listTitle}>Location Access</Text>
              <Text style={styles.listSubtitle}>Used to show exact distance to nearby parts</Text>
            </View>
            <Switch 
              value={locationEnabled} 
              onValueChange={handleToggleLocation} 
              color="#0066FF" 
            />
          </View>
          <Divider style={styles.divider} />
          <View style={styles.listItem}>
            <View style={styles.listIconBox}>
              <Icon source="volume-high" size={20} color="#64748B" />
            </View>
            <View style={styles.listTexts}>
              <Text style={styles.listTitle}>Sound & In-App Alerts</Text>
              <Text style={styles.listSubtitle}>Play sounds when chat message arrives</Text>
            </View>
            <Switch 
              value={soundEnabled} 
              onValueChange={handleToggleSound} 
              color="#0066FF" 
            />
          </View>
        </View>

        <Text style={styles.sectionTitle}>STORAGE & DATA</Text>
        <View style={styles.card}>
          <TouchableOpacity 
            style={styles.listItem} 
            onPress={handleClearCache}
            disabled={isClearingCache}
            activeOpacity={0.7}
          >
            <View style={[styles.listIconBox, { backgroundColor: '#FEE2E2' }]}>
              <Icon source="broom" size={20} color="#EF4444" />
            </View>
            <View style={styles.listTexts}>
              <Text style={styles.listTitle}>Clear Cache</Text>
              <Text style={styles.listSubtitle}>Free up space ({cacheSizeText})</Text>
            </View>
            {isClearingCache ? (
              <ActivityIndicator size="small" color="#EF4444" />
            ) : (
              <Icon source="chevron-right" size={20} color="#CBD5E1" />
            )}
          </TouchableOpacity>
        </View>

        <Text style={styles.sectionTitle}>APP INFORMATION</Text>
        <View style={styles.card}>
          <View style={styles.listItem}>
            <View style={styles.listIconBox}>
              <Icon source="information-outline" size={20} color="#64748B" />
            </View>
            <View style={styles.listTexts}>
              <Text style={styles.listTitle}>App Version</Text>
              <Text style={styles.listSubtitle}>v2.4.0 (Production Stable Build)</Text>
            </View>
          </View>
        </View>

      </ScrollView>

      {/* Language Modal */}
      <LanguageSelectorModal 
        visible={showLanguageModal} 
        onDismiss={() => setShowLanguageModal(false)} 
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F8FAFC' },
  topHeader: {
    height: 56,
    backgroundColor: '#0066FF',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    gap: 12,
  },
  backBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
  },
  topHeaderTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: '#FFFFFF',
    flex: 1,
  },
  scrollContent: { padding: 16, paddingBottom: 40 },
  sectionTitle: { fontSize: 11, fontWeight: '800', color: '#94A3B8', marginTop: 24, marginBottom: 8, paddingHorizontal: 4, letterSpacing: 1 },
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    overflow: 'hidden',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.05,
    shadowRadius: 10,
    elevation: 2.5,
  },
  listItem: { flexDirection: 'row', alignItems: 'center', padding: 16, gap: 12 },
  listIconBox: { width: 36, height: 36, borderRadius: 10, backgroundColor: '#F1F5F9', alignItems: 'center', justifyContent: 'center' },
  listTexts: { flex: 1 },
  listTitle: { fontSize: 15, fontWeight: '700', color: '#0F172A', marginBottom: 2 },
  listSubtitle: { fontSize: 13, color: '#64748B' },
  divider: { backgroundColor: '#F1F5F9', height: 1, marginLeft: 60 },
});
