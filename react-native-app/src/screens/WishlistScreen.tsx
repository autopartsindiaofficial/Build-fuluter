import React, { useState, useEffect } from 'react';
import { View, FlatList, StyleSheet, Image, TouchableOpacity, ActivityIndicator, StatusBar } from 'react-native';
import { Text, Icon } from 'react-native-paper';
import { getFirebaseFirestore, getCurrentUser } from '../services/firebase';
import useFavorites from '../services/favorites';
import { ScalePressable, SwipeableCard } from '../components/animations';
import { ListFeedSkeleton } from '../components/SkeletonLoaders';
import { FastImageOptimized } from '../components/FastImageOptimized';

export default function WishlistScreen({ navigation }: any) {
  const { favorites, toggleFavorite } = useFavorites();
  const [allParts, setAllParts] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;
    let unsubParts = () => {};
    try {
      const db = getFirebaseFirestore();
      if (db) {
        unsubParts = db.collection('spareParts')
          .onSnapshot((partsSnap: any) => {
            const items: any[] = [];
            partsSnap.forEach((docSnap: any) => {
              items.push({ id: docSnap.id, ...docSnap.data() });
            });
            if (isMounted) {
              setAllParts(items);
              setLoading(false);
            }
          }, () => {
            if (isMounted) setLoading(false);
          });
      } else {
        setLoading(false);
      }
    } catch (_) {
      if (isMounted) setLoading(false);
    }
    return () => {
      isMounted = false;
      unsubParts?.();
    };
  }, []);

  const savedParts = allParts.filter(p => favorites.includes(p.id) && !p.isDeleted && p.status !== 'deleted');

  const handleRemoveFavorite = async (partId: string) => {
    await toggleFavorite(partId);
  };

  if (loading) {
    return (
      <View style={styles.container}>
        <ListFeedSkeleton count={4} />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#0066FF" />
      <View style={styles.topHeaderBar}>
        <TouchableOpacity
          style={styles.headerBackBtn}
          onPress={() => navigation.goBack()}
          activeOpacity={0.7}
        >
          <Icon source="arrow-left" size={22} color="#FFFFFF" />
        </TouchableOpacity>
        <Text style={styles.topHeaderTitle}>Saved Parts</Text>
        <View style={styles.countBadge}>
          <Text style={styles.countBadgeText}>{savedParts.length}</Text>
        </View>
      </View>

      <FlatList
        data={savedParts}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
        scrollEventThrottle={16}
        bounces={true}
        alwaysBounceVertical={true}
        decelerationRate="normal"
        overScrollMode="never"
        removeClippedSubviews={Platform.OS === 'android'}
        initialNumToRender={8}
        maxToRenderPerBatch={10}
        windowSize={7}
        updateCellsBatchingPeriod={50}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <View style={styles.emptyIconCircle}>
              <Icon source="heart-outline" size={32} color="#64748B" />
            </View>
            <Text style={styles.emptyTitle}>No Saved Parts</Text>
            <Text style={styles.emptySubtitle}>Items you favorite will appear here.</Text>
            <TouchableOpacity style={styles.emptyActionBtn} onPress={() => navigation.navigate('MainTabs', { screen: 'HomeTab' })}>
              <Text style={styles.emptyActionBtnText}>Browse Marketplace</Text>
            </TouchableOpacity>
          </View>
        }
        renderItem={({ item }) => (
          <ScalePressable 
            style={styles.adCard}
            scaleTo={0.98}
            onPress={() => navigation.navigate('ProductDetail', { part: item, partId: item.id })}
          >
            <View style={styles.cardHeaderArea}>
              <View style={styles.imageWrapper}>
                {item.imageUrl || item.imageUrls?.[0] ? (
                  <FastImageOptimized 
                    uri={item.imageUrl || item.imageUrls?.[0]} 
                    style={styles.adImage}
                    resizeMode="cover"
                    width={200}
                    height={200}
                    quality={80}
                  />
                ) : (
                  <View style={styles.imagePlaceholder}>
                    <Icon source="camera-outline" size={24} color="#94A3B8" />
                  </View>
                )}
                {/* Favorite Heart Tag Overlay */}
                <TouchableOpacity
                  style={styles.heartOverlayBtn}
                  activeOpacity={0.8}
                  onPress={() => handleRemoveFavorite(item.id)}
                  hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                >
                  <Icon source="heart" size={16} color="#EF4444" />
                </TouchableOpacity>
              </View>

              <View style={styles.adInfoArea}>
                <View style={styles.brandAndConditionRow}>
                  <Text style={styles.adBrandTag} numberOfLines={1}>
                    {item.carBrand} {item.carModel || ''}
                  </Text>
                  <View style={[
                    styles.conditionPill,
                    (item.condition || '').toLowerCase().includes('new') ? styles.pillNew : styles.pillUsed
                  ]}>
                    <Text style={[
                      styles.conditionText,
                      (item.condition || '').toLowerCase().includes('new') ? styles.textNew : styles.textUsed
                    ]}>
                      {(item.condition || '').toLowerCase().includes('new') ? '✨ NEW' : 'USED'}
                    </Text>
                  </View>
                </View>

                <Text style={styles.adTitle} numberOfLines={2}>
                  {item.partName || item.title}
                </Text>

                <View style={styles.priceAndLocationRow}>
                  <Text style={styles.adPrice}>
                    ₹{Number(item.price || item.partPrice || 0).toLocaleString('en-IN')}
                  </Text>
                  <View style={styles.locationWrap}>
                    <Icon source="map-marker-outline" size={12} color="#64748B" />
                    <Text style={styles.locationText} numberOfLines={1}>
                      {item.district || item.state || 'India'}
                    </Text>
                  </View>
                </View>
              </View>
            </View>

            {/* Bottom Action Footer */}
            <View style={styles.cardActionsToolbar}>
              <TouchableOpacity 
                style={styles.viewDetailsBtn}
                activeOpacity={0.8}
                onPress={() => navigation.navigate('ProductDetail', { part: item, partId: item.id })}
              >
                <Text style={styles.viewDetailsText}>View Details</Text>
                <Icon source="chevron-right" size={16} color="#0066FF" />
              </TouchableOpacity>

              <TouchableOpacity 
                style={styles.actionBtnOutline}
                activeOpacity={0.8}
                onPress={() => handleRemoveFavorite(item.id)}
              >
                <Icon source="trash-can-outline" size={15} color="#DC2626" />
                <Text style={styles.actionBtnOutlineText}>Remove</Text>
              </TouchableOpacity>
            </View>
          </ScalePressable>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F8FAFC' },
  topHeaderBar: {
    height: 56,
    backgroundColor: '#0066FF',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    gap: 12,
  },
  headerBackBtn: {
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
  countBadge: {
    backgroundColor: 'rgba(255, 255, 255, 0.22)',
    paddingHorizontal: 10,
    paddingVertical: 3,
    borderRadius: 12,
  },
  countBadgeText: {
    fontSize: 12,
    fontWeight: '800',
    color: '#FFFFFF',
  },
  loadingContainer: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#F8FAFC' },
  listContent: { padding: 16 },
  adCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    marginBottom: 14,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 8,
    elevation: 3,
  },
  cardHeaderArea: { 
    flexDirection: 'row', 
    padding: 12, 
    gap: 12 
  },
  imageWrapper: { 
    width: 96, 
    height: 96, 
    borderRadius: 12, 
    overflow: 'hidden', 
    backgroundColor: '#F1F5F9',
    position: 'relative',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  adImage: { width: '100%', height: '100%', resizeMode: 'cover' },
  imagePlaceholder: { width: '100%', height: '100%', justifyContent: 'center', alignItems: 'center' },
  heartOverlayBtn: {
    position: 'absolute',
    top: 6,
    right: 6,
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: 'rgba(255, 255, 255, 0.92)',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 3,
    elevation: 3,
  },
  adInfoArea: { 
    flex: 1, 
    justifyContent: 'space-between' 
  },
  brandAndConditionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 6,
  },
  adBrandTag: { 
    fontSize: 12, 
    fontWeight: '800', 
    color: '#0066FF', 
    textTransform: 'uppercase', 
    letterSpacing: 0.3,
    flex: 1,
  },
  adTitle: { 
    fontSize: 14, 
    fontWeight: '700', 
    color: '#0F172A', 
    lineHeight: 19,
    marginVertical: 4,
  },
  priceAndLocationRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  adPrice: { 
    fontSize: 17, 
    fontWeight: '900', 
    color: '#002F34' 
  },
  conditionPill: { 
    paddingHorizontal: 7, 
    paddingVertical: 2, 
    borderRadius: 6 
  },
  pillNew: { backgroundColor: '#ECFDF5' },
  pillUsed: { backgroundColor: '#F1F5F9' },
  conditionText: { fontSize: 10.5, fontWeight: '800' },
  textNew: { color: '#16A34A' },
  textUsed: { color: '#475569' },
  locationWrap: { 
    flexDirection: 'row', 
    alignItems: 'center', 
    gap: 3 
  },
  locationText: { 
    fontSize: 12, 
    color: '#64748B', 
    fontWeight: '600' 
  },
  cardActionsToolbar: {
    flexDirection: 'row',
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
    paddingHorizontal: 14,
    paddingVertical: 9,
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#F8FAFC',
  },
  viewDetailsBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  viewDetailsText: {
    fontSize: 12.5,
    fontWeight: '700',
    color: '#0066FF',
  },
  actionBtnOutline: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
    backgroundColor: '#FEF2F2',
    borderWidth: 1,
    borderColor: '#FEE2E2',
  },
  actionBtnOutlineText: { 
    fontSize: 12, 
    fontWeight: '700', 
    color: '#DC2626' 
  },
  emptyContainer: { alignItems: 'center', justifyContent: 'center', paddingVertical: 80, paddingHorizontal: 20 },
  emptyIconCircle: { width: 64, height: 64, borderRadius: 32, backgroundColor: '#F1F5F9', justifyContent: 'center', alignItems: 'center', marginBottom: 16 },
  emptyTitle: { fontSize: 18, fontWeight: '700', color: '#0F172A', marginBottom: 6 },
  emptySubtitle: { fontSize: 13, color: '#475569', textAlign: 'center', marginBottom: 20 },
  emptyActionBtn: { backgroundColor: '#0066FF', paddingHorizontal: 20, paddingVertical: 12, borderRadius: 12 },
  emptyActionBtnText: { color: '#FFFFFF', fontSize: 14, fontWeight: '700' },
});
