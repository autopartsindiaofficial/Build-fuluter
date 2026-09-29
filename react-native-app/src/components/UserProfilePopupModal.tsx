import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableWithoutFeedback,
  TouchableOpacity,
  Image,
  useWindowDimensions,
  Platform,
  ActivityIndicator,
  Animated,
  PanResponder,
} from 'react-native';
import { Icon } from 'react-native-paper';
import { Haptics } from '../utils/haptics';

interface UserProfilePopupModalProps {
  visible: boolean;
  onDismiss: () => void;
  userPhoto?: string | null;
  userName?: string;
  userLocation?: string;
  phone?: string;
  onChangePhoto?: () => void;
  onChatPress?: () => void;
  onViewProfilePress?: () => void;
  onFullPhotoPress?: () => void;
}

export const UserProfilePopupModal: React.FC<UserProfilePopupModalProps> = ({
  visible,
  onDismiss,
  userPhoto,
  userName,
  userLocation,
  phone,
  onChangePhoto,
  onChatPress,
  onViewProfilePress,
  onFullPhotoPress,
}) => {
  const { width: screenWidth, height: screenHeight } = useWindowDimensions();
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);

  const translateY = useRef(new Animated.Value(screenHeight)).current;
  const overlayOpacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (visible) {
      setIsLoading(true);
      setHasError(false);
      Haptics.light();

      Animated.parallel([
        Animated.spring(translateY, {
          toValue: 0,
          useNativeDriver: true,
          bounciness: 4,
          speed: 14,
        }),
        Animated.timing(overlayOpacity, {
          toValue: 1,
          duration: 250,
          useNativeDriver: true,
        }),
      ]).start();
    } else {
      Animated.parallel([
        Animated.timing(translateY, {
          toValue: screenHeight,
          duration: 220,
          useNativeDriver: true,
        }),
        Animated.timing(overlayOpacity, {
          toValue: 0,
          duration: 200,
          useNativeDriver: true,
        }),
      ]).start();
    }
  }, [visible, userPhoto, screenHeight]);

  const handleClose = () => {
    Haptics.light();
    Animated.parallel([
      Animated.timing(translateY, {
        toValue: screenHeight,
        duration: 200,
        useNativeDriver: true,
      }),
      Animated.timing(overlayOpacity, {
        toValue: 0,
        duration: 180,
        useNativeDriver: true,
      }),
    ]).start(() => {
      onDismiss();
    });
  };

  const panResponder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onMoveShouldSetPanResponder: (_, g) => g.dy > 5,
      onPanResponderMove: (_, g) => {
        if (g.dy > 0) {
          translateY.setValue(g.dy);
        }
      },
      onPanResponderRelease: (_, g) => {
        if (g.dy > 80 || g.vy > 0.8) {
          handleClose();
        } else {
          Animated.spring(translateY, {
            toValue: 0,
            useNativeDriver: true,
            bounciness: 4,
          }).start();
        }
      },
    })
  ).current;

  if (!visible) return null;

  const hasValidPhoto =
    !hasError &&
    Boolean(userPhoto) &&
    typeof userPhoto === 'string' &&
    userPhoto.trim().length > 5 &&
    !userPhoto.includes('photo-1534528741775-53994a69daeb');

  const displayName = userName || 'Verified Member';

  return (
    <Modal
      visible={visible}
      transparent={true}
      animationType="none"
      onRequestClose={handleClose}
      statusBarTranslucent={true}
    >
      <TouchableWithoutFeedback onPress={handleClose}>
        <Animated.View style={[styles.backdrop, { opacity: overlayOpacity }]}>
          <TouchableWithoutFeedback onPress={(e) => e.stopPropagation()}>
            <Animated.View
              style={[
                styles.sheetContainer,
                { transform: [{ translateY }] },
              ]}
              {...panResponder.panHandlers}
            >
              {/* Native Grab Handle */}
              <View style={styles.handleBar} />

              {/* Close Button Top Right */}
              <TouchableOpacity
                style={styles.closeBtn}
                onPress={handleClose}
                hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}
              >
                <Icon source="close" size={20} color="#64748B" />
              </TouchableOpacity>

              {/* Profile Avatar with Native Ring */}
              <TouchableOpacity
                activeOpacity={onFullPhotoPress || onChangePhoto ? 0.8 : 1}
                onPress={() => {
                  if (onFullPhotoPress) {
                    onFullPhotoPress();
                  } else if (onChangePhoto) {
                    onChangePhoto();
                  }
                }}
                style={styles.avatarWrapper}
              >
                <View style={styles.avatarBorder}>
                  {hasValidPhoto ? (
                    <>
                      <Image
                        source={{ uri: userPhoto! }}
                        style={styles.avatarImage}
                        resizeMode="cover"
                        onLoadStart={() => setIsLoading(true)}
                        onLoadEnd={() => setIsLoading(false)}
                        onError={() => {
                          setHasError(true);
                          setIsLoading(false);
                        }}
                      />
                      {isLoading && (
                        <View style={styles.avatarLoading}>
                          <ActivityIndicator size="small" color="#0066FF" />
                        </View>
                      )}
                    </>
                  ) : (
                    <View style={styles.avatarFallback}>
                      <Text style={styles.avatarInitial}>
                        {displayName.charAt(0).toUpperCase()}
                      </Text>
                    </View>
                  )}
                </View>

                {/* Verified Native Badge */}
                <View style={styles.verifiedBadge}>
                  <Icon source="check-decagram" size={22} color="#0066FF" />
                </View>
              </TouchableOpacity>

              {/* User Information */}
              <Text style={styles.nameText} numberOfLines={1}>
                {displayName}
              </Text>

              {userLocation ? (
                <View style={styles.locationRow}>
                  <Icon source="map-marker" size={16} color="#64748B" />
                  <Text style={styles.locationText} numberOfLines={1}>
                    {userLocation}
                  </Text>
                </View>
              ) : null}

              {phone ? (
                <View style={styles.phoneRow}>
                  <Icon source="phone" size={14} color="#0066FF" />
                  <Text style={styles.phoneText}>{phone}</Text>
                </View>
              ) : null}

              {/* Native Action Buttons */}
              <View style={styles.actionRow}>
                {onChatPress && (
                  <TouchableOpacity
                    style={styles.primaryActionBtn}
                    onPress={() => {
                      handleClose();
                      setTimeout(() => onChatPress(), 150);
                    }}
                    activeOpacity={0.8}
                  >
                    <Icon source="message-text" size={18} color="#FFFFFF" />
                    <Text style={styles.primaryActionText}>Message</Text>
                  </TouchableOpacity>
                )}

                {onViewProfilePress && (
                  <TouchableOpacity
                    style={styles.secondaryActionBtn}
                    onPress={() => {
                      handleClose();
                      setTimeout(() => onViewProfilePress(), 150);
                    }}
                    activeOpacity={0.8}
                  >
                    <Icon source="account-circle-outline" size={18} color="#0F172A" />
                    <Text style={styles.secondaryActionText}>View Profile</Text>
                  </TouchableOpacity>
                )}

                {onChangePhoto && (
                  <TouchableOpacity
                    style={styles.secondaryActionBtn}
                    onPress={() => {
                      handleClose();
                      setTimeout(() => onChangePhoto(), 150);
                    }}
                    activeOpacity={0.8}
                  >
                    <Icon source="camera-outline" size={18} color="#0066FF" />
                    <Text style={[styles.secondaryActionText, { color: '#0066FF' }]}>Change Photo</Text>
                  </TouchableOpacity>
                )}
              </View>
            </Animated.View>
          </TouchableWithoutFeedback>
        </Animated.View>
      </TouchableWithoutFeedback>
    </Modal>
  );
};

const styles = StyleSheet.create({
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(15, 23, 42, 0.65)',
    justifyContent: 'flex-end',
  },
  sheetContainer: {
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    paddingHorizontal: 20,
    paddingTop: 12,
    paddingBottom: Platform.OS === 'ios' ? 36 : 24,
    alignItems: 'center',
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: -8 },
        shadowOpacity: 0.15,
        shadowRadius: 20,
      },
      android: {
        elevation: 16,
      },
    }),
  },
  handleBar: {
    width: 40,
    height: 4.5,
    borderRadius: 3,
    backgroundColor: '#CBD5E1',
    alignSelf: 'center',
    marginBottom: 8,
  },
  closeBtn: {
    position: 'absolute',
    top: 14,
    right: 16,
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#F1F5F9',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 10,
  },
  avatarWrapper: {
    marginTop: 8,
    marginBottom: 14,
    position: 'relative',
  },
  avatarBorder: {
    width: 104,
    height: 104,
    borderRadius: 52,
    borderWidth: 3.5,
    borderColor: '#0066FF',
    overflow: 'hidden',
    backgroundColor: '#EFF6FF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarImage: {
    width: '100%',
    height: '100%',
  },
  avatarLoading: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(255, 255, 255, 0.7)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarFallback: {
    width: '100%',
    height: '100%',
    backgroundColor: '#EFF6FF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarInitial: {
    fontSize: 42,
    fontWeight: '800',
    color: '#0066FF',
  },
  verifiedBadge: {
    position: 'absolute',
    bottom: 2,
    right: 2,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 1,
    elevation: 2,
  },
  nameText: {
    fontSize: 18,
    fontWeight: '800',
    color: '#0F172A',
    textAlign: 'center',
    letterSpacing: -0.2,
  },
  locationRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginTop: 4,
  },
  locationText: {
    fontSize: 13,
    color: '#64748B',
    fontWeight: '500',
  },
  phoneRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginTop: 6,
    backgroundColor: '#EFF6FF',
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 12,
  },
  phoneText: {
    fontSize: 12.5,
    color: '#0066FF',
    fontWeight: '700',
  },
  actionRow: {
    flexDirection: 'row',
    gap: 12,
    width: '100%',
    marginTop: 20,
  },
  primaryActionBtn: {
    flex: 1,
    height: 46,
    borderRadius: 14,
    backgroundColor: '#0066FF',
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 8,
    elevation: 3,
    shadowColor: '#0066FF',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
  },
  primaryActionText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '700',
  },
  secondaryActionBtn: {
    flex: 1,
    height: 46,
    borderRadius: 14,
    backgroundColor: '#F1F5F9',
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 8,
  },
  secondaryActionText: {
    color: '#0F172A',
    fontSize: 14,
    fontWeight: '700',
  },
});

export default UserProfilePopupModal;
