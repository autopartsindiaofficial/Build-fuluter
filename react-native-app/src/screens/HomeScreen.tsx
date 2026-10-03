import React, { useState, useEffect, useRef, useMemo, useCallback } from 'react';
import { 
  View, 
  StyleSheet, 
  TouchableOpacity, 
  ScrollView, 
  RefreshControl, 
  Image, 
  SafeAreaView, 
  StatusBar, 
  Modal, 
  Animated,
  Easing,
  TextInput,
  KeyboardAvoidingView,
  Platform,
  Linking,
  Share,
  Alert,
  FlatList,
  useWindowDimensions
} from "react-native";
import { 
  Text, 
  ActivityIndicator,
  Button,
  Icon
} from 'react-native-paper';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { getFirebaseFirestore, getCurrentUser } from '../services/firebase';
import { useFavorites } from '../services/favorites';
import { 
  getCurrentLocation, 
  reverseGeocodeLatLng, 
  saveUserLocation,
  getUserSavedLocation
} from '../services/location';
import { requestNotificationPermission, saveFcmTokenToFirestore } from '../services/fcm';
import { INDIAN_STATES_AND_DISTRICTS } from '../data/indianLocations';
import { CarBrandBadge } from '../components/BrandLogo';
import { useLanguage } from '../context/LanguageContext';
import { LanguageSelectorModal } from '../components/LanguageSelectorModal';
import { UpdateDialogModal } from '../components/UpdateDialogModal';
import { BottomSheetModal } from '../components/BottomSheetModal';
import { matchesCategoryFilter } from '../utils/categoryMatcher';
import { matchPartSearch, parseCreatedAt } from '../utils/searchHelper';
import { Category3DIcon } from '../components/Category3DIcon';
import { subscribeToUnreadNotificationCount, subscribeToUserUnreadCounts } from '../services/notifications';
import { useNotificationStore, useAuthStore } from '../store';
import { getOptimizedImageUrl } from '../services/cloudinary';
import { getRecentlyViewedParts, clearRecentlyViewedParts, removeRecentlyViewedPart, subscribeRecentlyViewed } from '../services/recentlyViewed';
import { BannerPartsCollage } from '../components/BannerPartsCollage';
import { 
  initializeTaxonomyDefaults, 
  INITIAL_DEFAULT_CATEGORIES, 
  INITIAL_DEFAULT_BRANDS 
} from '../services/taxonomyDefaults';
import { fastCache } from '../services/fastCache';
import { FastImageOptimized } from '../components/FastImageOptimized';
import NetInfo from '@react-native-community/netinfo';
import { ScalePressable, FadeInSlide, FavoriteHeartButton, AutoScrollBanner, FloatingCategoryItem } from '../components/animations';
import { 
  
  CategoryGridSkeleton,
  BrandListSkeleton,
  ProductGridSkeleton 
} from '../components/ProductCardSkeleton';
import { UserAvatar } from '../components/UserAvatar';

// City coordinates for real distance calculations
const CITY_COORDINATES: Record<string, { lat: number; lng: number }> = {
  'chennai': { lat: 13.0827, lng: 80.2707 },
  'coimbatore': { lat: 11.0168, lng: 76.9558 },
  'madurai': { lat: 9.9252, lng: 78.1198 },
  'trichy': { lat: 10.7905, lng: 78.7047 },
  'tiruchirappalli': { lat: 10.7905, lng: 78.7047 },
  'salem': { lat: 11.6643, lng: 78.1460 },
  'tiruppur': { lat: 11.1085, lng: 77.3411 },
  'erode': { lat: 11.3410, lng: 77.7172 },
  'vellore': { lat: 12.9165, lng: 79.1325 },
  'karur': { lat: 10.9601, lng: 78.0766 },
  'pallapatti': { lat: 10.8655, lng: 78.1065 },
  'bangalore': { lat: 12.9716, lng: 77.5946 },
  'bengaluru': { lat: 12.9716, lng: 77.5946 },
  'mumbai': { lat: 19.0760, lng: 72.8777 },
  'delhi': { lat: 28.6139, lng: 77.2090 },
  'hyderabad': { lat: 17.3850, lng: 78.4867 },
};

export const DEFAULT_BANNERS = [
  {
    id: 'mega-deals',
    badge: 'MEGA DEALS',
    badgeColor: '#0066FF',
    headline1: 'UP TO',
    discount: '50% OFF',
    headline2: 'ON GENUINE PARTS',
    features: ['100% Genuine Parts', 'Best Price Guaranteed', 'Fast & Safe Delivery'],
    cta: 'EXPLORE',
    targetCategory: 'All',
  },
  {
    id: 'turbo-performance',
    badge: 'PERFORMANCE',
    badgeColor: '#EF4444',
    headline1: 'UP TO',
    discount: '40% OFF',
    headline2: 'TURBOCHARGERS',
    features: ['Precision Balanced', 'OEM Grade Build', '1 Year Warranty'],
    cta: 'EXPLORE',
    targetCategory: 'Engine & Parts',
  },
  {
    id: 'brakes-suspension',
    badge: 'SAFETY & COMFORT',
    badgeColor: '#10B981',
    headline1: 'UP TO',
    discount: '45% OFF',
    headline2: 'DISCS & COILOVERS',
    features: ['Ceramic Friction Pads', 'Slotted Steel Discs', 'Anti-Fade Durability'],
    cta: 'EXPLORE',
    targetCategory: 'Suspension',
  },
  {
    id: 'body-electricals',
    badge: 'POPULAR LIGHTING',
    badgeColor: '#F59E0B',
    headline1: 'UP TO',
    discount: '35% OFF',
    headline2: 'LED HEADLIGHTS',
    features: ['Plug & Play Harness', 'High Lumen Output', 'Weather Sealed'],
    cta: 'EXPLORE',
    targetCategory: 'Electricals',
  },
];

export const HOME_DEFAULT_CATEGORIES = [
  {
    id: 'Engine & Mechanical',
    name: 'Engine & Mechanical',
    icon: 'engine',
    imageUrl: 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788828857/categories/v40ctc1xzsul1nmquwno.png',
  },
  {
    id: 'Body & Exterior',
    name: 'Body & Exterior',
    icon: 'car-door',
    imageUrl: 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788915211/categories/ssxl1agf8ydkau5aqv4h.png',
  },
  {
    id: 'Lights & Electricals',
    name: 'Lights & Electricals',
    icon: 'lightning-bolt',
    imageUrl: 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788746594/categories/w1tym7epvnhv0f9aapuf.png',
  },
  {
    id: 'Suspension & Brakes',
    name: 'Suspension & Brakes',
    icon: 'car-brake-alert',
    imageUrl: 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788808169/categories/ebbks7ce3jejqgtxlndo.png',
  },
  {
    id: 'Interior & Wheels',
    name: 'Interior & Wheels',
    icon: 'car-seat',
    imageUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=400&q=80',
  },
  {
    id: 'Cooling & AC',
    name: 'Cooling & AC',
    icon: 'fan',
    imageUrl: 'https://images.unsplash.com/photo-1580273916550-e323be2ae537?auto=format&fit=crop&w=400&q=80',
  },
  {
    id: 'Transmission & Clutch',
    name: 'Transmission & Clutch',
    icon: 'car-shift-pattern',
    imageUrl: 'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?auto=format&fit=crop&w=400&q=80',
  },
  {
    id: 'More',
    name: 'More',
    icon: 'apps',
  },
];

export const HOME_DEFAULT_BRANDS = [
  { id: 'maruti', name: 'Maruti Suzuki' },
  { id: 'hyundai', name: 'Hyundai' },
  { id: 'tata', name: 'Tata' },
  { id: 'mahindra', name: 'Mahindra' },
  { id: 'toyota', name: 'Toyota' },
  { id: 'honda', name: 'Honda' },
  { id: 'kia', name: 'Kia' },
  { id: 'volkswagen', name: 'Volkswagen' },
  { id: 'ford', name: 'Ford' },
];

// Memoized Part Card
const PartCard = React.memo(({ item, navigation, cardWidth, isFavorited, toggleFavorite, selectedCity }: any) => {
  const [imgError, setImgError] = useState(false);

  let resolvedImageSource = null;
  if (imgError) {
    resolvedImageSource = { uri: 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=400&q=80' };
  } else if (item.imageUrl && typeof item.imageUrl === 'string' && item.imageUrl.startsWith('http')) {
    resolvedImageSource = { uri: getOptimizedImageUrl(item.imageUrl, 400, 300) };
  } else if (item.image && typeof item.image === 'string' && item.image.startsWith('http')) {
    resolvedImageSource = { uri: getOptimizedImageUrl(item.image, 400, 300) };
  } else {
    resolvedImageSource = { uri: 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=400&q=80' };
  }

  const isVerified = Boolean(item.isVerifiedSeller || item.verified || (item.sellerRating && item.sellerRating >= 4.5));
  const isFeatured = Boolean(item.featured || item.isFeatured || item.priority === 'urgent');
  const activeFavorited = Boolean(isFavorited);

  // Calculate authentic distance dynamically based on user's selected city
  const itemCity = (item.location || item.district || '').toLowerCase();
  const selectedCityLower = (selectedCity || 'Chennai').toLowerCase();

  let distanceDisplay = item.distance || '3 km';
  if (selectedCity && selectedCity !== 'All India') {
    if (itemCity.includes(selectedCityLower) || selectedCityLower.includes(itemCity)) {
      distanceDisplay = item.distance || '4 km';
    } else {
      const cityCoords = CITY_COORDINATES[selectedCityLower];
      const itemLat = item.lat || item.latitude;
      const itemLng = item.lng || item.longitude;
      if (cityCoords && itemLat && itemLng) {
        const R = 6371; // km
        const dLat = ((itemLat - cityCoords.lat) * Math.PI) / 180;
        const dLon = ((itemLng - cityCoords.lng) * Math.PI) / 180;
        const a =
          Math.sin(dLat / 2) * Math.sin(dLat / 2) +
          Math.cos((cityCoords.lat * Math.PI) / 180) *
            Math.cos((itemLat * Math.PI) / 180) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        const d = Math.round(R * c);
        distanceDisplay = `${d} km`;
      }
    }
  }

  return (
    <View
      style={{
        width: cardWidth,
        height: 260,
        marginBottom: 12,
      }}
    >
      <ScalePressable
        scaleTo={0.97}
        onPress={() => navigation.navigate('ProductDetail', { part: item })}
        style={[styles.card, { height: '100%' }]}
      >
        {/* Top Image Container */}
        <View style={styles.imageContainer}>
          {resolvedImageSource ? (
            <FastImageOptimized 
              source={resolvedImageSource} 
              style={styles.cardImage} 
              resizeMode="cover"
              width={350}
              height={260}
              quality={80}
            />
          ) : (
            <View style={[styles.cardImage, { backgroundColor: '#F1F5F9', justifyContent: 'center', alignItems: 'center' }]}>
              <Icon source="car-cog" size={32} color="#94A3B8" />
              <Text style={{ fontSize: 11.5, fontWeight: '700', color: '#64748B', marginTop: 4 }}>OEM Spare Part</Text>
            </View>
          )}

          {/* OLX-style Featured / Condition Badges */}
          <View style={styles.badgeContainer}>
            {isFeatured ? (
              <View style={styles.badgeFeatured}>
                <Text style={styles.badgeFeaturedText}>FEATURED</Text>
              </View>
            ) : item.condition ? (
              <View style={[
                styles.conditionBadge, 
                (item.condition.toLowerCase().includes('new') ? styles.badgeNew : styles.badgeUsed)
              ]}>
                <Text style={[
                  styles.conditionText,
                  item.condition.toLowerCase().includes('new') ? styles.conditionTextNew : styles.conditionTextUsed
                ]}>
                  {item.condition.toLowerCase().includes('new') ? '✨ NEW' : 'USED'}
                </Text>
              </View>
            ) : null}
          </View>

          {/* Animated Favorite Heart Button */}
          <FavoriteHeartButton
            isFavorited={activeFavorited}
            onPress={() => toggleFavorite(item.id)}
            containerStyle={styles.favoriteButton}
            size={18}
          />
        </View>

        {/* Content Box - True OLX Marketplace Hierarchy */}
        <View style={styles.cardContent}>
          <View>
            {/* Price FIRST - Bold, High-Contrast OLX Marketplace Metric */}
            <View style={styles.priceRow}>
              <Text style={styles.price} numberOfLines={1}>
                ₹{Number(item.price || item.partPrice || 0).toLocaleString('en-IN')}
              </Text>
              {isVerified && (
                <View style={styles.verifiedTag}>
                  <Icon source="check-decagram" size={14} color="#0066FF" />
                </View>
              )}
            </View>

            {/* Title - Clean 2-Line Fixed Height */}
            <Text numberOfLines={2} style={styles.partTitle}>
              {item.title || item.partTitle || item.name}
            </Text>

            {/* Car Model / Subcategory */}
            <Text style={styles.categorySubText} numberOfLines={1}>
              {item.carModel ? `${item.carModel}` : item.category || 'Genuine Part'}
            </Text>
          </View>

          {/* Bottom Location & Distance Row */}
          <View style={styles.locationRow}>
            <Icon source="map-marker" size={12} color="#64748B" />
            <Text numberOfLines={1} style={styles.locationText}>
              {(item.location || item.district || 'CHENNAI').toUpperCase()}
            </Text>
            <Text style={styles.distanceBullet}>•</Text>
            <Text numberOfLines={1} style={styles.distanceBadgeText}>
              {distanceDisplay}
            </Text>
          </View>
        </View>
      </ScalePressable>
    </View>
  );
});

export default function HomeScreen({ navigation, route, user: propUser }: any) {
  const authUser = useAuthStore((state) => state.user);
  const activeUser = propUser || authUser || getCurrentUser();
  const { favorites, toggleFavorite } = useFavorites();
  const { width: screenWidth } = useWindowDimensions();
  const { t, translateDynamic } = useLanguage();

  const [showLanguageModal, setShowLanguageModal] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState(route?.params?.selectedCategory || 'All');
  const [selectedBrand, setSelectedBrand] = useState<string>('All');
  const [selectedCity, setSelectedCity] = useState('All India');
  const [isDetectingGPS, setIsDetectingGPS] = useState(false);
  const [locationSearchQuery, setLocationSearchQuery] = useState('');
  const [minPrice, setMinPrice] = useState('');
  const [maxPrice, setMaxPrice] = useState('');
  const [parts, setParts] = useState<any[]>([]);
  const [topCategories, setTopCategories] = useState<any[]>(HOME_DEFAULT_CATEGORIES);
  const [carBrands, setCarBrands] = useState<any[]>(HOME_DEFAULT_BRANDS);
  const [banners, setBanners] = useState<any[]>(DEFAULT_BANNERS);
  const [activeBannerIndex, setActiveBannerIndex] = useState(0);
  const unreadNotifications = useNotificationStore((state) => state.unreadNotifications);
  const initNotificationListener = useNotificationStore((state) => state.initNotificationListener);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [showFilterModal, setShowFilterModal] = useState(false);
  const [showLocationModal, setShowLocationModal] = useState(false);
  const [selectedActionPart, setSelectedActionPart] = useState<any | null>(null);
  const [showUpdateDialog, setShowUpdateDialog] = useState(false);
  const [updateConfig, setUpdateConfig] = useState<any>(null);
  const [recentlyViewed, setRecentlyViewed] = useState<any[]>([]);

  const activeUid = activeUser?.uid || activeUser?.id || null;

  // Load Recently Viewed Parts on Focus and subscribe to user-specific updates
  useEffect(() => {
    let isMounted = true;
    const loadRecentlyViewed = async () => {
      try {
        const items = await getRecentlyViewedParts(activeUid);
        if (isMounted) {
          setRecentlyViewed(items || []);
        }
      } catch (e) {
        console.warn('Recently viewed load error:', e);
      }
    };
    loadRecentlyViewed();
    const unsubFocus = navigation.addListener('focus', loadRecentlyViewed);
    const unsubChange = subscribeRecentlyViewed((items, notifiedUid) => {
      if (isMounted && (notifiedUid === activeUid || !notifiedUid)) {
        setRecentlyViewed(items || []);
      }
    });
    return () => {
      isMounted = false;
      unsubFocus();
      unsubChange();
    };
  }, [navigation, activeUid]);

  const activeBanners = useMemo(() => {
    if (banners && banners.length > 0) {
      return banners.filter((b: any) => b.active !== false && b.activeStatus !== false);
    }
    return [];
  }, [banners]);

  // Responsive calculations
  // 4 Columns for compact category cards as requested
  const catCardWidth = Math.floor((screenWidth - 32 - 3 * 8) / 4);
  const brandCardWidth = Math.floor((screenWidth - 32 - 4 * 8) / 5);
  const productCardWidth = Math.floor((screenWidth - 32 - 12) / 2);

  // Prompt Notification Permission & Ensure FCM Token on Launch
  useEffect(() => {
    const initNotifications = async () => {
      try {
        await requestNotificationPermission();
        const currentU = getCurrentUser();
        const uid = currentU?.uid || currentU?.id;
        if (uid) {
          await saveFcmTokenToFirestore(uid);
        }
      } catch (err) {
        console.warn('[HomeScreen] Init notifications error:', err);
      }
    };
    initNotifications();
  }, []);

  // Sync selectedCategory when passed via navigation params
  useEffect(() => {
    if (route?.params?.selectedCategory) {
      setSelectedCategory(route.params.selectedCategory);
    }
  }, [route?.params?.selectedCategory]);

  // Instant cache load on boot so categories, brands, and banners never disappear when reopening the app
  useEffect(() => {
    // Proactively request notification permissions and register high-priority channels for status bar alerts
    requestNotificationPermission().catch(() => {});
    if (activeUser?.uid) {
      saveFcmTokenToFirestore(activeUser.uid).catch(() => {});
    }

    initializeTaxonomyDefaults().catch((e) => console.warn('Init taxonomy defaults notice:', e));

    AsyncStorage.getItem('@autoparts_firestore_topCategories').then((val) => {
      if (val) {
        try {
          const parsed = JSON.parse(val);
          const list = Array.isArray(parsed) ? parsed : Object.values(parsed);
          if (list.length > 0) {
            list.sort((a: any, b: any) => (a.order ?? 0) - (b.order ?? 0));
            setTopCategories(list);
          }
        } catch (_) {}
      }
    }).catch(() => {});

    AsyncStorage.getItem('@autoparts_firestore_carBrands').then((val) => {
      if (val) {
        try {
          const parsed = JSON.parse(val);
          const list = Array.isArray(parsed) ? parsed : Object.values(parsed);
          if (list.length > 0) {
            list.sort((a: any, b: any) => (a.order ?? 0) - (b.order ?? 0));
            setCarBrands(list);
          }
        } catch (_) {}
      }
    }).catch(() => {});

    AsyncStorage.getItem('@autoparts_firestore_banners').then((val) => {
      if (val) {
        try {
          const parsed = JSON.parse(val);
          const list = Object.values(parsed);
          if (list.length > 0) {
            list.sort((a: any, b: any) => (a.order ?? 0) - (b.order ?? 0));
            setBanners(list);
          }
        } catch (_) {}
      }
    }).catch(() => {});
  }, []);

  // Load saved location on boot
  useEffect(() => {
    getUserSavedLocation().then((saved) => {
      if (saved && saved.city) {
        setSelectedCity(saved.city);
      }
    });
  }, []);

  // Refresh saved location when screen comes to focus
  useEffect(() => {
    const unsubscribe = navigation?.addListener('focus', () => {
      getUserSavedLocation().then((saved) => {
        if (saved && saved.city) {
          setSelectedCity(saved.city);
        }
      });
    });
    return unsubscribe;
  }, [navigation]);

  const handleSelectCity = async (
    cityName: string,
    extra?: { state?: string; district?: string; area?: string; lat?: number; lng?: number; isGPS?: boolean }
  ) => {
    setSelectedCity(cityName);
    setShowLocationModal(false);
    setLocationSearchQuery('');
    await saveUserLocation({
      city: cityName,
      district: extra?.district,
      state: extra?.state,
      area: extra?.area,
      lat: extra?.lat,
      lng: extra?.lng,
      isGPS: !!extra?.isGPS,
    });
  };

  const handleGPSDetect = async () => {
    setIsDetectingGPS(true);
    try {
      const coords = await getCurrentLocation();
      if (coords) {
        const geo = await reverseGeocodeLatLng(coords.latitude, coords.longitude);
        const chosenCity = geo.district || geo.area || geo.state || 'Chennai';
        await handleSelectCity(chosenCity, {
          state: geo.state,
          district: geo.district,
          area: geo.area,
          lat: coords.latitude,
          lng: coords.longitude,
          isGPS: true,
        });
      }
    } catch (err) {
      console.warn('GPS detection error:', err);
    } finally {
      setIsDetectingGPS(false);
    }
  };

  // Real-time notification & chat unread listener for bell icon
  useEffect(() => {
    const unsub = initNotificationListener(activeUser?.uid || authUser?.uid);
    return () => {
      try { unsub(); } catch (_) {}
    };
  }, [activeUser?.uid, authUser?.uid, initNotificationListener]);

  // Entrance Animations
  const headerFade = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.timing(headerFade, {
      toValue: 1,
      duration: 350,
      useNativeDriver: true,
    }).start();
  }, []);

  // Fetch Parts from Firestore
  const fetchParts = useCallback((isPullRefresh = false) => {
    setLoading(true);
    const startTime = Date.now();
    const MIN_LOADING_TIME = isPullRefresh ? 600 : 700; // Guarantee smooth skeleton display

    try {
      // Load from local cache first for offline safety
      AsyncStorage.getItem('@autoparts_firestore_parts').then((cached) => {
        if (cached) {
          try {
            const parsed = JSON.parse(cached);
            if (Array.isArray(parsed) && parsed.length > 0) {
              setParts(parsed);
              const elapsed = Date.now() - startTime;
              const remaining = Math.max(0, MIN_LOADING_TIME - elapsed);
              setTimeout(() => {
                setLoading(false);
                setRefreshing(false);
              }, remaining);
            }
          } catch (_) {}
        }
      }).catch(() => {});

      const db = getFirebaseFirestore();
      if (!db || typeof db.collection !== 'function') {
        setParts([]);
        const elapsed = Date.now() - startTime;
        const remaining = Math.max(0, MIN_LOADING_TIME - elapsed);
        setTimeout(() => {
          setLoading(false);
          setRefreshing(false);
        }, remaining);
        return () => {};
      }

      const unsubscribe = db.collection('spareParts').onSnapshot(
        (snapshot: any) => {
          const partsList: any[] = [];
          if (snapshot && typeof snapshot.forEach === 'function') {
            snapshot.forEach((doc: any) => {
              const data = doc.data ? doc.data() : doc;
              if (data && (data.isDeleted === true || data.status === 'deleted')) {
                return;
              }
              partsList.push({ id: doc.id, ...data });
            });
          }
          if (partsList.length === 0) {
            setParts([]);
          } else {
            partsList.sort((a, b) => parseCreatedAt(b.createdAt) - parseCreatedAt(a.createdAt));
            setParts(partsList);
            AsyncStorage.setItem('@autoparts_firestore_parts', JSON.stringify(partsList)).catch(() => {});
          }
          const elapsed = Date.now() - startTime;
          const remaining = Math.max(0, MIN_LOADING_TIME - elapsed);
          setTimeout(() => {
            setLoading(false);
            setRefreshing(false);
          }, remaining);
        },
        (error: any) => {
          console.warn('[HomeScreen] Firestore parts snapshot error:', error);
          setParts((prev) => (prev.length > 0 ? prev : []));
          const elapsed = Date.now() - startTime;
          const remaining = Math.max(0, MIN_LOADING_TIME - elapsed);
          setTimeout(() => {
            setLoading(false);
            setRefreshing(false);
          }, remaining);
        }
      );

      return unsubscribe;
    } catch (e) {
      console.warn('[HomeScreen] Exception fetching parts:', e);
      setParts([]);
      const elapsed = Date.now() - startTime;
      const remaining = Math.max(0, MIN_LOADING_TIME - elapsed);
      setTimeout(() => {
        setLoading(false);
        setRefreshing(false);
      }, remaining);
      return () => {};
    }
  }, []);

  // Fetch Firestore Top Categories & Car Brands & Banners
  useEffect(() => {
    try {
      const db = getFirebaseFirestore();
      if (!db || typeof db.collection !== 'function') return;

      const unsubCats = db.collection('topCategories').onSnapshot((snap: any) => {
        const catList: any[] = [];
        if (snap && typeof snap.forEach === 'function') {
          snap.forEach((doc: any) => {
            const data = doc.data ? doc.data() : doc;
            catList.push({ id: doc.id, ...data });
          });
        }
        catList.sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
        setTopCategories(catList);
        AsyncStorage.setItem('@autoparts_firestore_topCategories', JSON.stringify(catList)).catch(() => {});
      }, (err: any) => console.warn('Categories sync error:', err));

      const unsubBrands = db.collection('carBrands').onSnapshot((snap: any) => {
        const brandList: any[] = [];
        if (snap && typeof snap.forEach === 'function') {
          snap.forEach((doc: any) => {
            const data = doc.data ? doc.data() : doc;
            brandList.push({ id: doc.id, ...data });
          });
        }
        brandList.sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
        setCarBrands(brandList);
        AsyncStorage.setItem('@autoparts_firestore_carBrands', JSON.stringify(brandList)).catch(() => {});
      }, (err: any) => console.warn('Car brands sync error:', err));

      const unsubBanners = db.collection('banners').onSnapshot((snap: any) => {
        const bannerList: any[] = [];
        if (snap && typeof snap.forEach === 'function') {
          snap.forEach((doc: any) => {
            const data = doc.data ? doc.data() : doc;
            bannerList.push({ id: doc.id, ...data });
          });
        }
        bannerList.sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
        setBanners(bannerList);
        AsyncStorage.setItem('@autoparts_firestore_banners', JSON.stringify(bannerList)).catch(() => {});
      }, (err: any) => console.warn('Banners sync error:', err));

      return () => {
        try { unsubCats(); } catch (_) {}
        try { unsubBrands(); } catch (_) {}
        try { unsubBanners(); } catch (_) {}
      };
    } catch (e) {
      console.warn('Metadata listener setup error:', e);
    }
  }, []);

  useEffect(() => {
    const unsub = fetchParts();
    return () => {
      try {
        if (typeof unsub === 'function') unsub();
      } catch (_) {}
    };
  }, [fetchParts]);

  // Auto-reconnect & refresh data when network comes back online
  useEffect(() => {
    const unsubscribeNet = NetInfo.addEventListener((state) => {
      if (state.isConnected && state.isInternetReachable !== false) {
        console.log('[HomeScreen] Internet reconnected, refreshing parts & data...');
        fetchParts();
      }
    });

    return () => {
      unsubscribeNet();
    };
  }, [fetchParts]);

  const onRefresh = () => {
    setRefreshing(true);
    fetchParts(true);

    try {
      const db = getFirebaseFirestore();
      if (db && typeof db.collection === 'function') {
        db.collection('topCategories').get().then((snap: any) => {
          const catList: any[] = [];
          if (snap && typeof snap.forEach === 'function') {
            snap.forEach((doc: any) => {
              const data = doc.data ? doc.data() : doc;
              catList.push({ id: doc.id, ...data });
            });
          }
          if (catList.length > 0) {
            catList.sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
            setTopCategories(catList);
            AsyncStorage.setItem('@autoparts_firestore_topCategories', JSON.stringify(catList)).catch(() => {});
          }
        }).catch(() => {});

        db.collection('carBrands').get().then((snap: any) => {
          const brandList: any[] = [];
          if (snap && typeof snap.forEach === 'function') {
            snap.forEach((doc: any) => {
              const data = doc.data ? doc.data() : doc;
              brandList.push({ id: doc.id, ...data });
            });
          }
          if (brandList.length > 0) {
            brandList.sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
            setCarBrands(brandList);
            AsyncStorage.setItem('@autoparts_firestore_carBrands', JSON.stringify(brandList)).catch(() => {});
          }
        }).catch(() => {});
      }
    } catch (_) {}
  };

  const handleShare = async () => {
    try {
      await Share.share({
        message: 'Download Auto Parts India App to buy and sell verified car spare parts! https://autoparts.in',
      });
    } catch (e) {
      console.warn('Share error:', e);
    }
  };

  // Filter Parts Based on Search, Category, Brand, Price and Location
  const filteredParts = useMemo(() => {
    const scoredList: { part: any; score: number }[] = [];

    for (const part of parts) {
      // 0. Exclude deleted, sold or inactive parts from marketplace feed
      if (
        part.isDeleted === true ||
        part.status === 'deleted' ||
        part.sold === true ||
        part.status === 'sold'
      ) {
        continue;
      }

      // 1. Search filter & Scoring
      let searchScore = 0;
      if (searchQuery.trim()) {
        const result = matchPartSearch(part, searchQuery.trim());
        if (!result.matches) {
          continue;
        }
        searchScore = result.score;
      }

      // 2. Category filter
      if (selectedCategory && selectedCategory !== 'All' && selectedCategory !== 'All Categories') {
        const matchesCat = matchesCategoryFilter(part, selectedCategory);
        if (!matchesCat) {
          continue;
        }
      }

      // 3. Brand filter
      if (selectedBrand && selectedBrand !== 'All' && selectedBrand !== 'All Brands') {
        const brandLower = selectedBrand.toLowerCase().trim();
        const partBrand = (part.brand || part.carBrand || part.make || '').toString().toLowerCase().trim();
        const partTitle = (part.title || part.name || '').toString().toLowerCase().trim();
        const partModel = (part.carModel || part.model || '').toString().toLowerCase().trim();
        const brandMatched = 
          partBrand === brandLower ||
          (partBrand && (partBrand.includes(brandLower) || brandLower.includes(partBrand))) ||
          partTitle.includes(brandLower) ||
          partModel.includes(brandLower);

        if (!brandMatched) {
          continue;
        }
      }

      // 4. Price filter
      const price = Number(part.price || part.partPrice || 0);
      if (minPrice && price < Number(minPrice)) continue;
      if (maxPrice && price > Number(maxPrice)) continue;

      // 5. City filter
      if (selectedCity && selectedCity !== 'All India') {
        const cityLower = selectedCity.toLowerCase().trim();
        const partLoc = [
          part.location,
          part.district,
          part.city,
          part.state,
          part.area,
          part.sellerCity,
          part.sellerDistrict,
          part.sellerState
        ]
          .filter(Boolean)
          .join(' ')
          .toLowerCase();

        if (!partLoc.includes(cityLower)) {
          // Allow nationwide shipping parts or parts without strict location
          const canShip = Boolean(part.deliveryAvailable || part.allIndiaShipping);
          if (!canShip) {
            continue;
          }
        }
      }

      scoredList.push({ part, score: searchScore });
    }

    // Sort: If search query active, sort by relevance score; otherwise by newest
    return scoredList.sort((a, b) => {
      if (searchQuery.trim()) {
        if (b.score !== a.score) {
          return b.score - a.score;
        }
      }
      return parseCreatedAt(b.part.createdAt) - parseCreatedAt(a.part.createdAt);
    }).map((item) => item.part);
  }, [parts, searchQuery, selectedCategory, selectedBrand, minPrice, maxPrice, selectedCity]);

  // Display Categories for Grid: Top 7 + More
  const displayCategories = useMemo(() => {
    let rawList: any[] = [];
    if (topCategories && topCategories.length > 0) {
      const activeList = topCategories.filter((c: any) => c.active !== false);
      rawList = activeList.map((c: any) => ({
        id: c.id || c.name,
        name: c.name || c.title,
        icon: c.icon || 'car-cog',
        imageUrl: c.imageUrl,
        iconUrl: c.iconUrl || c.imageUrl,
        order: typeof c.order === 'number' ? c.order : 0,
      }));
      rawList.sort((a, b) => a.order - b.order);
    } else {
      rawList = HOME_DEFAULT_CATEGORIES;
    }

    const withoutMore = rawList.filter((c: any) => c.name?.toLowerCase() !== 'more' && c.id !== 'More');
    const top7 = withoutMore.slice(0, 7);
    const moreItem = {
      id: 'More',
      name: 'More',
      icon: 'dots-grid',
      imageUrl: undefined,
      iconUrl: undefined,
      order: 999,
    };
    return [...top7, moreItem];
  }, [topCategories]);

  // Full Categories list for Filter Modal (shows all categories without 'More' button)
  const allCategoriesForFilter = useMemo(() => {
    let rawList: any[] = [];
    if (topCategories && topCategories.length > 0) {
      const activeList = topCategories.filter((c: any) => c.active !== false);
      rawList = activeList.map((c: any) => ({
        id: c.id || c.name,
        name: c.name || c.title,
        order: typeof c.order === 'number' ? c.order : 0,
      }));
      rawList.sort((a, b) => a.order - b.order);
    } else {
      rawList = HOME_DEFAULT_CATEGORIES;
    }
    // Return all categories, ensuring no 'More' button is mixed in
    return rawList.filter((c: any) => c.name?.toLowerCase() !== 'more' && c.id !== 'More');
  }, [topCategories]);

  // Display Brands: Prefer Firestore carBrands if populated, otherwise fallback to defaults
  const displayBrands = useMemo(() => {
    if (carBrands && carBrands.length > 0) {
      const activeList = carBrands.filter((b: any) => b.active !== false);
      activeList.sort((a: any, b: any) => (a.order ?? 0) - (b.order ?? 0));
      return activeList;
    }
    return HOME_DEFAULT_BRANDS;
  }, [carBrands]);

  // Memoized renderItem for high-performance 60fps flatlist rendering
  const renderPartCard = useCallback(({ item }: any) => {
    const isFav = favorites.includes(item.id) ||
      (favorites as any[]).some((f: any) => f === item.id || f?.id === item.id);
    return (
      <PartCard
        item={item}
        navigation={navigation}
        cardWidth={productCardWidth}
        isFavorited={isFav}
        toggleFavorite={toggleFavorite}
        selectedCity={selectedCity}
      />
    );
  }, [favorites, navigation, productCardWidth, toggleFavorite, selectedCity]);

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#0066FF" />

      {/* ROYAL BLUE BRAND HEADER - Original Clean Theme */}
      <View style={styles.royalHeader}>
        <View style={styles.topBar}>
          {/* Brand Title & Location */}
          <View style={styles.brandTitleRow}>
            <Image 
              source={require('../assets/header_logo.png')}
              style={{ width: 105, height: 32, resizeMode: 'contain', marginRight: 8 }}
            />
            <View style={styles.brandTextCol}>
              {/* Location Selector */}
              <ScalePressable 
                style={styles.locationButton}
                scaleTo={0.94}
                onPress={() => navigation.navigate('LocationSelectScreen')}
              >
                <Icon source="map-marker" size={13} color="#BAE6FD" />
                <Text style={styles.locationTitle} numberOfLines={1}>
                  {selectedCity || 'All India'}
                </Text>
                <Icon source="chevron-down" size={13} color="#BAE6FD" />
              </ScalePressable>
            </View>
          </View>

          {/* Right Action Icons: Language, Notifications */}
          <View style={styles.headerActionRow}>
            {/* Language Selector */}
            <ScalePressable
              style={styles.iconBtn}
              scaleTo={0.9}
              onPress={() => setShowLanguageModal(true)}
            >
              <Icon source="translate" size={20} color="#FFFFFF" />
            </ScalePressable>

            {/* Notifications */}
            <ScalePressable
              style={styles.iconBtn}
              scaleTo={0.9}
              onPress={() => navigation.navigate('Notifications')}
            >
              <Icon source="bell-outline" size={20} color="#FFFFFF" />
              {unreadNotifications > 0 && (
                <View style={styles.badgeRed}>
                  <Text style={styles.badgeText}>{unreadNotifications > 9 ? '9+' : unreadNotifications}</Text>
                </View>
              )}
            </ScalePressable>
          </View>
        </View>

        {/* SEARCH BAR ROW IN BLUE HEADER */}
        <View style={styles.searchBarRow}>
          <ScalePressable
            style={styles.searchBox}
            scaleTo={0.98}
            onPress={() => navigation.navigate('Search')}
          >
            <Icon source="magnify" size={20} color="#64748B" />
            <Text style={styles.searchPlaceholder}>
              Search spare parts, headlights, bumper...
            </Text>
          </ScalePressable>

          <ScalePressable
            style={styles.filterBtn}
            scaleTo={0.92}
            onPress={() => setShowFilterModal(true)}
          >
            <Icon source="tune-variant" size={20} color="#0066FF" />
          </ScalePressable>
        </View>
      </View>

      {/* MAIN VIRTUALIZED FEED (FlatList for high performance) */}
      <FlatList
        data={loading ? [] : filteredParts}
        keyExtractor={(item) => item.id || String(Math.random())}
        renderItem={renderPartCard}
        numColumns={2}
        columnWrapperStyle={styles.partsGridColumnWrapper}
        scrollEventThrottle={16}
        bounces={true}
        alwaysBounceVertical={true}
        decelerationRate="normal"
        overScrollMode="never"
        keyboardDismissMode="on-drag"
        keyboardShouldPersistTaps="handled"
        initialNumToRender={8}
        maxToRenderPerBatch={10}
        windowSize={7}
        updateCellsBatchingPeriod={50}
        removeClippedSubviews={Platform.OS === 'android'}
        ListHeaderComponent={
          <View>
            {/* HERO PROMO BANNER: Auto-scrolling Hero Banner with Smooth Dots */}
            <AutoScrollBanner
              banners={activeBanners.slice(0, 4)}
              screenWidth={screenWidth}
              onBannerPress={(item: any) => {
                const target = item.targetLink || item.targetCategory || item.category || '';
                if (target && target !== 'All') {
                  setSelectedCategory(target);
                } else {
                  navigation.navigate('Search');
                }
              }}
            />

            {/* 1. TOP CATEGORIES (4-Column Grid) - Real Admin Categories Only */}
            <View style={styles.sectionHeaderRow}>
              <Text variant="titleMedium" style={styles.sectionTitle}>
                Top Categories
              </Text>
            </View>

            {loading ? (
              <CategoryGridSkeleton cardWidth={catCardWidth} count={8} />
            ) : displayCategories.length > 0 ? (
              <View style={styles.categoriesGrid}>
                {displayCategories.slice(0, 8).map((cat: any, idx: number) => {
                  const isSelected = selectedCategory.toLowerCase() === cat.name.toLowerCase();
                  const isMore = cat.id === 'More' || cat.name?.toLowerCase() === 'more';
                  return (
                    <FadeInSlide
                      key={cat.id || cat.name}
                      delay={idx * 30}
                      slideDistance={10}
                      style={{ width: catCardWidth }}
                    >
                      <ScalePressable
                        scaleTo={0.93}
                        style={[styles.categoryItem, { width: catCardWidth }]}
                        onPress={() => {
                          if (isMore) {
                            navigation.navigate('AllCategories');
                          } else {
                            setSelectedCategory(isSelected ? 'All' : cat.name);
                          }
                        }}
                      >
                        {/* Top Rounded Card Box - 100% Image Filled */}
                        <View
                          style={[
                            styles.categoryCardBox,
                            { width: catCardWidth, height: catCardWidth },
                            isSelected && styles.categoryCardBoxActive,
                          ]}
                        >
                          {isMore ? (
                            <View style={[styles.categoryFallbackCenter, { backgroundColor: '#EFF6FF' }]}>
                              <Icon source="dots-grid" size={Math.round(catCardWidth * 0.45)} color="#0066FF" />
                            </View>
                          ) : cat.imageUrl ? (
                            <Image
                              source={{ uri: cat.imageUrl }}
                              style={styles.categoryFullImage}
                              resizeMode="cover"
                            />
                          ) : (
                            <View style={styles.categoryFallbackCenter}>
                              <Category3DIcon
                                categoryName={cat.name}
                                iconUrl={cat.iconUrl}
                                size={Math.round(catCardWidth * 0.56)}
                              />
                            </View>
                          )}
                        </View>

                        {/* Outside Text Label Below Card */}
                        <Text
                          style={[
                            styles.categoryLabel, 
                            isSelected && styles.categoryLabelActive,
                            isMore && { color: '#0066FF', fontWeight: '700' }
                          ]}
                          numberOfLines={2}
                        >
                          {cat.name}
                        </Text>
                      </ScalePressable>
                    </FadeInSlide>
                  );
                })}
              </View>
            ) : null}

            {/* 3. POPULAR CAR BRANDS - Real Admin Brands Only */}
            <View style={styles.sectionHeaderRow}>
              <Text variant="titleMedium" style={styles.sectionTitle}>
                Popular Brands
              </Text>
            </View>

            {loading ? (
              <BrandListSkeleton count={5} />
            ) : displayBrands.length > 0 ? (
              <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                nestedScrollEnabled={true}
                scrollEventThrottle={16}
                decelerationRate="normal"
                overScrollMode="never"
                keyboardShouldPersistTaps="handled"
                contentContainerStyle={styles.brandsScroll}
              >
                {displayBrands.map((brand: any) => {
                  const isSelected = selectedBrand.toLowerCase() === brand.name.toLowerCase();
                  return (
                    <ScalePressable
                      key={brand.id || brand.name}
                      scaleTo={0.94}
                      style={[styles.brandPill, isSelected && styles.brandPillActive]}
                      onPress={() => {
                        setSelectedBrand(isSelected ? 'All' : brand.name);
                      }}
                    >
                      <CarBrandBadge brandName={brand.name} logoUrl={brand.logoUrl || brand.imageUrl} size={24} />
                      <Text style={[styles.brandNameText, isSelected && styles.brandNameTextActive]}>
                        {brand.name}
                      </Text>
                    </ScalePressable>
                  );
                })}
              </ScrollView>
            ) : null}

            {/* RECENTLY VIEWED PARTS SLIDER */}
            {recentlyViewed && recentlyViewed.length > 0 ? (
              <View style={{ marginTop: 16 }}>
                <View style={styles.sectionHeaderRow}>
                  <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                    <Icon source="clock-outline" size={18} color="#0066FF" />
                    <Text variant="titleMedium" style={styles.sectionTitle}>
                      Recently Viewed
                    </Text>
                  </View>
                  <TouchableOpacity
                    onPress={() => {
                      Alert.alert(
                        translateDynamic('Clear History'),
                        translateDynamic('Are you sure you want to clear all recently viewed items?'),
                        [
                          { text: translateDynamic('Cancel'), style: 'cancel' },
                          {
                            text: translateDynamic('Clear All'),
                            style: 'destructive',
                            onPress: async () => {
                              await clearRecentlyViewedParts(activeUid || undefined);
                              setRecentlyViewed([]);
                            },
                          },
                        ]
                      );
                    }}
                    hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
                  >
                    <Text style={{ fontSize: 13, fontWeight: '700', color: '#0066FF' }}>
                      {translateDynamic('Clear')}
                    </Text>
                  </TouchableOpacity>
                </View>

                <ScrollView
                  horizontal
                  showsHorizontalScrollIndicator={false}
                  nestedScrollEnabled={true}
                  scrollEventThrottle={16}
                  decelerationRate="normal"
                  overScrollMode="never"
                  keyboardShouldPersistTaps="handled"
                  contentContainerStyle={{ paddingHorizontal: 16, gap: 12, paddingVertical: 4 }}
                >
                  {recentlyViewed.map((rvItem: any) => (
                    <TouchableOpacity
                      key={`rv-${rvItem.id}`}
                      style={styles.recentlyViewedCard}
                      activeOpacity={0.88}
                      onPress={() => navigation.navigate('ProductDetail', { part: rvItem })}
                      onLongPress={() => {
                        Alert.alert(
                          translateDynamic('Remove Item'),
                          translateDynamic('Remove this item from recently viewed?'),
                          [
                            { text: translateDynamic('Cancel'), style: 'cancel' },
                            {
                              text: translateDynamic('Remove'),
                              style: 'destructive',
                              onPress: async () => {
                                await removeRecentlyViewedPart(rvItem.id, activeUid || undefined);
                                setRecentlyViewed((prev) => prev.filter((p) => p.id !== rvItem.id));
                              },
                            },
                          ]
                        );
                      }}
                    >
                      <View style={{ position: 'relative' }}>
                        <Image
                          source={{
                            uri:
                              rvItem.imageUrl ||
                              rvItem.image ||
                              'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&q=80&w=200',
                          }}
                          style={styles.recentlyViewedImage}
                        />
                        <TouchableOpacity
                          style={{
                            position: 'absolute',
                            top: 4,
                            right: 4,
                            backgroundColor: 'rgba(15, 23, 42, 0.65)',
                            borderRadius: 10,
                            width: 20,
                            height: 20,
                            alignItems: 'center',
                            justifyContent: 'center',
                          }}
                          onPress={async () => {
                            await removeRecentlyViewedPart(rvItem.id, activeUid || undefined);
                            setRecentlyViewed((prev) => prev.filter((p) => p.id !== rvItem.id));
                          }}
                          hitSlop={{ top: 6, bottom: 6, left: 6, right: 6 }}
                        >
                          <Icon source="close" size={12} color="#FFFFFF" />
                        </TouchableOpacity>
                      </View>
                      <View style={styles.recentlyViewedInfo}>
                        <Text numberOfLines={1} style={styles.recentlyViewedTitle}>
                          {rvItem.title || rvItem.name || 'Spare Part'}
                        </Text>
                        <Text style={styles.recentlyViewedPrice}>
                          ₹{Number(rvItem.price || rvItem.partPrice || 0).toLocaleString('en-IN')}
                        </Text>
                      </View>
                    </TouchableOpacity>
                  ))}
                </ScrollView>
              </View>
            ) : null}

            {/* 4. VERIFIED SPARE PARTS FEED */}
            <View style={[styles.sectionHeaderRow, { marginTop: 20 }]}>
              <Text variant="titleMedium" style={styles.sectionTitle}>
                {selectedCategory !== 'All' 
                  ? (selectedCategory.toLowerCase().endsWith('parts') ? selectedCategory : `${selectedCategory} Parts`) 
                  : 'Fresh Recommendations'}
              </Text>
              <Text style={styles.partsCountText}>{filteredParts.length} Parts</Text>
            </View>

            {selectedCategory !== 'All' && (
              <View style={styles.activeFilterBar}>
                <View style={styles.activeFilterPill}>
                  <Icon source="filter-variant" size={14} color="#0066FF" />
                  <Text style={styles.activeFilterPillText}>{selectedCategory}</Text>
                  <TouchableOpacity
                    activeOpacity={0.7}
                    onPress={() => setSelectedCategory('All')}
                    hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                    style={styles.filterCloseCircle}
                  >
                    <Icon source="close" size={11} color="#FFFFFF" />
                  </TouchableOpacity>
                </View>
                <TouchableOpacity 
                  activeOpacity={0.7}
                  onPress={() => setSelectedCategory('All')}
                >
                  <Text style={styles.clearFilterText}>Show All Parts</Text>
                </TouchableOpacity>
              </View>
            )}
          </View>
        }
        ListEmptyComponent={
          loading ? (
            <ProductGridSkeleton cardWidth={productCardWidth} count={6} />
          ) : (
            <View style={styles.emptyBox}>
              <Icon source="car-off" size={48} color="#64748B" />
              <Text style={styles.emptyTitle}>No Spare Parts Found</Text>
              <Text style={styles.emptySubtitle}>
                No parts match your current category or location filter. Try clearing filters.
              </Text>
              <Button
                mode="contained"
                onPress={() => {
                  setSelectedCategory('All');
                  setSelectedBrand('All');
                  setSelectedCity('All India');
                }}
                style={styles.resetBtn}
              >
                Reset Filters
              </Button>
            </View>
          )
        }
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor="#0066FF"
            colors={['#0066FF']}
          />
        }
        showsVerticalScrollIndicator={false}
        scrollEventThrottle={16}
        bounces={true}
        alwaysBounceVertical={true}
        decelerationRate="normal"
        overScrollMode="never"
        keyboardDismissMode="on-drag"
        removeClippedSubviews={Platform.OS === 'android'}
        maxToRenderPerBatch={10}
        windowSize={7}
        initialNumToRender={8}
        updateCellsBatchingPeriod={50}
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
      />

      {/* FILTER BOTTOM SHEET */}
      <BottomSheetModal
        visible={showFilterModal}
        onClose={() => setShowFilterModal(false)}
        height={Platform.OS === 'ios' ? 450 : 480}
      >
        <View style={styles.modalHeader}>
          <Text variant="titleMedium" style={styles.modalTitle}>Filter Spare Parts</Text>
          <TouchableOpacity onPress={() => setShowFilterModal(false)} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
            <Icon source="close" size={24} color="#0F172A" />
          </TouchableOpacity>
        </View>

        <ScrollView style={styles.modalBody}>
          <Text style={styles.filterLabel}>Price Range (₹)</Text>
          <View style={styles.priceInputRow}>
            <TextInput
              style={styles.priceInput}
              placeholder="Min Price"
              placeholderTextColor="#64748B"
              keyboardType="numeric"
              value={minPrice}
              onChangeText={setMinPrice}
            />
            <Text style={{ color: '#94A3B8' }}>—</Text>
            <TextInput
              style={styles.priceInput}
              placeholder="Max Price"
              placeholderTextColor="#64748B"
              keyboardType="numeric"
              value={maxPrice}
              onChangeText={setMaxPrice}
            />
          </View>

          <Text style={[styles.filterLabel, { marginTop: 16 }]}>Category</Text>
          <View style={styles.modalPillWrap}>
            {['All', ...allCategoriesForFilter.map((c) => c.name)].map((cat) => {
              return (
                <TouchableOpacity
                  key={cat}
                  style={[styles.modalPill, selectedCategory === cat && styles.modalPillActive]}
                  onPress={() => {
                    setSelectedCategory(cat);
                  }}
                >
                  <Text style={[styles.modalPillText, selectedCategory === cat && styles.modalPillTextActive]}>
                    {cat}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        </ScrollView>

        <View style={styles.modalFooter}>
          <ScalePressable
            style={styles.modalClearBtn}
            scaleTo={0.94}
            onPress={() => {
              setMinPrice('');
              setMaxPrice('');
              setSelectedCategory('All');
              setSelectedBrand('All');
              setShowFilterModal(false);
            }}
          >
            <Text style={styles.modalClearText}>Clear All</Text>
          </ScalePressable>

          <ScalePressable
            style={styles.modalApplyBtn}
            scaleTo={0.96}
            onPress={() => setShowFilterModal(false)}
          >
            <Text style={styles.modalApplyText}>Apply Filters</Text>
          </ScalePressable>
        </View>
      </BottomSheetModal>

      {/* Language Selector Modal */}
      <LanguageSelectorModal
        visible={showLanguageModal}
        onClose={() => setShowLanguageModal(false)}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  royalHeader: {
    backgroundColor: '#0066FF',
    paddingBottom: 14,
    borderBottomLeftRadius: 16,
    borderBottomRightRadius: 16,
    shadowColor: '#002F34',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 10,
    elevation: 4,
  },
  topBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: 8,
    paddingBottom: 8,
  },
  brandTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    flex: 1,
  },
  brandTextCol: {
    flex: 1,
  },
  brandRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  brandAutoParts: {
    fontSize: 18,
    fontWeight: '800',
    color: '#FFFFFF',
    letterSpacing: 0.2,
  },
  brandIndia: {
    fontSize: 18,
    fontWeight: '800',
    color: '#FF6B00',
    letterSpacing: 0.2,
  },
  locationButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    marginTop: 1,
  },
  locationTitle: {
    color: '#E0F2FE',
    fontWeight: '600',
    fontSize: 12,
    maxWidth: 130,
  },
  headerActionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  iconBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(255, 255, 255, 0.18)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  profileHeaderBtn: {
    width: 34,
    height: 34,
    borderRadius: 17,
    justifyContent: 'center',
    alignItems: 'center',
    marginLeft: 2,
  },
  badge: {
    position: 'absolute',
    top: -3,
    right: -3,
    backgroundColor: '#38BDF8',
    borderRadius: 10,
    minWidth: 16,
    height: 16,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 3,
  },
  badgeRed: {
    position: 'absolute',
    top: -3,
    right: -3,
    backgroundColor: '#EF4444',
    borderRadius: 10,
    minWidth: 16,
    height: 16,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 3,
  },
  badgeText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: 'bold',
  },
  searchBarRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 16,
    paddingTop: 4,
  },
  searchBox: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 11,
    gap: 8,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 5,
    elevation: 2,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  searchPlaceholder: {
    color: '#94A3B8',
    fontSize: 13,
    flex: 1,
  },
  filterBtn: {
    width: 44,
    height: 44,
    borderRadius: 8,
    backgroundColor: '#FFFFFF',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 5,
    elevation: 2,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  scrollContent: {
    paddingBottom: 36,
  },
  bannerOuterContainer: {
    marginHorizontal: 16,
    marginTop: 14,
    marginBottom: 6,
  },
  fullImageBannerCard: {
    width: '100%',
    aspectRatio: 2.3,
    borderRadius: 18,
    overflow: 'hidden',
    backgroundColor: '#051433',
    borderWidth: 0,
    borderColor: '#E2E8F0',
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 8,
    elevation: 3,
  },
  fullBannerImage: {
    width: '100%',
    height: '100%',
  },
  megaDealBanner: {
    backgroundColor: '#051433',
    borderRadius: 18,
    padding: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    overflow: 'hidden',
    position: 'relative',
    height: 168,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 4,
  },
  bannerLeftContent: {
    flex: 1.25,
    paddingRight: 6,
    justifyContent: 'center',
  },
  bannerBadgePill: {
    backgroundColor: '#0066FF',
    paddingHorizontal: 7,
    paddingVertical: 2.5,
    borderRadius: 5,
    alignSelf: 'flex-start',
    marginBottom: 4,
  },
  bannerBadgePillText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  bannerSubHeadSmall: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '900',
    letterSpacing: 0.5,
    marginBottom: 0,
    opacity: 1,
  },
  megaDealDiscount: {
    color: '#FEE140',
    fontSize: 26,
    fontWeight: '900',
    lineHeight: 30,
    textShadowColor: 'rgba(0, 0, 0, 0.4)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 3,
  },
  megaDealHeadline: {
    color: '#FFFFFF',
    fontSize: 12.5,
    fontWeight: '900',
    letterSpacing: 0.2,
    marginTop: 1,
    marginBottom: 2,
    opacity: 1,
  },
  bannerFeatureList: {
    marginVertical: 4,
    gap: 3,
  },
  bannerFeatureItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  bannerFeatureText: {
    color: '#FFFFFF',
    fontSize: 11.5,
    fontWeight: '700',
    opacity: 0.95,
  },
  shopNowBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    alignSelf: 'flex-start',
    paddingHorizontal: 12,
    paddingVertical: 5,
    borderRadius: 20,
    gap: 3,
    marginTop: 2,
  },
  shopNowBtnText: {
    color: '#0F172A',
    fontSize: 12,
    fontWeight: '800',
  },
  bannerRightArt: {
    flex: 1,
    height: 130,
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
  },
  bannerGlowCircle: {
    position: 'absolute',
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: '#1E40AF',
    opacity: 0.6,
  },
  bannerArtImage: {
    width: '100%',
    height: '100%',
    borderRadius: 12,
  },
  dotsRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 10,
    gap: 5,
  },
  dot: {
    width: 5,
    height: 5,
    borderRadius: 2.5,
    backgroundColor: '#CBD5E1',
  },
  activeDot: {
    width: 20,
    height: 5,
    borderRadius: 2.5,
    backgroundColor: '#0066FF',
  },
  sectionHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    marginTop: 20,
    marginBottom: 12,
  },
  activeFilterBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    marginBottom: 12,
    marginTop: -4,
  },
  activeFilterPill: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#EFF6FF',
    borderWidth: 0,
    borderColor: '#BFDBFE',
    borderRadius: 20,
    paddingVertical: 4,
    paddingLeft: 10,
    paddingRight: 6,
    gap: 6,
  },
  activeFilterPillText: {
    color: '#0066FF',
    fontSize: 12,
    fontWeight: '700',
  },
  filterCloseCircle: {
    backgroundColor: '#0066FF',
    borderRadius: 8,
    width: 16,
    height: 16,
    justifyContent: 'center',
    alignItems: 'center',
  },
  clearFilterText: {
    color: '#64748B',
    fontSize: 12,
    fontWeight: '600',
    textDecorationLine: 'underline',
  },
  sectionTitle: {
    color: '#0F172A',
    fontWeight: '800',
    fontSize: 16,
  },
  seeAllText: {
    color: '#0066FF',
    fontWeight: '700',
    fontSize: 13,
  },
  categoriesGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    paddingHorizontal: 16,
    marginTop: 10,
  },
  categoryItem: {
    alignItems: 'center',
    marginBottom: 14,
  },
  categoryCardBox: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    overflow: 'hidden',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.04,
    shadowRadius: 8,
    elevation: 1.5,
  },
  categoryCardBoxActive: {
    backgroundColor: '#EFF6FF',
    shadowColor: '#0066FF',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.12,
    shadowRadius: 8,
    elevation: 3,
  },
  categoryFullImage: {
    width: '100%',
    height: '100%',
  },
  categoryFallbackCenter: {
    width: '100%',
    height: '100%',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F8FAFC',
  },
  categoryLabel: {
    color: '#0F172A',
    fontSize: 12.5,
    fontWeight: '700',
    textAlign: 'center',
    lineHeight: 16,
    marginTop: 6,
    paddingHorizontal: 2,
    letterSpacing: -0.1,
  },
  categoryLabelActive: {
    color: '#0066FF',
    fontWeight: '800',
  },
  brandsScroll: {
    paddingHorizontal: 16,
    gap: 8,
  },
  brandPill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 15,
    paddingVertical: 9,
    borderRadius: 24,
    borderWidth: 0,
    borderColor: '#CBD5E1',
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 3,
    elevation: 2,
  },
  brandPillActive: {
    backgroundColor: '#0066FF',
    borderColor: '#0066FF',
    shadowColor: '#0066FF',
    shadowOpacity: 0.25,
  },
  brandNameText: {
    color: '#0F172A',
    fontSize: 14,
    fontWeight: '800',
    letterSpacing: 0.2,
  },
  brandNameTextActive: {
    color: '#FFFFFF',
    fontWeight: '900',
  },
  partsCountText: {
    color: '#64748B',
    fontSize: 12,
    fontWeight: '600',
  },
  partsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
    paddingHorizontal: 16,
  },
  partsGridColumnWrapper: {
    justifyContent: 'space-between',
    paddingHorizontal: 16,
  },
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 5,
    elevation: 2,
    height: 260,
  },
  imageContainer: {
    height: 128,
    backgroundColor: '#F8FAFC',
    position: 'relative',
  },
  cardImage: {
    width: '100%',
    height: '100%',
  },
  badgeContainer: {
    position: 'absolute',
    top: 8,
    left: 8,
    flexDirection: 'column',
    gap: 4,
    zIndex: 5,
  },
  badgeFeatured: {
    backgroundColor: '#FFCE32',
    paddingHorizontal: 7,
    paddingVertical: 2.5,
    borderRadius: 3,
  },
  badgeFeaturedText: {
    color: '#002F34',
    fontSize: 9.5,
    fontWeight: '900',
    letterSpacing: 0.5,
  },
  conditionBadge: {
    paddingHorizontal: 7,
    paddingVertical: 2.5,
    borderRadius: 5,
    borderWidth: 1,
  },
  badgeNew: {
    backgroundColor: '#ECFDF5',
    borderColor: '#A7F3D0',
  },
  badgeUsed: {
    backgroundColor: '#F1F5F9',
    borderColor: '#E2E8F0',
  },
  conditionText: {
    fontSize: 9.5,
    fontWeight: '800',
    letterSpacing: 0.3,
  },
  conditionTextNew: {
    color: '#16A34A',
  },
  conditionTextUsed: {
    color: '#475569',
  },
  favoriteButton: {
    position: 'absolute',
    top: 8,
    right: 8,
    zIndex: 10,
  },
  favoriteCircle: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: 'rgba(255, 255, 255, 0.95)',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 4,
    elevation: 4,
  },
  cardContent: {
    padding: 10,
    flex: 1,
    justifyContent: 'space-between',
  },
  priceRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 2,
  },
  price: {
    color: '#002F34',
    fontWeight: '900',
    fontSize: 17,
    lineHeight: 22,
    letterSpacing: -0.2,
  },
  verifiedTag: {
    marginLeft: 4,
  },
  partTitle: {
    color: '#0F172A',
    fontWeight: '500',
    fontSize: 13,
    lineHeight: 18,
    height: 36,
    minHeight: 36,
    marginBottom: 2,
  },
  categorySubText: {
    color: '#64748B',
    fontSize: 11,
    lineHeight: 15,
    height: 15,
    marginBottom: 4,
  },
  locationRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
    marginTop: 'auto',
  },
  locationText: {
    color: '#64748B',
    fontSize: 10.5,
    fontWeight: '600',
    letterSpacing: 0.2,
    maxWidth: 80,
  },
  distanceBullet: {
    color: '#94A3B8',
    fontSize: 10.5,
    marginHorizontal: 2,
  },
  distanceBadgeText: {
    color: '#64748B',
    fontSize: 10.5,
    fontWeight: '500',
    flex: 1,
  },
  loadingBox: {
    padding: 36,
    alignItems: 'center',
    justifyContent: 'center',
  },
  loadingText: {
    color: '#64748B',
    marginTop: 10,
    fontSize: 13,
  },
  emptyBox: {
    padding: 36,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptyTitle: {
    color: '#0F172A',
    fontWeight: 'bold',
    fontSize: 16,
    marginTop: 12,
  },
  emptySubtitle: {
    color: '#64748B',
    fontSize: 13,
    textAlign: 'center',
    marginTop: 6,
    marginBottom: 18,
    maxWidth: 260,
  },
  resetBtn: {
    backgroundColor: '#0066FF',
    borderRadius: 8,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  filterModalContainer: {
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    maxHeight: '80%',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
  },
  modalTitle: {
    color: '#0F172A',
    fontWeight: 'bold',
    fontSize: 16,
  },
  modalBody: {
    padding: 16,
  },
  filterLabel: {
    color: '#334155',
    fontWeight: '700',
    fontSize: 13,
    marginBottom: 8,
  },
  priceInputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  priceInput: {
    flex: 1,
    backgroundColor: '#F8FAFC',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    color: '#0F172A',
    borderWidth: 0,
    borderColor: '#E2E8F0',
  },
  modalPillWrap: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  modalPill: {
    backgroundColor: '#F1F5F9',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    borderWidth: 0,
    borderColor: '#E2E8F0',
  },
  modalPillActive: {
    backgroundColor: '#0066FF',
    borderColor: '#0066FF',
  },
  modalPillText: {
    color: '#475569',
    fontSize: 12,
  },
  modalPillTextActive: {
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  modalFooter: {
    flexDirection: 'row',
    padding: 16,
    gap: 12,
    borderTopWidth: 1,
    borderTopColor: '#E2E8F0',
  },
  modalClearBtn: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 10,
    borderWidth: 0,
    borderColor: '#CBD5E1',
    alignItems: 'center',
  },
  modalClearText: {
    color: '#64748B',
    fontWeight: '700',
  },
  modalApplyBtn: {
    flex: 2,
    backgroundColor: '#0066FF',
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: 'center',
  },
  modalApplyText: {
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  recentlyViewedCard: {
    width: 140,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    borderWidth: 0,
    borderColor: '#E2E8F0',
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  recentlyViewedImage: {
    width: '100%',
    height: 90,
    backgroundColor: '#F1F5F9',
  },
  recentlyViewedInfo: {
    padding: 8,
  },
  recentlyViewedTitle: {
    fontSize: 12,
    fontWeight: '700',
    color: '#0F172A',
  },
  recentlyViewedPrice: {
    fontSize: 13,
    fontWeight: '900',
    color: '#0066FF',
    marginTop: 2,
  },
});
