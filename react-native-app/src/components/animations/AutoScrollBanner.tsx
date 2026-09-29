import React, { useEffect, useRef, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Image,
  Animated,
  Dimensions,
} from 'react-native';
import MaterialCommunityIcons from 'react-native-vector-icons/MaterialCommunityIcons';

interface BannerItem {
  id: string;
  badge?: string;
  badgeColor?: string;
  headline1?: string;
  discount?: string;
  headline2?: string;
  features?: string[];
  cta?: string;
  targetCategory?: string;
  targetLink?: string;
  category?: string;
  imageUrl?: string;
  image?: string;
  photoURL?: string;
  backgroundColor?: string;
}

interface AutoScrollBannerProps {
  banners: BannerItem[];
  screenWidth?: number;
  onBannerPress: (item: BannerItem) => void;
  autoPlayInterval?: number;
}

const DEFAULT_WIDTH = Dimensions.get('window').width;

export const AutoScrollBanner: React.FC<AutoScrollBannerProps> = ({
  banners,
  screenWidth = DEFAULT_WIDTH,
  onBannerPress,
  autoPlayInterval = 4000,
}) => {
  const [activeIndex, setActiveIndex] = useState(0);
  const scrollRef = useRef<ScrollView>(null);
  const isInteracting = useRef(false);
  const cardWidth = Math.max(screenWidth - 32, 280);

  // Animated dot widths
  const dotAnimations = useRef(banners.map(() => new Animated.Value(0))).current;

  // Update animated dot indicators
  useEffect(() => {
    banners.forEach((_, idx) => {
      if (!dotAnimations[idx]) {
        dotAnimations[idx] = new Animated.Value(idx === activeIndex ? 1 : 0);
      }
      Animated.spring(dotAnimations[idx], {
        toValue: idx === activeIndex ? 1 : 0,
        friction: 7,
        tension: 50,
        useNativeDriver: false,
      }).start();
    });
  }, [activeIndex, banners.length]);

  // Auto scroll timer
  useEffect(() => {
    if (banners.length <= 1) return;

    const interval = setInterval(() => {
      if (isInteracting.current) return;
      setActiveIndex((prev) => {
        const next = (prev + 1) % banners.length;
        scrollRef.current?.scrollTo({ x: next * screenWidth, animated: true });
        return next;
      });
    }, autoPlayInterval);

    return () => clearInterval(interval);
  }, [banners.length, screenWidth, autoPlayInterval]);

  if (!banners || banners.length === 0) return null;

  return (
    <View style={styles.container}>
      <ScrollView
        ref={scrollRef}
        horizontal
        pagingEnabled
        snapToInterval={screenWidth}
        snapToAlignment="center"
        decelerationRate="fast"
        showsHorizontalScrollIndicator={false}
        scrollEventThrottle={16}
        nestedScrollEnabled={true}
        overScrollMode="never"
        keyboardShouldPersistTaps="handled"
        onScrollBeginDrag={() => { isInteracting.current = true; }}
        onScrollEndDrag={() => {
          setTimeout(() => { isInteracting.current = false; }, 2000);
        }}
        onMomentumScrollEnd={(e) => {
          const idx = Math.round(e.nativeEvent.contentOffset.x / screenWidth);
          if (idx >= 0 && idx < banners.length && idx !== activeIndex) {
            setActiveIndex(idx);
          }
        }}
        contentContainerStyle={{ alignItems: 'center' }}
      >
        {banners.map((item, idx) => {
          const badge = item.badge || 'MEGA DEALS';
          const head1 = item.headline1 || 'UP TO';
          const discount = item.discount || '50% OFF';
          const head2 = item.headline2 || 'GENUINE PARTS';
          const features = Array.isArray(item.features) && item.features.length > 0
            ? item.features
            : ['100% Genuine Parts', 'Best Price Guaranteed', 'Fast & Safe Delivery'];
          const cta = item.cta || 'SHOP NOW';
          const rawImgUri = item.imageUrl || item.image || item.photoURL;
          const imgUri = rawImgUri && typeof rawImgUri === 'string' && rawImgUri.trim().length > 5 && rawImgUri.startsWith('http')
            ? rawImgUri.trim()
            : null;

          return (
            <View
              key={item.id || `banner-page-${idx}`}
              style={{
                width: screenWidth,
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              {imgUri ? (
                <TouchableOpacity
                  activeOpacity={0.92}
                  onPress={() => onBannerPress(item)}
                  style={[styles.fullImageCard, { width: cardWidth }]}
                >
                  <Image 
                    source={{ uri: imgUri }} 
                    style={styles.fullImage} 
                    resizeMode="cover" 
                  />
                </TouchableOpacity>
              ) : (
                <TouchableOpacity
                  activeOpacity={0.92}
                  onPress={() => onBannerPress(item)}
                  style={[
                    styles.dealBanner,
                    { width: cardWidth },
                    item.backgroundColor ? { backgroundColor: item.backgroundColor } : null,
                  ]}
                >
                  <View style={styles.leftContent}>
                    <View style={[styles.badgePill, item.badgeColor ? { backgroundColor: item.badgeColor } : null]}>
                      <Text style={styles.badgeText}>{badge}</Text>
                    </View>
                    <Text style={styles.subHeadSmall}>{head1}</Text>
                    <Text style={styles.discountText}>{discount}</Text>
                    <Text style={styles.headlineText}>{head2}</Text>
                    <View style={styles.featureList}>
                      {features.slice(0, 3).map((feat, fIdx) => (
                        <View key={`feat-${fIdx}`} style={styles.featureItem}>
                          <MaterialCommunityIcons name="check-circle" size={12} color="#60A5FA" />
                          <Text style={styles.featureText} numberOfLines={1}>{feat}</Text>
                        </View>
                      ))}
                    </View>
                    <View style={styles.ctaBtn}>
                      <Text style={styles.ctaText}>{cta}</Text>
                      <MaterialCommunityIcons name="chevron-right" size={13} color="#051433" />
                    </View>
                  </View>

                  <View style={styles.rightArt}>
                    <View style={styles.glowCircle} />
                    <Image
                      source={require('../../assets/banner/hero_parts_collage.png')}
                      style={styles.artImage}
                      resizeMode="contain"
                    />
                  </View>
                </TouchableOpacity>
              )}
            </View>
          );
        })}
      </ScrollView>

      {/* Animated Pagination Dots */}
      {banners.length > 1 && (
        <View style={styles.dotsRow}>
          {banners.map((_, dotIdx) => {
            const anim = dotAnimations[dotIdx] || new Animated.Value(dotIdx === activeIndex ? 1 : 0);
            const dotWidth = anim.interpolate({
              inputRange: [0, 1],
              outputRange: [6, 20],
            });
            const dotColor = anim.interpolate({
              inputRange: [0, 1],
              outputRange: ['#CBD5E1', '#0066FF'],
            });

            return (
              <TouchableOpacity
                key={`dot-${dotIdx}`}
                onPress={() => {
                  setActiveIndex(dotIdx);
                  scrollRef.current?.scrollTo({ x: dotIdx * screenWidth, animated: true });
                }}
                hitSlop={{ top: 10, bottom: 10, left: 6, right: 6 }}
              >
                <Animated.View
                  style={[
                    styles.dotBase,
                    {
                      width: dotWidth,
                      backgroundColor: dotColor,
                    },
                  ]}
                />
              </TouchableOpacity>
            );
          })}
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    marginVertical: 10,
    width: '100%',
  },
  fullImageCard: {
    height: 156,
    borderRadius: 16,
    overflow: 'hidden',
    backgroundColor: '#1E293B',
  },
  fullImage: {
    width: '100%',
    height: '100%',
  },
  dealBanner: {
    height: 156,
    borderRadius: 16,
    backgroundColor: '#0A192F',
    flexDirection: 'row',
    overflow: 'hidden',
    padding: 14,
    borderWidth: 1,
    borderColor: '#1E3A8A',
  },
  leftContent: {
    flex: 1,
    justifyContent: 'center',
    paddingRight: 8,
    zIndex: 2,
  },
  badgePill: {
    backgroundColor: '#2563EB',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 6,
    alignSelf: 'flex-start',
    marginBottom: 4,
  },
  badgeText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  subHeadSmall: {
    color: '#94A3B8',
    fontSize: 11,
    fontWeight: '700',
    textTransform: 'uppercase',
  },
  discountText: {
    color: '#60A5FA',
    fontSize: 20,
    fontWeight: '900',
    letterSpacing: -0.5,
    marginVertical: -1,
  },
  headlineText: {
    color: '#FFFFFF',
    fontSize: 12.5,
    fontWeight: '800',
    marginBottom: 6,
  },
  featureList: {
    marginBottom: 6,
  },
  featureItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 2,
  },
  featureText: {
    color: '#CBD5E1',
    fontSize: 11.5,
    fontWeight: '500',
    marginLeft: 4,
  },
  ctaBtn: {
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 12,
    paddingVertical: 5,
    borderRadius: 20,
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    elevation: 2,
  },
  ctaText: {
    color: '#051433',
    fontSize: 11.5,
    fontWeight: '800',
    marginRight: 2,
  },
  rightArt: {
    width: 100,
    justifyContent: 'center',
    alignItems: 'center',
    position: 'relative',
  },
  glowCircle: {
    position: 'absolute',
    width: 90,
    height: 90,
    borderRadius: 45,
    backgroundColor: 'rgba(37, 99, 235, 0.25)',
  },
  artImage: {
    width: 95,
    height: 95,
  },
  dotsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 8,
    gap: 6,
  },
  dotBase: {
    height: 6,
    borderRadius: 3,
  },
});
