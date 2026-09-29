import React, { useState, useEffect, useRef } from 'react';
import { View, ScrollView, StyleSheet, Alert, Linking, Image, Share, TouchableOpacity, ActivityIndicator, Animated, Platform } from "react-native";
import { Text, Button, Card, Avatar, Divider, Chip, IconButton, Icon, useTheme } from 'react-native-paper';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import GMap from '../components/GMap';
import { EditListingModal } from '../components/EditListingModal';
import { ImageGalleryModal } from '../components/ImageGalleryModal';
import { UserProfilePopupModal } from '../components/UserProfilePopupModal';
import { MakeOfferModal } from '../components/MakeOfferModal';
import { getFirebaseFirestore, getCurrentUser } from '../services/firebase';
import { useAuthStore } from '../store';
import { useFavorites } from '../services/favorites';
import { addRecentlyViewedPart } from '../services/recentlyViewed';
import { 
  getCurrentLocation, 
  formatLocationBadgeWithDistance, 
  openLocationInExternalMaps,
  LocationCoords 
} from '../services/location';
import { ProductDetailSkeleton } from '../components/SkeletonLoaders';
import { NativeButton } from '../components/NativeButton';
import { ScalePressable } from '../components/animations/ScalePressable';
import { shareProductListing } from '../utils/shareUtils';

export default function ProductDetailScreen({ route, navigation, user: initialUser }: any) {
  const insets = useSafeAreaInsets();
  const { part: initialPart, partId: routePartId } = route.params || {};
  const [part, setPart] = useState<any>(initialPart || null);
  const [loadingDoc, setLoadingDoc] = useState<boolean>(!initialPart && Boolean(routePartId));
  const [userCoords, setUserCoords] = useState<LocationCoords | null>(null);
  const [liveSellerPhoto, setLiveSellerPhoto] = useState<string | null>(null);
  const [isProductInfoExpanded, setIsProductInfoExpanded] = useState<boolean>(true);
  const [activeImageIndex, setActiveImageIndex] = useState<number>(0);

  useEffect(() => {
    const sellerId = part?.sellerId || part?.ownerId || part?.userId;
    if (!sellerId) return;

    let unsubSeller = () => {};
    try {
      const db = getFirebaseFirestore();
      if (db && typeof db.collection === 'function') {
        unsubSeller = db.collection('users').doc(sellerId).onSnapshot((docSnap: any) => {
          if (docSnap && docSnap.exists) {
            const uData = docSnap.data();
            if (uData?.photoURL || uData?.profilePhoto) {
              setLiveSellerPhoto(uData.photoURL || uData.profilePhoto);
            }
          }
        }, () => {});
      }
    } catch (_) {}

    return () => {
      try { unsubSeller(); } catch (_) {}
    };
  }, [part?.sellerId, part?.ownerId, part?.userId]);

  const [editModalVisible, setEditModalVisible] = useState(false);
  const [galleryVisible, setGalleryVisible] = useState(false);
  const [galleryIndex, setGalleryIndex] = useState(0);
  const [profilePopupVisible, setProfilePopupVisible] = useState(false);
  const [profileViewerVisible, setProfileViewerVisible] = useState(false);
  const [showOfferModal, setShowOfferModal] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const authUser = useAuthStore((state) => state.user);
  const user = initialUser || authUser || getCurrentUser();
  const currentActiveUid = user?.uid || user?.id || null;
  const { favorites, toggleFavorite } = useFavorites();
  const isFav = favorites.includes(part?.id);

  const handleOfferSubmitted = (offerPrice: number) => {
    setShowOfferModal(false);
    const sellerId = part?.sellerId || part?.ownerId || part?.userId || 'seller';
    const sellerName = part?.contactName || part?.sellerName || 'Verified Seller';
    const sellerPhoto = liveSellerPhoto || part?.sellerPhotoURL || part?.sellerPhoto || part?.sellerAvatar || part?.photoURL || null;
    const currentUid = user?.uid || user?.id || 'guest';
    const currentName = user?.displayName || user?.name || user?.email?.split('@')[0] || 'Buyer';
    const chatId = `${currentUid}_${sellerId}_${part?.id || 'item'}`;

    navigation.navigate('ChatRoom', {
      chatId,
      part: {
        id: part?.id,
        title: part?.title || 'Spare Part',
        imageUrl: part?.imageUrl || (part?.imageUrls && part?.imageUrls[0]) || '',
        price: Number(part?.price) || 0,
        sellerId,
        sellerName,
        contactPhone: part?.contactPhone || '',
      },
      partnerId: sellerId,
      partnerName: sellerName,
      partnerPhoto: sellerPhoto,
      initialOfferPrice: offerPrice,
      chat: {
        id: chatId,
        partId: part?.id || '',
        partTitle: part?.title || 'Spare Part',
        partImageUrl: part?.imageUrl || (part?.imageUrls && part?.imageUrls[0]) || '',
        partPrice: Number(part?.price) || 0,
        buyerId: currentUid,
        buyerName: currentName,
        sellerId,
        sellerName,
      },
    });
  };

  // Parallax Scroll Animation Value
  const scrollY = useRef(new Animated.Value(0)).current;

  // Parallax Image: Moves up at 1/2 speed (0.55x) when scrolling down, and expands/zooms on pull down (<0)
  const imageTranslateY = scrollY.interpolate({
    inputRange: [-300, 0, 300],
    outputRange: [0, 0, 150],
    extrapolate: 'clamp',
  });

  const imageScale = scrollY.interpolate({
    inputRange: [-200, 0],
    outputRange: [1.4, 1],
    extrapolateRight: 'clamp',
  });

  // Sticky Mini Top Bar Animation (Fades in when scrolled past image)
  const stickyHeaderOpacity = scrollY.interpolate({
    inputRange: [200, 270],
    outputRange: [0, 1],
    extrapolate: 'clamp',
  });

  const stickyHeaderTranslateY = scrollY.interpolate({
    inputRange: [200, 270],
    outputRange: [-20, 0],
    extrapolate: 'clamp',
  });

  // Fetch device GPS coords for real distance calculation
  useEffect(() => {
    getCurrentLocation().then((coords) => {
      if (coords) setUserCoords(coords);
    });
  }, []);

  // Increment view counter once per session
  const hasIncrementedViewRef = useRef<boolean>(false);
  useEffect(() => {
    const targetId = initialPart?.id || routePartId;
    if (!targetId || hasIncrementedViewRef.current) return;
    hasIncrementedViewRef.current = true;
    try {
      const db = getFirebaseFirestore();
      if (db && typeof db.collection === 'function') {
        const docRef = db.collection('spareParts').doc(targetId);
        docRef.get().then((docSnap: any) => {
          if (docSnap && (typeof docSnap.exists === 'function' ? docSnap.exists() : Boolean(docSnap.exists))) {
            const currentViews = docSnap.data()?.views || docSnap.data()?.viewCount || 0;
            docRef.update({
              views: currentViews + 1,
              viewCount: currentViews + 1,
              lastViewedAt: Date.now(),
            }).catch(() => {});
          }
        }).catch(() => {});
      }
    } catch (_) {}
  }, [initialPart?.id, routePartId]);

  useEffect(() => {
    const targetId = initialPart?.id || routePartId;
    if (!targetId) {
      setLoadingDoc(false);
      return;
    }

    if (initialPart) {
      setPart(initialPart);
      addRecentlyViewedPart(initialPart, currentActiveUid || undefined);
    }

    let unsub = () => {};
    try {
      const db = getFirebaseFirestore();
      if (db && typeof db.collection === 'function') {
        unsub = db.collection('spareParts').doc(targetId).onSnapshot((docSnap: any) => {
          const isExisting = typeof docSnap?.exists === 'function' ? docSnap.exists() : Boolean(docSnap?.exists);
          if (isExisting) {
            const data = { id: docSnap.id, ...docSnap.data() };
            setPart(data);
            addRecentlyViewedPart(data, currentActiveUid || undefined);
          }
          setLoadingDoc(false);
        }, (err: any) => {
          console.warn('[ProductDetailScreen] Realtime sync error:', err);
          setLoadingDoc(false);
        });
      } else {
        setLoadingDoc(false);
      }
    } catch (e) {
      console.warn('[ProductDetailScreen] Realtime sync setup error:', e);
      setLoadingDoc(false);
    }
    return () => {
      try { unsub(); } catch (_) {}
    };
  }, [initialPart?.id, routePartId, currentActiveUid]);

  const [relatedParts, setRelatedParts] = useState<any[]>([]);
  const [loadingRelated, setLoadingRelated] = useState<boolean>(false);

  useEffect(() => {
    if (!part?.id) return;

    const brand = (part.carBrand || part.brand || '').trim();
    const model = (part.carModel || part.model || '').trim();
    const category = (part.category || '').trim();

    let isMounted = true;
    setLoadingRelated(true);

    const fetchRelated = async () => {
      try {
        const db = getFirebaseFirestore();
        let partsList: any[] = [];

        if (db && typeof db.collection === 'function') {
          const snap = await db.collection('spareParts').get();
          if (snap && !snap.empty) {
            snap.forEach((doc: any) => {
              partsList.push({ id: doc.id, ...doc.data() });
            });
          }
        }

        // Score based on car compatibility & category
        const scored = partsList
          .filter((p) => p.id !== part.id && !p.isDeleted && p.status !== 'deleted')
          .map((p) => {
            let score = 0;
            const pBrand = (p.carBrand || p.brand || '').toLowerCase();
            const pModel = (p.carModel || p.model || '').toLowerCase();
            const pCat = (p.category || '').toLowerCase();

            // Direct model match (e.g. Swift with Swift)
            if (model && pModel && (pModel.includes(model.toLowerCase()) || model.toLowerCase().includes(pModel))) {
              score += 20;
            }
            // Brand match (e.g. Maruti with Maruti, Hyundai with Hyundai)
            if (brand && pBrand && (pBrand.includes(brand.toLowerCase()) || brand.toLowerCase().includes(pBrand))) {
              score += 10;
            }
            // Category match (e.g. Electricals, Engine, Brakes)
            if (category && pCat && (pCat.includes(category.toLowerCase()) || category.toLowerCase().includes(pCat))) {
              score += 6;
            }

            return { part: p, score };
          })
          .filter((item) => item.score > 0)
          .sort((a, b) => b.score - a.score)
          .slice(0, 10)
          .map((item) => item.part);

        if (isMounted) {
          setRelatedParts(scored);
          setLoadingRelated(false);
        }
      } catch (e) {
        console.warn('[ProductDetail] Error fetching related parts:', e);
        if (isMounted) setLoadingRelated(false);
      }
    };

    fetchRelated();

    return () => {
      isMounted = false;
    };
  }, [part?.id, part?.carBrand, part?.brand, part?.carModel, part?.model, part?.category]);

  if (loadingDoc) {
    return (
      <View style={[styles.errorContainer, { backgroundColor: '#FFFFFF' }]}>
        <ActivityIndicator size="large" color="#0066FF" />
        <Text variant="bodyMedium" style={{ marginTop: 12, color: '#64748B' }}>
          Loading part details...
        </Text>
      </View>
    );
  }

  if (!part) {
    return (
      <View style={styles.errorContainer}>
        <Text variant="titleMedium">Spare part details not available.</Text>
        <Button mode="contained" onPress={() => navigation.goBack()} style={{ marginTop: 16 }}>
          Go Back
        </Button>
      </View>
    );
  }

  // Determine ownership using the authenticated user's ID/UID and listing's owner/seller ID
  const currentUserId = user?.uid || user?.id || null;
  const listingOwnerId = part.ownerId || part.sellerId || part.userId || null;
  const isOwner = Boolean(currentUserId && listingOwnerId && String(currentUserId) === String(listingOwnerId));
  const sellerName = part.contactName || part.sellerName || 'Verified Seller';

  const handleOpenSellerProfile = () => {
    setProfilePopupVisible(false);
    const sId = part.sellerId || part.userId || part.ownerId || 'seller';
    const sName = part.contactName || part.sellerName || 'Automotive Seller';
    const sLoc = part.location || part.district || part.state || 'India';
    const sPhoto = liveSellerPhoto || part.sellerPhotoURL || part.sellerPhoto || part.sellerAvatar || part.photoURL || null;
    navigation.navigate('SellerProfile', {
      seller: {
        id: sId,
        sellerId: sId,
        name: sName,
        sellerName: sName,
        location: sLoc,
        photoURL: sPhoto,
        profilePhoto: sPhoto,
        phone: part.contactPhone || part.phone,
      },
      sellerId: sId,
      sellerName: sName,
    });
  };

  const distanceInfo = formatLocationBadgeWithDistance(part, userCoords);

  const handleCall = () => {
    if (part.contactPhone) {
      // Directly launch phone dialer immediately for fast response
      Linking.openURL(`tel:${part.contactPhone}`).catch(() => {
        Alert.alert('Error', 'Unable to open phone dialer.');
      });
    } else {
      Alert.alert('Contact', 'Phone number not listed for this seller.');
    }
  };

  const handleChat = () => {
    if (!user) {
      navigation.navigate('Auth');
      return;
    }
    const currentUid = user.uid || user.id;
    const sellerUid = part.sellerId || part.userId || part.ownerId || 'seller';
    const currentName = user.displayName || user.name || user.email?.split('@')[0] || 'Buyer';
    const sellerName = part.contactName || part.sellerName || 'Verified Seller';
    const chatId = `${currentUid}_${sellerUid}_${part.id}`;
    
    // Navigate immediately (Optimistic UI - Zero lag)
    navigation.navigate('ChatRoom', { 
      chatId, 
      part: {
        id: part.id,
        title: part.title || 'Spare Part',
        imageUrl: part.imageUrl || (part.imageUrls && part.imageUrls[0]) || '',
        price: Number(part.price) || 0,
        sellerId: sellerUid,
        sellerName: sellerName,
        contactPhone: part.contactPhone || ''
      },
      chat: {
        id: chatId,
        partId: part.id || '',
        partTitle: part.title || 'Spare Part',
        partImageUrl: part.imageUrl || (part.imageUrls && part.imageUrls[0]) || '',
        partPrice: Number(part.price) || 0,
        buyerId: currentUid,
        buyerName: currentName,
        sellerId: sellerUid,
        sellerName: sellerName,
      }
    });

    // Run firestore initialization silently in background without blocking screen transition
    try {
      const db = getFirebaseFirestore();
      if (db && typeof db.collection === 'function') {
        db.collection('chats').doc(chatId).set({
          id: chatId,
          partId: part.id || '',
          partTitle: part.title || 'Spare Part',
          partImageUrl: part.imageUrl || (part.imageUrls && part.imageUrls[0]) || '',
          partPrice: Number(part.price) || 0,
          buyerId: currentUid,
          buyerName: currentName,
          buyerPhoto: user.photoURL || '',
          sellerId: sellerUid,
          sellerName: sellerName,
          sellerPhoto: part.sellerPhoto || '',
          participants: [currentUid, sellerUid],
          lastMessageText: '',
          lastMessageAt: Date.now()
        }, { merge: true }).catch(() => {});
      }
    } catch (e) {
      console.warn('[ProductDetailScreen] Background chat init error:', e);
    }
  };

  const handleShare = async () => {
    if (!part) return;
    await shareProductListing({
      id: part.id,
      title: part.title || 'Spare Part',
      price: part.price,
      imageUrl: part.imageUrl,
      imageUrls: part.imageUrls,
      carBrand: part.carBrand || part.brand,
      carModel: part.carModel || part.model,
      location: part.location,
      district: part.district,
      state: part.state,
    });
  };

  const handleDelete = () => {
    Alert.alert(
      'Delete Listing',
      'Are you sure you want to permanently delete this listing? This action cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              setIsDeleting(true);
              if (part.id) {
                const db = getFirebaseFirestore();
                if (db && typeof db.collection === 'function') {
                  await db.collection('spareParts').doc(part.id).delete();
                }
              }
              Alert.alert('Listing Deleted', 'Your spare part listing has been permanently deleted.');
              navigation.goBack();
            } catch (err: any) {
              console.warn('[ProductDetailScreen] Delete error:', err);
              Alert.alert('Error', err.message || 'Failed to delete listing. Please try again.');
            } finally {
              setIsDeleting(false);
            }
          },
        },
      ]
    );
  };

  // Format posted date cleanly (e.g. 06 Sep '26)
  const formatPostedDate = (timestamp: any) => {
    if (!timestamp) return "Recently";
    try {
      const date = typeof timestamp === 'number' ? new Date(timestamp) : timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
      if (isNaN(date.getTime())) return "Recently";
      return date.toLocaleDateString("en-GB", {
        day: "2-digit",
        month: "short",
        year: "2-digit",
      });
    } catch {
      return "Recently";
    }
  };

  if (loadingDoc || !part) {
    return (
      <View style={[styles.screenWrapper, { paddingTop: Math.max(insets.top, 12) }]}>
        <View style={{ flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16, paddingVertical: 10 }}>
          <ScalePressable 
            style={styles.stickyHeaderBackBtn} 
            onPress={() => navigation.goBack()}
            scaleTo={0.9}
          >
            <Icon source="arrow-left" size={20} color="#0F172A" />
          </ScalePressable>
        </View>
        <ProductDetailSkeleton />
      </View>
    );
  }

  const allImages = (part.imageUrls && part.imageUrls.length > 0)
    ? part.imageUrls
    : (part.images && part.images.length > 0)
    ? part.images
    : [part.imageUrl || 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&q=80&w=800'];

  const partLat = part.latitude || part.lat;
  const partLng = part.longitude || part.lng;

  return (
    <View style={styles.screenWrapper}>
      {/* ANIMATED STICKY HEADER BAR (Appears smoothly when scrolled past image) */}
      <Animated.View 
        style={[
          styles.stickyHeaderBar, 
          { 
            paddingTop: Math.max(insets.top, 10),
            opacity: stickyHeaderOpacity,
            transform: [{ translateY: stickyHeaderTranslateY }],
          }
        ]}
        pointerEvents="box-none"
      >
        <ScalePressable 
          style={styles.stickyHeaderBackBtn} 
          onPress={() => navigation.goBack()}
          scaleTo={0.9}
        >
          <Icon source="arrow-left" size={20} color="#0F172A" />
        </ScalePressable>

        <View style={styles.stickyHeaderTitleCol}>
          <Text numberOfLines={1} style={styles.stickyHeaderTitle}>{part.title}</Text>
          <Text numberOfLines={1} style={styles.stickyHeaderPrice}>₹ {part.price ? Number(part.price).toLocaleString('en-IN') : '0'}</Text>
        </View>

        <ScalePressable 
          style={styles.stickyHeaderShareBtn} 
          onPress={handleShare}
          scaleTo={0.9}
        >
          <Icon source="share-variant-outline" size={20} color="#0F172A" />
        </ScalePressable>
      </Animated.View>

      <Animated.ScrollView 
        style={styles.container}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
        scrollEventThrottle={16}
        bounces={true}
        alwaysBounceVertical={true}
        overScrollMode="never"
        decelerationRate="normal"
        keyboardDismissMode="on-drag"
        keyboardShouldPersistTaps="handled"
        onScroll={Animated.event(
          [{ nativeEvent: { contentOffset: { y: scrollY } } }],
          { useNativeDriver: true }
        )}
      >
        {/* TOP IMAGE SLIDER WITH PARALLAX & RUBBER-BAND ZOOM */}
        <View style={styles.imageHeader}>
          <Animated.View 
            style={[
              StyleSheet.absoluteFillObject,
              {
                transform: [
                  { translateY: imageTranslateY },
                  { scale: imageScale }
                ]
              }
            ]}
          >
            <TouchableOpacity
              activeOpacity={0.92}
              onPress={() => {
                setGalleryIndex(activeImageIndex);
                setGalleryVisible(true);
              }}
              style={{ width: '100%', height: '100%' }}
            >
              <Image 
                source={{ uri: allImages[activeImageIndex] || allImages[0] }} 
                style={styles.image} 
              />
            </TouchableOpacity>
          </Animated.View>

          {/* Floating Back Button */}
          <ScalePressable 
            style={[styles.floatingCircleBtn, { left: 16, top: Math.max(insets.top + 8, 16) }]} 
            onPress={() => navigation.goBack()}
            scaleTo={0.9}
          >
            <Icon source="arrow-left" size={20} color="#0F172A" />
          </ScalePressable>

          {/* Floating Share Button */}
          <ScalePressable 
            style={[styles.floatingCircleBtn, { right: 16, top: Math.max(insets.top + 8, 16) }]} 
            onPress={handleShare}
            scaleTo={0.9}
          >
            <Icon source="share-variant-outline" size={20} color="#0F172A" />
          </ScalePressable>

          {/* Photo Count Badge (e.g. 1/3) */}
          <View style={styles.photoCountBadge}>
            <Icon source="camera-outline" size={13} color="#FFFFFF" />
            <Text style={styles.photoCountText}>
              {activeImageIndex + 1}/{allImages.length}
            </Text>
          </View>

          {/* Sold Out Banner on Image */}
          {(part.sold === true || part.status === 'sold') && (
            <View style={{
              position: 'absolute',
              top: 70,
              left: 0,
              right: 0,
              backgroundColor: 'rgba(239, 68, 68, 0.92)',
              paddingVertical: 8,
              alignItems: 'center',
              zIndex: 15,
            }}>
              <Text style={{ color: '#FFFFFF', fontWeight: '800', fontSize: 14, letterSpacing: 1.5 }}>
                ITEM SOLD OUT
              </Text>
            </View>
          )}

          {/* Dots Indicator if multiple images */}
          {allImages.length > 1 && (
            <View style={styles.dotsRow}>
              {allImages.map((_: any, idx: number) => (
                <TouchableOpacity 
                  key={idx} 
                  onPress={() => setActiveImageIndex(idx)}
                  style={[styles.dot, activeImageIndex === idx ? styles.activeDot : null]}
                />
              ))}
            </View>
          )}
        </View>

        {/* MAIN AD CARD (Elevated with Curved Top) */}
        <View style={styles.mainAdCard}>
          {/* Wishlist Heart Button Row */}
          <View style={styles.topBadgeRow}>
            <View style={{ flex: 1 }} />
            <TouchableOpacity 
              style={[styles.wishlistBox, isFav && styles.wishlistBoxActive]} 
              onPress={() => toggleFavorite(part.id)}
              activeOpacity={0.8}
            >
              <Icon source={isFav ? "cards-heart" : "heart-outline"} size={22} color={isFav ? "#EF4444" : "#475569"} />
            </TouchableOpacity>
          </View>

          {/* Title & Car Details */}
          <Text style={styles.adTitle}>{part.title}</Text>
          <Text style={styles.adSubtitle}>
            {[part.carBrand, part.carModel, part.carVariant, part.carYear].filter(Boolean).join(' | ')}
          </Text>

          {/* Price & Posted Date Row */}
          <View style={styles.priceDateRow}>
            <View>
              <Text style={styles.priceText}>₹ {part.price ? Number(part.price).toLocaleString('en-IN') : '0'}</Text>
            </View>
            <View style={styles.postedOnWrapper}>
              <Text style={styles.postedOnLabel}>Posted On</Text>
              <Text style={styles.postedOnValue}>{formatPostedDate(part.createdAt)}</Text>
            </View>
          </View>

          {/* Location Row */}
          <View style={styles.locationRow}>
            <Icon source="map-marker-outline" size={16} color="#475569" />
            <Text style={styles.locationText} numberOfLines={1}>
              {part.district || part.location || 'India'}{part.state ? `, ${part.state}` : ''}
              {distanceInfo.distanceText ? ` • ${distanceInfo.distanceText}` : ''}
            </Text>
          </View>
        </View>

        {/* KEY HIGHLIGHTS (2x2 Grid with Clean Rounded Boxes & Round Icons) */}
        <View style={styles.highlightsContainer}>
          <Text style={styles.sectionHeaderTitle}>Key Highlights</Text>
          <View style={styles.highlightsGrid}>
            {/* Box 1: Condition */}
            <View style={styles.highlightBox}>
              <View style={styles.highlightTextCol}>
                <Text style={styles.highlightLabel}>Condition</Text>
                <Text style={styles.highlightValue} numberOfLines={1}>
                  {part.condition || 'Used - Good'}
                </Text>
              </View>
              <View style={styles.highlightIconCircle}>
                <Icon source="tag-outline" size={18} color="#0D9488" />
              </View>
            </View>

            {/* Box 2: Category */}
            <View style={styles.highlightBox}>
              <View style={styles.highlightTextCol}>
                <Text style={styles.highlightLabel}>Category</Text>
                <Text style={styles.highlightValue} numberOfLines={1}>
                  {part.category || 'Auto Part'}
                </Text>
              </View>
              <View style={styles.highlightIconCircle}>
                <Icon source="cog-outline" size={18} color="#0284C7" />
              </View>
            </View>

            {/* Box 3: Car Brand / Model */}
            <View style={styles.highlightBox}>
              <View style={styles.highlightTextCol}>
                <Text style={styles.highlightLabel}>Fitment Brand</Text>
                <Text style={styles.highlightValue} numberOfLines={1}>
                  {part.carBrand || 'Universal'}
                </Text>
              </View>
              <View style={styles.highlightIconCircle}>
                <Icon source="car-outline" size={18} color="#4F46E5" />
              </View>
            </View>

            {/* Box 4: Part Number / Type */}
            <View style={styles.highlightBox}>
              <View style={styles.highlightTextCol}>
                <Text style={styles.highlightLabel}>Part Type</Text>
                <Text style={styles.highlightValue} numberOfLines={1}>
                  {part.partNumber || 'Original OEM'}
                </Text>
              </View>
              <View style={styles.highlightIconCircle}>
                <Icon source="shield-check-outline" size={18} color="#16A34A" />
              </View>
            </View>
          </View>
        </View>

        {/* COLLAPSIBLE PRODUCT INFORMATION ACCORDION */}
        <View style={styles.accordionContainer}>
          <TouchableOpacity 
            style={styles.accordionHeader}
            onPress={() => setIsProductInfoExpanded(!isProductInfoExpanded)}
            activeOpacity={0.7}
          >
            <Text style={styles.accordionTitle}>Product Information</Text>
            <Icon source={isProductInfoExpanded ? "chevron-up" : "chevron-down"} size={22} color="#0F172A" />
          </TouchableOpacity>

          {isProductInfoExpanded && (
            <View style={styles.accordionBody}>
              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>Brand</Text>
                <Text style={styles.infoValue}>{part.carBrand || 'Universal'}</Text>
              </View>
              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>Car Model</Text>
                <Text style={styles.infoValue}>{part.carModel || 'All Models'}</Text>
              </View>
              {part.carVariant && (
                <View style={styles.infoRow}>
                  <Text style={styles.infoLabel}>Variant</Text>
                  <Text style={styles.infoValue}>{part.carVariant}</Text>
                </View>
              )}
              {part.fuelType && part.fuelType !== 'All / Any' && (
                <View style={styles.infoRow}>
                  <Text style={styles.infoLabel}>Fuel Type</Text>
                  <Text style={styles.infoValue}>{part.fuelType}</Text>
                </View>
              )}
              {part.carYear && (
                <View style={styles.infoRow}>
                  <Text style={styles.infoLabel}>Year</Text>
                  <Text style={styles.infoValue}>{part.carYear}</Text>
                </View>
              )}
              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>Condition</Text>
                <Text style={styles.infoValue}>{part.condition || 'Used'}</Text>
              </View>
              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>OEM Part Number</Text>
                <Text style={styles.infoValue}>{part.partNumber || 'OEM Standard'}</Text>
              </View>
              {part.warranty && (
                <View style={styles.infoRow}>
                  <Text style={styles.infoLabel}>Warranty</Text>
                  <Text style={styles.infoValue}>{part.warranty}</Text>
                </View>
              )}
            </View>
          )}
        </View>

        {/* DESCRIPTION SECTION */}
        <View style={styles.sectionContainer}>
          <Text style={styles.sectionHeaderTitle}>Description</Text>
          <Text style={styles.descriptionText}>
            {part.description || 'Verified auto spare part available for immediate purchase or pickup. Please contact the seller for further fitment details.'}
          </Text>
        </View>

        {/* SELLER INFORMATION CARD */}
        <View style={styles.sectionContainer}>
          <Text style={styles.sectionHeaderTitle}>Seller Information</Text>
          <Card style={styles.sellerCard}>
            <Card.Title
              title={part.contactName || part.sellerName || 'Verified Auto Parts Seller'}
              titleStyle={{ fontWeight: '700', fontSize: 15, color: '#0F172A' }}
              subtitle="Tap photo to inspect profile"
              subtitleStyle={{ fontSize: 11, color: '#64748B' }}
              left={(props) => {
                const sPhoto = liveSellerPhoto || part.sellerPhotoURL || part.sellerPhoto || part.sellerAvatar || part.photoURL;
                return (
                  <TouchableOpacity
                    activeOpacity={0.7}
                    onPress={() => setProfilePopupVisible(true)}
                  >
                    {sPhoto ? (
                      <Image
                        source={{ uri: sPhoto }}
                        style={{
                          width: 48,
                          height: 48,
                          borderRadius: 24,
                          borderWidth: 2,
                          borderColor: '#0066FF',
                        }}
                      />
                    ) : (
                      <Avatar.Icon {...props} icon="account" size={48} style={{ backgroundColor: "#0066FF" }} />
                    )}
                  </TouchableOpacity>
                );
              }}
              right={(props) => (
                <TouchableOpacity
                  activeOpacity={0.7}
                  style={{ flexDirection: 'row', alignItems: 'center', paddingRight: 8 }}
                  onPress={() => {
                    const sId = part.sellerId || part.userId || part.ownerId || 'seller';
                    const sName = part.contactName || part.sellerName || 'Automotive Seller';
                    const sLoc = part.location || part.district || part.state || 'India';
                    const sPhoto = liveSellerPhoto || part.sellerPhotoURL || part.sellerPhoto || part.sellerAvatar || part.photoURL || null;
                    navigation.navigate('SellerProfile', {
                      seller: {
                        id: sId,
                        sellerId: sId,
                        name: sName,
                        sellerName: sName,
                        location: sLoc,
                        photoURL: sPhoto,
                        profilePhoto: sPhoto,
                        phone: part.contactPhone || part.phone,
                      },
                      sellerId: sId,
                      sellerName: sName,
                    });
                  }}
                >
                  <Text style={{ fontSize: 12, color: '#0066FF', fontWeight: 'bold' }}>View Profile</Text>
                  <IconButton {...props} icon="chevron-right" iconColor="#0066FF" />
                </TouchableOpacity>
              )}
            />
          </Card>
        </View>

        {/* SELLER LOCATION & MAP */}
        <View style={styles.sectionContainer}>
          <View style={styles.mapSectionHeader}>
            <Text style={styles.sectionHeaderTitle}>Location & Map</Text>
            {partLat && partLng ? (
              <TouchableOpacity 
                style={styles.openNavBtn}
                onPress={() => openLocationInExternalMaps(partLat, partLng, part.title)}
              >
                <Icon source="directions" size={16} color="#0066FF" />
                <Text style={styles.openNavText}>Get Directions</Text>
              </TouchableOpacity>
            ) : null}
          </View>
          <GMap latitude={partLat} longitude={partLng} state={part.state} district={part.district || part.location} title={`${part.title} - ${part.location || 'India'}`} interactive={false} style={{ marginBottom: 8 }} height={140} />
        </View>

        {/* SIMILAR & RELATED PARTS */}
        {relatedParts.length > 0 && (
          <View style={styles.relatedSection}>
            <View style={styles.relatedHeaderRow}>
              <View style={{ flex: 1 }}>
                <View style={styles.relatedBadgeRow}>
                  <Icon source="auto-fix" size={14} color="#0066FF" />
                  <Text style={styles.relatedBadgeText}>RECOMMENDED FOR YOU</Text>
                </View>
                <Text style={styles.relatedSectionTitle}>Similar & Related Parts</Text>
                <Text style={styles.relatedSectionSubtitle}>
                  {part.carModel
                    ? `Other parts compatible with ${part.carBrand || ''} ${part.carModel}`
                    : `Related parts in ${part.category || 'this category'}`}
                </Text>
              </View>
              <View style={styles.relatedCountPill}>
                <Text style={styles.relatedCountText}>{relatedParts.length} Parts</Text>
              </View>
            </View>

            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              nestedScrollEnabled={true}
              scrollEventThrottle={16}
              overScrollMode="never"
              decelerationRate="normal"
              keyboardShouldPersistTaps="handled"
              contentContainerStyle={styles.relatedScrollContainer}
            >
              {relatedParts.map((item) => {
                const itemImg =
                  item.imageUrl ||
                  (item.imageUrls && item.imageUrls[0]) ||
                  (item.images && item.images[0]) ||
                  'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=400&q=80';
                const isNew = (item.condition || '').toLowerCase().includes('new');
                const itemPrice = Number(item.price || item.partPrice || 0);
                const itemLocation = item.city || item.location || item.district || 'India';

                return (
                  <TouchableOpacity
                    key={item.id}
                    style={styles.relatedCard}
                    activeOpacity={0.88}
                    onPress={() => {
                      if (navigation?.push) {
                        navigation.push('ProductDetail', { part: item, partId: item.id });
                      } else {
                        navigation.navigate('ProductDetail', { part: item, partId: item.id });
                      }
                    }}
                  >
                    <View style={styles.relatedCardImageWrapper}>
                      <Image source={{ uri: itemImg }} style={styles.relatedCardImage} />
                      <View
                        style={[
                          styles.relatedCardConditionBadge,
                          { backgroundColor: isNew ? '#10B981' : '#F59E0B' },
                        ]}
                      >
                        <Text style={styles.relatedCardConditionText}>
                          {isNew ? 'NEW' : 'USED'}
                        </Text>
                      </View>
                    </View>

                    <View style={styles.relatedCardBody}>
                      <Text numberOfLines={2} style={styles.relatedCardTitle}>
                        {item.title}
                      </Text>

                      <View style={styles.relatedCardCarRow}>
                        <Icon source="car" size={13} color="#64748B" />
                        <Text numberOfLines={1} style={styles.relatedCardCarText}>
                          {item.carBrand} {item.carModel || ''}
                        </Text>
                      </View>

                      <View style={styles.relatedCardLocRow}>
                        <Icon source="map-marker-outline" size={13} color="#64748B" />
                        <Text numberOfLines={1} style={styles.relatedCardLocText}>
                          {itemLocation}
                        </Text>
                      </View>

                      <View style={styles.relatedCardFooter}>
                        <Text style={styles.relatedCardPrice}>
                          ₹{itemPrice.toLocaleString('en-IN')}
                        </Text>
                        <View style={styles.relatedViewBtn}>
                          <Text style={styles.relatedViewBtnText}>View</Text>
                          <Icon source="chevron-right" size={14} color="#0066FF" />
                        </View>
                      </View>
                    </View>
                  </TouchableOpacity>
                );
              })}
            </ScrollView>
          </View>
        )}
      </Animated.ScrollView>

      {/* FIXED BOTTOM ACTION BAR (Clean Dual Button Layout from Screenshot) */}
      <View style={[styles.fixedBottomBar, { paddingBottom: Math.max(insets.bottom, 12) }]}>
        {isOwner ? (
          <View style={styles.actionRow}>
            <NativeButton 
              style={[styles.outlineActionBtn, { flex: 1 }]} 
              onPress={() => {
                navigation.navigate('EditListing', {
                  part,
                  onUpdated: (updatedPart: any) => {
                    setPart((prev: any) => ({ ...prev, ...updatedPart }));
                  },
                });
              }}
              disabled={isDeleting}
              hapticStyle="medium"
            >
              <Icon source="pencil-outline" size={18} color="#0066FF" />
              <Text style={styles.outlineActionBtnText}>Edit Ad</Text>
            </NativeButton>

            <NativeButton 
              style={[styles.solidActionBtn, { flex: 1, backgroundColor: '#EF4444' }]} 
              onPress={handleDelete}
              disabled={isDeleting}
              hapticStyle="heavy"
            >
              {isDeleting ? (
                <ActivityIndicator size="small" color="#FFFFFF" />
              ) : (
                <>
                  <Icon source="delete-outline" size={18} color="#FFFFFF" />
                  <Text style={styles.solidActionBtnText}>Delete Ad</Text>
                </>
              )}
            </NativeButton>
          </View>
        ) : (
          <View style={styles.actionRow}>
            {part.sold === true || part.status === 'sold' ? (
              <View style={[styles.solidActionBtn, { flex: 1, backgroundColor: '#EF4444', justifyContent: 'center' }]}>
                <Icon source="check-decagram" size={20} color="#FFFFFF" />
                <Text style={styles.solidActionBtnText}>SOLD OUT</Text>
              </View>
            ) : (
              <>
                {/* Make Offer Button */}
                <NativeButton 
                  style={[styles.offerActionBtn, { flex: 1 }]} 
                  onPress={() => setShowOfferModal(true)}
                  hapticStyle="medium"
                >
                  <Icon source="tag-text-outline" size={17} color="#D97706" />
                  <Text style={styles.offerActionBtnText}>Make Offer</Text>
                </NativeButton>

                {/* Outline Chat Button */}
                <NativeButton 
                  style={[styles.outlineActionBtn, { flex: 1 }]} 
                  onPress={handleChat}
                  hapticStyle="medium"
                >
                  <Icon source="message-text-outline" size={17} color="#0066FF" />
                  <Text style={styles.outlineActionBtnText}>Chat</Text>
                </NativeButton>

                {/* Solid Call Button */}
                <NativeButton 
                  style={[styles.solidActionBtn, { flex: 1 }]} 
                  onPress={handleCall}
                  hapticStyle="success"
                >
                  <Icon source="phone" size={17} color="#FFFFFF" />
                  <Text style={styles.solidActionBtnText}>Call</Text>
                </NativeButton>
              </>
            )}
          </View>
        )}
      </View>

      {/* Make Offer Modal */}
      <MakeOfferModal
        visible={showOfferModal}
        partTitle={part?.title || part?.partTitle}
        listedPrice={Number(part?.price || part?.partPrice || 0)}
        onClose={() => setShowOfferModal(false)}
        onSubmitOffer={handleOfferSubmitted}
      />

      {/* Modals */}
      {isOwner && (
        <EditListingModal
          visible={editModalVisible}
          onClose={() => setEditModalVisible(false)}
          listing={part}
          onSuccess={() => setEditModalVisible(false)}
        />
      )}

      <ImageGalleryModal
        visible={galleryVisible}
        onDismiss={() => setGalleryVisible(false)}
        part={part}
        images={allImages}
        initialIndex={galleryIndex}
        onChat={handleChat}
        onCall={handleCall}
        isOwner={isOwner}
      />

      <UserProfilePopupModal
        visible={profilePopupVisible}
        onDismiss={() => setProfilePopupVisible(false)}
        userPhoto={liveSellerPhoto || part.sellerPhotoURL || part.sellerPhoto || part.sellerAvatar || part.photoURL || null}
        userName={sellerName}
        userLocation={part.location || undefined}
        phone={part.sellerPhone || undefined}
        onChatPress={!isOwner ? handleChat : undefined}
        onViewProfilePress={handleOpenSellerProfile}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  screenWrapper: {
    flex: 1,
    backgroundColor: '#F8FAFC',
    position: 'relative',
  },
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  scrollContent: {
    paddingBottom: 110,
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },

  /* Animated Sticky Top Bar */
  stickyHeaderBar: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    height: 90,
    backgroundColor: '#FFFFFF',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingBottom: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 4,
    elevation: 8,
    zIndex: 100,
  },
  stickyHeaderBackBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#F1F5F9',
    alignItems: 'center',
    justifyContent: 'center',
  },
  stickyHeaderTitleCol: {
    flex: 1,
    marginHorizontal: 12,
    justifyContent: 'center',
  },
  stickyHeaderTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: '#0F172A',
  },
  stickyHeaderPrice: {
    fontSize: 13,
    fontWeight: '800',
    color: '#0066FF',
    marginTop: 1,
  },
  stickyHeaderShareBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#F1F5F9',
    alignItems: 'center',
    justifyContent: 'center',
  },

  /* Top Image Area */
  imageHeader: {
    position: 'relative',
    height: 320,
    backgroundColor: '#0F172A',
    overflow: 'hidden',
  },
  image: {
    width: '100%',
    height: '100%',
    resizeMode: 'cover',
  },
  floatingCircleBtn: {
    position: 'absolute',
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.18,
    shadowRadius: 4,
    elevation: 5,
    zIndex: 20,
  },
  photoCountBadge: {
    position: 'absolute',
    bottom: 28,
    right: 16,
    backgroundColor: 'rgba(15, 23, 42, 0.75)',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 14,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  photoCountText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '700',
  },
  dotsRow: {
    position: 'absolute',
    bottom: 30,
    left: 0,
    right: 0,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 6,
  },
  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: 'rgba(255, 255, 255, 0.5)',
  },
  activeDot: {
    width: 14,
    backgroundColor: '#FFFFFF',
  },

  /* Main Elevated Ad Card */
  mainAdCard: {
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    marginTop: -20,
    paddingHorizontal: 18,
    paddingTop: 18,
    paddingBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -3 },
    shadowOpacity: 0.05,
    shadowRadius: 12,
    elevation: 4,
  },
  topBadgeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  featuredBadge: {
    backgroundColor: '#FEF3C7',
    paddingHorizontal: 10,
    paddingVertical: 3.5,
    borderRadius: 6,
  },
  featuredBadgeText: {
    color: '#D97706',
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 0.6,
  },
  wishlistBox: {
    width: 44,
    height: 44,
    borderRadius: 12,
    backgroundColor: '#F1F5F9',
    alignItems: 'center',
    justifyContent: 'center',
  },
  wishlistBoxActive: {
    backgroundColor: '#FFF1F2',
  },
  adTitle: {
    fontSize: 20,
    fontWeight: '800',
    color: '#0F172A',
    lineHeight: 26,
    marginBottom: 4,
    paddingRight: 8,
  },
  adSubtitle: {
    fontSize: 13,
    color: '#64748B',
    fontWeight: '500',
    marginBottom: 12,
  },
  priceDateRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-between',
    marginBottom: 14,
    paddingBottom: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  priceText: {
    fontSize: 24,
    fontWeight: '900',
    color: '#0F172A',
    letterSpacing: -0.5,
  },
  postedOnWrapper: {
    alignItems: 'flex-end',
  },
  postedOnLabel: {
    fontSize: 11,
    color: '#94A3B8',
    fontWeight: '600',
    textTransform: 'uppercase',
  },
  postedOnValue: {
    fontSize: 13,
    color: '#475569',
    fontWeight: '700',
    marginTop: 1,
  },
  locationRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  locationText: {
    fontSize: 13,
    color: '#475569',
    fontWeight: '600',
    flex: 1,
  },

  /* Key Highlights (2x2 Grid) */
  highlightsContainer: {
    backgroundColor: '#FFFFFF',
    marginTop: 12,
    marginHorizontal: 12,
    borderRadius: 16,
    padding: 16,
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.04,
    shadowRadius: 10,
    elevation: 2,
  },
  sectionHeaderTitle: {
    fontSize: 15,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 12,
  },
  highlightsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  highlightBox: {
    width: '48.5%',
    backgroundColor: '#F8FAFC',
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 10,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  highlightTextCol: {
    flex: 1,
    paddingRight: 6,
  },
  highlightLabel: {
    fontSize: 11.5,
    color: '#64748B',
    fontWeight: '600',
  },
  highlightValue: {
    fontSize: 13,
    fontWeight: '700',
    color: '#0F172A',
    marginTop: 2,
  },
  highlightIconCircle: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
    justifyContent: 'center',
  },

  /* Accordion Container */
  accordionContainer: {
    backgroundColor: '#FFFFFF',
    marginTop: 12,
    marginHorizontal: 12,
    borderRadius: 16,
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.04,
    shadowRadius: 10,
    elevation: 2,
    overflow: 'hidden',
  },
  accordionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 14,
  },
  accordionTitle: {
    fontSize: 15,
    fontWeight: '800',
    color: '#0F172A',
  },
  accordionBody: {
    paddingHorizontal: 16,
    paddingBottom: 14,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 10,
    paddingHorizontal: 12,
    backgroundColor: '#F8FAFC',
    borderRadius: 10,
    marginBottom: 6,
  },
  infoLabel: {
    fontSize: 12.5,
    color: '#64748B',
    fontWeight: '600',
  },
  infoValue: {
    fontSize: 13,
    color: '#0F172A',
    fontWeight: '700',
    maxWidth: '65%',
    textAlign: 'right',
  },

  /* Sections */
  sectionContainer: {
    backgroundColor: '#FFFFFF',
    marginTop: 12,
    marginHorizontal: 12,
    borderRadius: 16,
    padding: 16,
    borderWidth: 0,
    borderColor: '#E2E8F0',
  },
  descriptionText: {
    fontSize: 14.5,
    color: '#475569',
    lineHeight: 23,
  },
  sellerCard: {
    backgroundColor: '#F8FAFC',
    borderWidth: 0,
    borderColor: '#E2E8F0',
    borderRadius: 12,
  },
  mapSectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  openNavBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#EFF6FF',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
    gap: 4,
  },
  openNavText: {
    color: '#0066FF',
    fontSize: 12,
    fontWeight: '700',
  },

  /* Safety Card */
  safetyCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#EFF6FF',
    borderWidth: 1,
    borderColor: '#DBEAFE',
    borderRadius: 14,
    marginHorizontal: 12,
    marginTop: 12,
    padding: 14,
  },
  safetyTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: '#0066FF',
  },
  safetyDesc: {
    fontSize: 12,
    color: '#475569',
    marginTop: 2,
    lineHeight: 17,
  },

  /* Related Section */
  relatedSection: {
    marginTop: 14,
    paddingHorizontal: 12,
    paddingTop: 16,
    paddingBottom: 20,
    backgroundColor: '#FFFFFF',
    borderTopWidth: 1,
    borderTopColor: '#E2E8F0',
  },
  relatedHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 14,
  },
  relatedBadgeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 2,
    gap: 4,
  },
  relatedBadgeText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#0066FF',
    letterSpacing: 0.8,
  },
  relatedSectionTitle: {
    fontSize: 17,
    fontWeight: '800',
    color: '#0F172A',
  },
  relatedSectionSubtitle: {
    fontSize: 12,
    color: '#64748B',
    marginTop: 2,
  },
  relatedCountPill: {
    backgroundColor: '#EFF6FF',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
    borderWidth: 0,
    borderColor: '#BFDBFE',
  },
  relatedCountText: {
    color: '#0066FF',
    fontSize: 12,
    fontWeight: '700',
  },
  relatedScrollContainer: {
    paddingRight: 12,
    gap: 12,
  },
  relatedCard: {
    width: 175,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    borderWidth: 0,
    borderColor: '#E2E8F0',
    overflow: 'hidden',
  },
  relatedCardImageWrapper: {
    position: 'relative',
    width: '100%',
    height: 115,
    backgroundColor: '#F1F5F9',
  },
  relatedCardImage: {
    width: '100%',
    height: '100%',
    resizeMode: 'cover',
  },
  relatedCardConditionBadge: {
    position: 'absolute',
    top: 6,
    left: 6,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  relatedCardConditionText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '700',
  },
  relatedCardBody: {
    padding: 8,
  },
  relatedCardTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: '#0F172A',
    lineHeight: 17,
    minHeight: 34,
  },
  relatedCardCarRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 4,
    gap: 4,
  },
  relatedCardCarText: {
    fontSize: 11.5,
    fontWeight: '600',
    color: '#475569',
    flex: 1,
  },
  relatedCardLocRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 2,
    gap: 4,
  },
  relatedCardLocText: {
    fontSize: 11.5,
    color: '#64748B',
    flex: 1,
  },
  relatedCardFooter: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 8,
    paddingTop: 6,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
  },
  relatedCardPrice: {
    fontSize: 14,
    fontWeight: '800',
    color: '#0066FF',
  },
  relatedViewBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#EFF6FF',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  relatedViewBtnText: {
    fontSize: 11.5,
    fontWeight: '700',
    color: '#0066FF',
  },

  /* Fixed Bottom Bar */
  fixedBottomBar: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 16,
    paddingTop: 10,
    borderTopWidth: 1,
    borderTopColor: '#E2E8F0',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -3 },
    shadowOpacity: 0.08,
    shadowRadius: 6,
    elevation: 12,
    zIndex: 99,
  },
  actionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  offerActionBtn: {
    height: 48,
    borderRadius: 12,
    borderWidth: 1.5,
    borderColor: '#F59E0B',
    backgroundColor: '#FEF3C7',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
  offerActionBtnText: {
    fontSize: 13.5,
    fontWeight: '800',
    color: '#B45309',
  },
  outlineActionBtn: {
    height: 48,
    borderRadius: 12,
    borderWidth: 1.5,
    borderColor: '#0066FF',
    backgroundColor: '#EFF6FF',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
  outlineActionBtnText: {
    fontSize: 14,
    fontWeight: '800',
    color: '#0066FF',
  },
  solidActionBtn: {
    height: 48,
    borderRadius: 12,
    backgroundColor: '#0066FF',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
  solidActionBtnText: {
    fontSize: 14,
    fontWeight: '800',
    color: '#FFFFFF',
  },
});
