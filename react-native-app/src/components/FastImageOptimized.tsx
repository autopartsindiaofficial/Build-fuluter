import React, { useState, useRef, useEffect } from 'react';
import {
  View,
  Image,
  ImageProps,
  StyleSheet,
  Animated,
  StyleProp,
  ImageStyle,
  ViewStyle,
} from 'react-native';
import { getOptimizedImageUrl } from '../services/cloudinary';

interface FastImageOptimizedProps extends Omit<ImageProps, 'source'> {
  source?: { uri?: string } | number;
  uri?: string;
  width?: number;
  height?: number;
  quality?: number;
  style?: StyleProp<ImageStyle>;
  containerStyle?: StyleProp<ViewStyle>;
  fallbackUri?: string;
}

/**
 * High-Performance Progressive Cached Image Component
 * 
 * Features:
 * - Automatic Cloudinary WebP optimization & dynamic resizing
 * - Smooth fadeIn on network load
 * - Ultra-low memory thumbnail skeleton placeholder
 * - Graceful fallback on network loss
 */
export const FastImageOptimized: React.FC<FastImageOptimizedProps> = React.memo(({
  source,
  uri,
  width = 400,
  height = 300,
  quality = 80,
  style,
  containerStyle,
  fallbackUri = 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=400&q=80',
  resizeMode = 'cover',
  ...rest
}) => {
  const [loaded, setLoaded] = useState(false);
  const [error, setError] = useState(false);
  const opacityAnim = useRef(new Animated.Value(0)).current;

  const rawUri = uri || (typeof source === 'object' && source?.uri ? source.uri : '');
  const isLocalRequire = typeof source === 'number';

  // Compute optimized Cloudinary CDN URL
  const optimizedUri = React.useMemo(() => {
    if (error || !rawUri) return fallbackUri;
    if (typeof rawUri === 'string' && rawUri.startsWith('http')) {
      return getOptimizedImageUrl(rawUri, width, height, quality);
    }
    return rawUri;
  }, [rawUri, width, height, quality, error, fallbackUri]);

  const handleLoad = () => {
    setLoaded(true);
    Animated.timing(opacityAnim, {
      toValue: 1,
      duration: 250,
      useNativeDriver: true,
    }).start();
  };

  const handleError = () => {
    setError(true);
    setLoaded(true);
  };

  if (isLocalRequire) {
    return (
      <View style={[styles.container, containerStyle]}>
        <Image
          source={source}
          style={style}
          resizeMode={resizeMode}
          {...rest}
        />
      </View>
    );
  }

  return (
    <View style={[styles.container, containerStyle]}>
      {/* Placeholder Base Background */}
      {!loaded && <View style={[styles.placeholder, style]} />}

      {/* Progressive Loaded Image */}
      <Animated.Image
        source={{ uri: optimizedUri }}
        style={[
          style,
          {
            opacity: opacityAnim,
          },
        ]}
        resizeMode={resizeMode}
        onLoad={handleLoad}
        onError={handleError}
        {...rest}
      />
    </View>
  );
});

const styles = StyleSheet.create({
  container: {
    overflow: 'hidden',
    position: 'relative',
    backgroundColor: '#F1F5F9',
  },
  placeholder: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: '#E2E8F0',
  },
});
