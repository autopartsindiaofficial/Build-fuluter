import React, { useState, useRef, useEffect, useCallback } from 'react';
import {
  View,
  StyleSheet,
  useWindowDimensions,
  Dimensions,
  Platform,
  TouchableOpacity,
  TouchableWithoutFeedback,
  SafeAreaView,
  Modal,
  Image,
  Animated,
  PanResponder,
  StatusBar,
  FlatList,
  ScrollView,
  Share,
  BackHandler,
  ActivityIndicator,
} from 'react-native';
import { Text, Icon } from 'react-native-paper';
import { SparePart } from '../types';
import { Haptics } from '../utils/haptics';
import { useLanguage } from '../context/LanguageContext';

export interface ImageGalleryModalProps {
  visible: boolean;
  part: SparePart | null;
  images?: string[];
  initialIndex?: number;
  onDismiss: () => void;
  onChat?: () => void;
  onCall?: () => void;
  isOwner?: boolean;
}

interface ZoomableSlideProps {
  uri: string;
  isActive: boolean;
  onZoomChange: (zoomed: boolean) => void;
  onDismiss: () => void;
  width: number;
  height: number;
}

const ZoomableSlide: React.FC<ZoomableSlideProps> = ({
  uri,
  isActive,
  onZoomChange,
  onDismiss,
  width,
  height,
}) => {
  const [loaded, setLoaded] = useState(false);
  const [loadError, setLoadError] = useState(false);

  const scale = useRef(new Animated.Value(1)).current;
  const pan = useRef(new Animated.ValueXY({ x: 0, y: 0 })).current;

  const currentScale = useRef(1);
  const currentPan = useRef({ x: 0, y: 0 });

  const lastTapTime = useRef(0);
  const initialDistance = useRef(0);
  const initialScale = useRef(1);
  const initialPan = useRef({ x: 0, y: 0 });
  const isPinching = useRef(false);
  const isDraggingDown = useRef(false);

  // Reset loaded states when uri changes
  useEffect(() => {
    setLoaded(false);
    setLoadError(false);
  }, [uri]);

  useEffect(() => {
    const sListener = scale.addListener((v) => {
      currentScale.current = v.value;
    });
    const pListener = pan.addListener((v) => {
      currentPan.current = v;
    });

    return () => {
      scale.removeListener(sListener);
      pan.removeListener(pListener);
    };
  }, [scale, pan]);

  // Reset zoom when this slide becomes inactive
  useEffect(() => {
    if (!isActive && currentScale.current !== 1) {
      scale.setValue(1);
      pan.setValue({ x: 0, y: 0 });
      currentScale.current = 1;
      currentPan.current = { x: 0, y: 0 };
      onZoomChange(false);
    }
  }, [isActive, onZoomChange]);

  const resetZoom = useCallback(
    (animated = true) => {
      currentScale.current = 1;
      currentPan.current = { x: 0, y: 0 };
      onZoomChange(false);
      if (animated) {
        Animated.parallel([
          Animated.spring(scale, {
            toValue: 1,
            useNativeDriver: true,
            friction: 7,
            tension: 40,
          }),
          Animated.spring(pan, {
            toValue: { x: 0, y: 0 },
            useNativeDriver: true,
            friction: 7,
            tension: 40,
          }),
        ]).start();
      } else {
        scale.setValue(1);
        pan.setValue({ x: 0, y: 0 });
      }
    },
    [scale, pan, onZoomChange]
  );

  const handleDoubleTapPress = () => {
    const now = Date.now();
    const timeSinceLastTap = now - lastTapTime.current;
    if (timeSinceLastTap < 300) {
      lastTapTime.current = 0;
      Haptics.light();
      if (currentScale.current > 1.1) {
        resetZoom(true);
      } else {
        currentScale.current = 2.5;
        onZoomChange(true);
        Animated.parallel([
          Animated.spring(scale, {
            toValue: 2.5,
            useNativeDriver: true,
            friction: 6,
            tension: 40,
          }),
          Animated.spring(pan, {
            toValue: { x: 0, y: 0 },
            useNativeDriver: true,
            friction: 6,
          }),
        ]).start();
      }
    } else {
      lastTapTime.current = now;
    }
  };

  const panResponder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => false,
      onMoveShouldSetPanResponder: (_, gestureState) => {
        // If zoomed in or multi-touch, capture for zoom/pan
        if (currentScale.current > 1.05 || gestureState.numberActiveTouches > 1) {
          return true;
        }
        // At 1x: only capture if dragging down steeply (drag-to-dismiss)
        // Leave horizontal gestures free for FlatList paging
        if (
          gestureState.dy > 12 &&
          Math.abs(gestureState.dy) > Math.abs(gestureState.dx) * 1.6
        ) {
          return true;
        }
        return false;
      },
      onPanResponderTerminationRequest: () => currentScale.current <= 1.05,
      onPanResponderGrant: (evt) => {
        if (evt.nativeEvent.touches.length === 2) {
          isPinching.current = true;
          isDraggingDown.current = false;
          const [t1, t2] = evt.nativeEvent.touches;
          initialDistance.current = Math.hypot(t1.pageX - t2.pageX, t1.pageY - t2.pageY);
          initialScale.current = currentScale.current;
        } else {
          isPinching.current = false;
          initialPan.current = { ...currentPan.current };
          isDraggingDown.current = currentScale.current <= 1.05;
        }
      },
      onPanResponderMove: (evt, gestureState) => {
        // 1. Two-finger Pinch to Zoom
        if (evt.nativeEvent.touches.length === 2) {
          isPinching.current = true;
          const [t1, t2] = evt.nativeEvent.touches;
          const dist = Math.hypot(t1.pageX - t2.pageX, t1.pageY - t2.pageY);
          if (initialDistance.current > 0) {
            const ratio = dist / initialDistance.current;
            const newScale = Math.max(0.8, Math.min(4.5, initialScale.current * ratio));
            scale.setValue(newScale);
            if (newScale > 1.05) {
              onZoomChange(true);
            }
          }
          return;
        }

        // 2. Single-finger interaction
        if (!isPinching.current && evt.nativeEvent.touches.length === 1) {
          if (currentScale.current > 1.05) {
            // Pan while zoomed
            const nextX = initialPan.current.x + gestureState.dx;
            const nextY = initialPan.current.y + gestureState.dy;
            pan.setValue({ x: nextX, y: nextY });
          } else if (isDraggingDown.current && gestureState.dy > 0) {
            // Drag-to-dismiss downwards
            pan.setValue({
              x: gestureState.dx * 0.2,
              y: gestureState.dy,
            });
          }
        }
      },
      onPanResponderRelease: (_, gestureState) => {
        // Handling release while zoomed
        if (currentScale.current > 1.05) {
          const maxPanX = (width * (currentScale.current - 1)) / 2;
          const maxPanY = (height * (currentScale.current - 1)) / 2;

          let targetX = currentPan.current.x;
          let targetY = currentPan.current.y;

          if (targetX > maxPanX) targetX = maxPanX;
          if (targetX < -maxPanX) targetX = -maxPanX;
          if (targetY > maxPanY) targetY = maxPanY;
          if (targetY < -maxPanY) targetY = -maxPanY;

          let targetScale = currentScale.current;
          if (targetScale < 1) targetScale = 1;
          if (targetScale > 4) targetScale = 4;

          Animated.parallel([
            Animated.spring(scale, {
              toValue: targetScale,
              useNativeDriver: true,
              friction: 7,
              tension: 40,
            }),
            Animated.spring(pan, {
              toValue: { x: targetX, y: targetY },
              useNativeDriver: true,
              friction: 7,
              tension: 40,
            }),
          ]).start();
        } else {
          // At 1x: check if user dragged down to dismiss
          if (
            gestureState.dy > 120 ||
            (gestureState.dy > 60 && gestureState.vy > 0.8)
          ) {
            Haptics.medium();
            Animated.timing(pan.y, {
              toValue: height,
              duration: 200,
              useNativeDriver: true,
            }).start(() => {
              onDismiss();
            });
          } else {
            resetZoom(true);
          }
        }
      },
    })
  ).current;

  return (
    <View style={[styles.slideContainer, { width, height }]} {...panResponder.panHandlers}>
      <Animated.View
        style={[
          styles.imageTransformWrapper,
          { width, height },
          {
            transform: [
              { translateX: pan.x },
              { translateY: pan.y },
              { scale: scale },
            ],
          },
        ]}
      >
        <TouchableWithoutFeedback onPress={handleDoubleTapPress}>
          <View style={[styles.imageInnerContainer, { width, height }]}>
            <Image
              source={{ uri }}
              style={[
                styles.fullImage,
                {
                  width: width,
                  height: height * 0.72,
                },
              ]}
              resizeMode="contain"
              onLoad={() => {
                setLoaded(true);
                setLoadError(false);
              }}
              onError={() => {
                setLoadError(true);
                setLoaded(true);
              }}
            />

            {!loaded && !loadError && (
              <View style={styles.loadingContainer} pointerEvents="none">
                <ActivityIndicator size="large" color="#3B82F6" />
              </View>
            )}

            {loadError && (
              <View style={styles.errorContainer} pointerEvents="none">
                <Icon source="image-broken-variant" size={48} color="#94A3B8" />
                <Text style={styles.errorText}>Unable to load image</Text>
              </View>
            )}
          </View>
        </TouchableWithoutFeedback>
      </Animated.View>
    </View>
  );
};

export const ImageGalleryModal: React.FC<ImageGalleryModalProps> = ({
  visible,
  part,
  images: imagesProp,
  initialIndex = 0,
  onDismiss,
  onChat,
  onCall,
  isOwner = false,
}) => {
  const windowDims = useWindowDimensions();
  const screenWidth = windowDims.width > 0 ? windowDims.width : Dimensions.get('window').width;
  const screenHeight = windowDims.height > 0 ? windowDims.height : Dimensions.get('window').height;

  const { translateDynamic } = useLanguage();
  const [currentIndex, setCurrentIndex] = useState(initialIndex);
  const [isZoomed, setIsZoomed] = useState(false);
  const flatListRef = useRef<FlatList<string>>(null);

  // Extract clean list of unique image URLs from imagesProp or part fields
  const rawList: (string | undefined | null)[] = [];
  if (imagesProp && Array.isArray(imagesProp)) {
    rawList.push(...imagesProp);
  }
  if (part) {
    if (Array.isArray(part.images)) rawList.push(...part.images);
    if (Array.isArray(part.imageUrls)) rawList.push(...part.imageUrls);
    if (part.imageUrl) rawList.push(part.imageUrl);
    if ((part as any).image) rawList.push((part as any).image);
    if (Array.isArray((part as any).photos)) rawList.push(...(part as any).photos);
    if ((part as any).photo) rawList.push((part as any).photo);
  }

  const images: string[] = [];
  rawList.forEach((item) => {
    if (typeof item === 'string') {
      const trimmed = item.trim();
      if (trimmed && !images.includes(trimmed)) {
        images.push(trimmed);
      }
    }
  });

  if (images.length === 0) {
    images.push(
      'https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=800&auto=format&fit=crop&q=80'
    );
  }

  // Synchronize index on open
  useEffect(() => {
    if (visible) {
      const safeIndex = Math.min(Math.max(0, initialIndex), images.length - 1);
      setCurrentIndex(safeIndex);
      setIsZoomed(false);
      setTimeout(() => {
        try {
          flatListRef.current?.scrollToIndex({ index: safeIndex, animated: false });
        } catch (_) {
          flatListRef.current?.scrollToOffset({ offset: safeIndex * screenWidth, animated: false });
        }
      }, 50);
    }
  }, [visible, initialIndex, images.length, screenWidth]);

  // Handle Android hardware back press
  useEffect(() => {
    if (!visible) return;
    const backHandler = BackHandler.addEventListener('hardwareBackPress', () => {
      onDismiss();
      return true;
    });
    return () => backHandler.remove();
  }, [visible, onDismiss]);

  const handleShare = async () => {
    try {
      Haptics.light();
      const currentUri = images[currentIndex] || images[0];
      await Share.share({
        title: part?.title || 'Auto Part',
        message: `${part?.title || 'Spare Part'} - Check it out on AutoParts India!\n${currentUri}`,
      });
    } catch (_) {}
  };

  if (!visible) return null;

  return (
    <Modal
      visible={visible}
      transparent={false}
      animationType="fade"
      onRequestClose={onDismiss}
      statusBarTranslucent={true}
    >
      <StatusBar barStyle="light-content" backgroundColor="#050B14" />

      <View style={[styles.container, { width: screenWidth, height: screenHeight }]}>
        {/* TOP FLOATING NAVIGATION BAR */}
        <SafeAreaView style={styles.topSafeArea} pointerEvents="box-none">
          <View style={styles.topBar}>
            {/* Close Button */}
            <TouchableOpacity
              style={styles.iconCircleBtn}
              onPress={() => {
                Haptics.light();
                onDismiss();
              }}
              activeOpacity={0.7}
              hitSlop={{ top: 15, bottom: 15, left: 15, right: 15 }}
            >
              <Icon source="close" size={22} color="#FFFFFF" />
            </TouchableOpacity>

            {/* Counter Pill Badge */}
            <View style={styles.counterBadge}>
              <Text style={styles.counterText}>
                {currentIndex + 1} / {images.length}
              </Text>
            </View>

            {/* Share Button */}
            <TouchableOpacity
              style={styles.iconCircleBtn}
              onPress={handleShare}
              activeOpacity={0.7}
              hitSlop={{ top: 15, bottom: 15, left: 15, right: 15 }}
            >
              <Icon source="share-variant" size={20} color="#FFFFFF" />
            </TouchableOpacity>
          </View>
        </SafeAreaView>

        {/* HORIZONTAL HARDWARE-ACCELERATED PAGING GALLERY */}
        <FlatList
          ref={flatListRef}
          data={images}
          horizontal
          pagingEnabled
          showsHorizontalScrollIndicator={false}
          scrollEnabled={!isZoomed}
          keyExtractor={(item, index) => `${item}-${index}`}
          initialScrollIndex={Math.min(Math.max(0, initialIndex), Math.max(0, images.length - 1))}
          onScrollToIndexFailed={(info) => {
            setTimeout(() => {
              try {
                flatListRef.current?.scrollToIndex({ index: info.index, animated: false });
              } catch (_) {
                flatListRef.current?.scrollToOffset({ offset: info.index * screenWidth, animated: false });
              }
            }, 80);
          }}
          getItemLayout={(_, index) => ({
            length: screenWidth,
            offset: screenWidth * index,
            index,
          })}
          onMomentumScrollEnd={(e) => {
            const newIdx = Math.round(e.nativeEvent.contentOffset.x / screenWidth);
            if (newIdx >= 0 && newIdx < images.length && newIdx !== currentIndex) {
              setCurrentIndex(newIdx);
              Haptics.selection();
            }
          }}
          renderItem={({ item, index }) => (
            <ZoomableSlide
              uri={item}
              isActive={index === currentIndex}
              onZoomChange={setIsZoomed}
              onDismiss={onDismiss}
              width={screenWidth}
              height={screenHeight}
            />
          )}
          style={[styles.flatList, { width: screenWidth, height: screenHeight }]}
        />

        {/* BOTTOM DETAILS & CONTROLS OVERLAY - ONLY CHAT & CALL BUTTONS */}
        {part && !isOwner && (onChat || onCall) && (
          <SafeAreaView style={styles.bottomSafeArea} pointerEvents="box-none">
            <View style={styles.bottomContentCard}>
              <View style={styles.actionButtonsRow}>
                {onChat && (
                  <TouchableOpacity
                    activeOpacity={0.85}
                    style={styles.chatButton}
                    onPress={() => {
                      Haptics.medium();
                      onDismiss();
                      setTimeout(() => {
                        onChat();
                      }, 120);
                    }}
                  >
                    <Icon source="message-text" size={19} color="#FFFFFF" />
                    <Text style={styles.chatButtonText}>{translateDynamic('Chat')}</Text>
                  </TouchableOpacity>
                )}

                {onCall && (
                  <TouchableOpacity
                    activeOpacity={0.85}
                    style={styles.callButton}
                    onPress={() => {
                      Haptics.medium();
                      onCall();
                    }}
                  >
                    <Icon source="phone" size={19} color="#38BDF8" />
                    <Text style={styles.callButtonText}>{translateDynamic('Call Seller')}</Text>
                  </TouchableOpacity>
                )}
              </View>
            </View>
          </SafeAreaView>
        )}
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#050B14',
    position: 'relative',
  },
  topSafeArea: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    zIndex: 100,
  },
  topBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: Platform.OS === 'ios' ? 12 : 36,
    paddingBottom: 8,
  },
  iconCircleBtn: {
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: 'rgba(15, 23, 42, 0.82)',
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.15)',
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.35,
    shadowRadius: 4,
  },
  counterBadge: {
    backgroundColor: 'rgba(15, 23, 42, 0.85)',
    paddingHorizontal: 16,
    paddingVertical: 6,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.18)',
    elevation: 3,
  },
  counterText: {
    color: '#F8FAFC',
    fontWeight: '700',
    fontSize: 13,
    letterSpacing: 0.5,
  },
  flatList: {
    flex: 1,
    backgroundColor: '#050B14',
  },
  slideContainer: {
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#050B14',
  },
  imageTransformWrapper: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  imageInnerContainer: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  fullImage: {
    resizeMode: 'contain',
  },
  loadingContainer: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 10,
  },
  errorContainer: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'center',
    alignItems: 'center',
    gap: 10,
    zIndex: 10,
  },
  errorText: {
    color: '#94A3B8',
    fontSize: 13,
    fontWeight: '500',
  },
  bottomSafeArea: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    zIndex: 100,
    paddingHorizontal: 16,
    paddingBottom: Platform.OS === 'ios' ? 24 : 16,
  },
  bottomContentCard: {
    backgroundColor: 'rgba(11, 19, 36, 0.88)',
    borderRadius: 18,
    padding: 10,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.12)',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.45,
    shadowRadius: 10,
    elevation: 8,
  },
  actionButtonsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  chatButton: {
    flex: 1,
    height: 48,
    backgroundColor: '#0066FF',
    borderRadius: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    elevation: 4,
    shadowColor: '#0066FF',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.35,
    shadowRadius: 4,
  },
  chatButtonText: {
    color: '#FFFFFF',
    fontSize: 14.5,
    fontWeight: '700',
  },
  callButton: {
    flex: 1,
    height: 48,
    backgroundColor: 'rgba(15, 23, 42, 0.95)',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: 'rgba(56, 189, 248, 0.45)',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
  },
  callButtonText: {
    color: '#38BDF8',
    fontSize: 14.5,
    fontWeight: '700',
  },
});

export default ImageGalleryModal;
