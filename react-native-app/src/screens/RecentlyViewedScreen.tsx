import React, { useState, useEffect, useCallback } from 'react';
import { View, FlatList, StyleSheet, Image, TouchableOpacity, ActivityIndicator, Alert, StatusBar, Platform } from 'react-native';
import { Text, Icon } from 'react-native-paper';
import { getRecentlyViewedParts, clearRecentlyViewedParts, removeRecentlyViewedPart, subscribeRecentlyViewed } from '../services/recentlyViewed';
import { ListFeedSkeleton } from '../components/SkeletonLoaders';
import { ScalePressable } from '../components/animations/ScalePressable';

export default function RecentlyViewedScreen({ navigation }: any) {
  const [recentlyViewed, setRecentlyViewed] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const loadRecent = useCallback(async () => {
    try {
      const items = await getRecentlyViewedParts();
      setRecentlyViewed(items || []);
    } catch (e) {
      console.warn('[RecentlyViewedScreen] Load error:', e);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadRecent();
    const unsubFocus = navigation.addListener('focus', loadRecent);
    const unsubRecent = subscribeRecentlyViewed((items) => {
      setRecentlyViewed(items || []);
      setLoading(false);
    });
    return () => {
      unsubFocus();
      unsubRecent();
    };
  }, [navigation, loadRecent]);

  const handleClearHistory = () => {
    Alert.alert(
      'Clear History',
      'Are you sure you want to clear your recently viewed history?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Clear',
          style: 'destructive',
          onPress: async () => {
            await clearRecentlyViewedParts();
            setRecentlyViewed([]);
          },
        },
      ]
    );
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
        <Text style={styles.topHeaderTitle}>Recently Viewed</Text>
        {recentlyViewed.length > 0 && (
          <View style={styles.countBadge}>
            <Text style={styles.countBadgeText}>{recentlyViewed.length}</Text>
          </View>
        )}
      </View>

      <FlatList
        data={recentlyViewed}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContent}
        keyboardShouldPersistTaps="handled"
        keyboardDismissMode="on-drag"
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
              <Icon source="history" size={32} color="#64748B" />
            </View>
            <Text style={styles.emptyTitle}>No Recent Views</Text>
            <Text style={styles.emptySubtitle}>Parts you view will appear here so you can easily find them later.</Text>
            <TouchableOpacity style={styles.emptyActionBtn} onPress={() => navigation.navigate('MainTabs', { screen: 'HomeTab' })}>
              <Text style={styles.emptyActionBtnText}>Explore Parts</Text>
            </TouchableOpacity>
          </View>
        }
        renderItem={({ item }) => (
          <TouchableOpacity 
            style={styles.adCard}
            onPress={() => navigation.navigate('ProductDetail', { part: item, partId: item.id })}
          >
            <View style={styles.cardHeaderArea}>
              <View style={styles.imageWrapper}>
                {item.imageUrl || item.imageUrls?.[0] ? (
                  <Image source={{ uri: item.imageUrl || item.imageUrls?.[0] }} style={styles.adImage} />
                ) : (
                  <View style={styles.imagePlaceholder}>
                    <Icon source="camera-outline" size={24} color="#94A3B8" />
                  </View>
                )}
              </View>
              <View style={styles.adInfoArea}>
                <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <Text style={[styles.adBrandTag, { flex: 1 }]} numberOfLines={1}>
                    {item.carBrand} {item.carModel}
                  </Text>
                  <TouchableOpacity
                    onPress={async () => {
                      await removeRecentlyViewedPart(item.id);
                      setRecentlyViewed((prev) => prev.filter((p) => p.id !== item.id));
                    }}
                    hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                    style={{ paddingLeft: 6 }}
                  >
                    <Icon source="close-circle-outline" size={18} color="#94A3B8" />
                  </TouchableOpacity>
                </View>
                <Text style={styles.adTitle} numberOfLines={2}>
                  {item.partName || item.title}
                </Text>
                <View style={styles.metaRow}>
                  <Text style={styles.adPrice}>₹{item.price?.toLocaleString() || 'N/A'}</Text>
                  <View style={styles.conditionPill}>
                    <Text style={styles.conditionText}>{item.condition || 'Used'}</Text>
                  </View>
                </View>
                <View style={styles.subMetaRow}>
                  <View style={styles.locationWrap}>
                    <Icon source="map-marker-outline" size={12} color="#64748B" />
                    <Text style={styles.locationText} numberOfLines={1}>{item.district || item.state || 'India'}</Text>
                  </View>
                </View>
              </View>
            </View>
          </TouchableOpacity>
        )}
      />
      {recentlyViewed.length > 0 && (
        <View style={styles.bottomBar}>
          <TouchableOpacity style={styles.clearBtn} onPress={handleClearHistory}>
            <Icon source="delete-sweep-outline" size={18} color="#475569" />
            <Text style={styles.clearBtnText}>Clear History</Text>
          </TouchableOpacity>
        </View>
      )}
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
  loadingContainer: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  listContent: { padding: 16 },
  bottomBar: { padding: 16, backgroundColor: '#FFFFFF', borderTopWidth: 1, borderTopColor: '#E2E8F0', alignItems: 'center' },
  clearBtn: { flexDirection: 'row', alignItems: 'center', gap: 6, paddingVertical: 10, paddingHorizontal: 20, borderRadius: 10, backgroundColor: '#F1F5F9' },
  clearBtnText: { fontSize: 13, fontWeight: '700', color: '#475569' },
  adCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    marginBottom: 14,
    overflow: 'hidden',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.05,
    shadowRadius: 10,
    elevation: 3,
  },
  cardHeaderArea: { flexDirection: 'row', padding: 12, gap: 12 },
  imageWrapper: { width: 84, height: 84, borderRadius: 10, backgroundColor: '#F1F5F9', overflow: 'hidden' },
  adImage: { width: '100%', height: '100%' },
  imagePlaceholder: { width: '100%', height: '100%', alignItems: 'center', justifyContent: 'center' },
  adInfoArea: { flex: 1, justifyContent: 'space-between' },
  adBrandTag: { fontSize: 11, fontWeight: '700', color: '#0066FF', textTransform: 'uppercase' },
  adTitle: { fontSize: 13, fontWeight: '700', color: '#0F172A', marginTop: 2, lineHeight: 17 },
  metaRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 4 },
  adPrice: { fontSize: 15, fontWeight: '800', color: '#0F172A' },
  conditionPill: { backgroundColor: '#F1F5F9', paddingHorizontal: 7, paddingVertical: 3, borderRadius: 6 },
  conditionText: { fontSize: 11, fontWeight: '700', color: '#475569', textTransform: 'uppercase' },
  subMetaRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 4 },
  locationWrap: { flexDirection: 'row', alignItems: 'center', gap: 3, flex: 1 },
  locationText: { fontSize: 11, color: '#64748B', fontWeight: '500' },
  emptyContainer: { alignItems: 'center', justifyContent: 'center', paddingHorizontal: 28, paddingVertical: 60 },
  emptyIconCircle: { width: 80, height: 80, borderRadius: 40, backgroundColor: '#F1F5F9', alignItems: 'center', justifyContent: 'center', marginBottom: 16 },
  emptyTitle: { fontSize: 17, fontWeight: '800', color: '#0F172A', marginBottom: 6, textAlign: 'center' },
  emptySubtitle: { fontSize: 13, color: '#64748B', textAlign: 'center', lineHeight: 19, marginBottom: 20 },
  emptyActionBtn: { flexDirection: 'row', alignItems: 'center', gap: 6, backgroundColor: '#0066FF', paddingVertical: 11, paddingHorizontal: 20, borderRadius: 12 },
  emptyActionBtnText: { fontSize: 13, fontWeight: '700', color: '#FFFFFF' },
});
