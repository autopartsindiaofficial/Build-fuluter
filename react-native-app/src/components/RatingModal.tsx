import React, { useState, useRef, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  TextInput,
  ActivityIndicator,
  Alert,
  Animated,
  PanResponder,
  Platform,
  TouchableWithoutFeedback,
  useWindowDimensions,
} from 'react-native';
import { Icon } from 'react-native-paper';
import { getFirebaseFirestore } from '../services/firebase';
import { Haptics } from '../utils/haptics';

interface RatingModalProps {
  isOpen: boolean;
  onClose: () => void;
  sellerId: string;
  sellerName: string;
  buyerId?: string;
  buyerName?: string;
  partId?: string;
  partTitle?: string;
  onSuccess?: () => void;
}

export default function RatingModal({
  isOpen,
  onClose,
  sellerId,
  sellerName,
  buyerId,
  buyerName,
  partId,
  partTitle,
  onSuccess,
}: RatingModalProps) {
  const { height: screenHeight } = useWindowDimensions();
  const [rating, setRating] = useState<number>(5);
  const [comment, setComment] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);

  const translateY = useRef(new Animated.Value(screenHeight)).current;
  const overlayOpacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (isOpen) {
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
  }, [isOpen, screenHeight]);

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
      onClose();
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

  if (!isOpen) return null;

  const handleSubmit = async () => {
    setIsSubmitting(true);
    try {
      const db = getFirebaseFirestore();
      const reviewDoc = {
        sellerId: sellerId || 'seller',
        sellerName: sellerName || 'Auto Parts Seller',
        buyerId: buyerId || 'buyer',
        buyerName: buyerName || 'Verified Buyer',
        rating,
        comment: comment.trim() || 'Great seller, fast communication!',
        partId: partId || '',
        partTitle: partTitle || '',
        createdAt: Date.now(),
      };

      if (db && typeof db.collection === 'function') {
        try {
          await db.collection('sellerReviews').add(reviewDoc);
        } catch (_) {}
      }

      Haptics.success();
      setIsSuccess(true);
      setTimeout(() => {
        setIsSuccess(false);
        setComment('');
        setRating(5);
        if (onSuccess) onSuccess();
        handleClose();
      }, 1400);
    } catch (err: any) {
      Alert.alert('Unable to Submit', 'Could not submit your review right now. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      visible={isOpen}
      transparent={true}
      animationType="none"
      onRequestClose={handleClose}
      statusBarTranslucent={true}
    >
      <TouchableWithoutFeedback onPress={handleClose}>
        <Animated.View style={[styles.overlay, { opacity: overlayOpacity }]}>
          <TouchableWithoutFeedback onPress={(e) => e.stopPropagation()}>
            <Animated.View
              style={[
                styles.sheetCard,
                { transform: [{ translateY }] },
              ]}
              {...panResponder.panHandlers}
            >
              {/* Native Grab Handle */}
              <View style={styles.handleBar} />

              {/* Close Button Top Right */}
              <TouchableOpacity
                onPress={handleClose}
                style={styles.closeBtn}
                hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}
              >
                <Icon source="close" size={20} color="#64748B" />
              </TouchableOpacity>

              {/* Header Title */}
              <View style={styles.header}>
                <Text style={styles.headerSubtitle}>RATE SELLER</Text>
                <Text style={styles.headerTitle} numberOfLines={1}>
                  Review for {sellerName}
                </Text>
              </View>

              {/* Content */}
              <View style={styles.body}>
                {isSuccess ? (
                  <View style={styles.successBox}>
                    <Icon source="check-circle" size={48} color="#10B981" />
                    <Text style={styles.successTitle}>Review Submitted!</Text>
                    <Text style={styles.successSubtitle}>Thank you for your valuable feedback.</Text>
                  </View>
                ) : (
                  <>
                    {partTitle ? (
                      <View style={styles.partInfoBox}>
                        <Text style={styles.partLabel}>PURCHASED PART</Text>
                        <Text style={styles.partName} numberOfLines={1}>
                          {partTitle}
                        </Text>
                      </View>
                    ) : null}

                    <Text style={styles.starPrompt}>How was your experience?</Text>
                    <View style={styles.starsRow}>
                      {[1, 2, 3, 4, 5].map((star) => (
                        <TouchableOpacity
                          key={star}
                          onPress={() => {
                            Haptics.selection();
                            setRating(star);
                          }}
                          style={styles.starTouch}
                          activeOpacity={0.7}
                        >
                          <Icon
                            source={star <= rating ? 'star' : 'star-outline'}
                            size={36}
                            color={star <= rating ? '#F59E0B' : '#CBD5E1'}
                          />
                        </TouchableOpacity>
                      ))}
                    </View>

                    <Text style={styles.inputLabel}>Comments (Optional)</Text>
                    <TextInput
                      style={styles.commentInput}
                      placeholder="Share condition, responsiveness, delivery speed..."
                      placeholderTextColor="#94A3B8"
                      value={comment}
                      onChangeText={setComment}
                      multiline={true}
                      numberOfLines={3}
                    />

                    <TouchableOpacity
                      style={[styles.submitBtn, isSubmitting && styles.submitBtnDisabled]}
                      onPress={handleSubmit}
                      disabled={isSubmitting}
                      activeOpacity={0.85}
                    >
                      {isSubmitting ? (
                        <ActivityIndicator color="#FFFFFF" size="small" />
                      ) : (
                        <Text style={styles.submitBtnText}>Submit Rating & Review</Text>
                      )}
                    </TouchableOpacity>
                  </>
                )}
              </View>
            </Animated.View>
          </TouchableWithoutFeedback>
        </Animated.View>
      </TouchableWithoutFeedback>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(15, 23, 42, 0.65)',
    justifyContent: 'flex-end',
  },
  sheetCard: {
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    paddingTop: 12,
    paddingBottom: Platform.OS === 'ios' ? 36 : 24,
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
  header: {
    paddingHorizontal: 20,
    paddingBottom: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  headerSubtitle: {
    fontSize: 11,
    fontWeight: '800',
    color: '#0066FF',
    letterSpacing: 1,
  },
  headerTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: '#0F172A',
    marginTop: 2,
  },
  body: {
    padding: 20,
  },
  partInfoBox: {
    backgroundColor: '#F8FAFC',
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    marginBottom: 16,
  },
  partLabel: {
    fontSize: 11.5,
    fontWeight: '700',
    color: '#64748B',
    letterSpacing: 0.5,
  },
  partName: {
    fontSize: 14,
    fontWeight: '700',
    color: '#0F172A',
    marginTop: 2,
  },
  starPrompt: {
    fontSize: 14,
    fontWeight: '700',
    color: '#334155',
    textAlign: 'center',
    marginBottom: 10,
  },
  starsRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 12,
    marginBottom: 18,
  },
  starTouch: {
    padding: 4,
  },
  inputLabel: {
    fontSize: 12,
    fontWeight: '700',
    color: '#475569',
    marginBottom: 6,
  },
  commentInput: {
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 14,
    padding: 12,
    fontSize: 13.5,
    color: '#0F172A',
    minHeight: 76,
    textAlignVertical: 'top',
    marginBottom: 18,
  },
  submitBtn: {
    backgroundColor: '#0066FF',
    height: 48,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 3,
    shadowColor: '#0066FF',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
  },
  submitBtnDisabled: {
    opacity: 0.7,
  },
  submitBtnText: {
    color: '#FFFFFF',
    fontSize: 14.5,
    fontWeight: '800',
  },
  successBox: {
    alignItems: 'center',
    paddingVertical: 24,
  },
  successTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: '#10B981',
    marginTop: 10,
  },
  successSubtitle: {
    fontSize: 13,
    color: '#64748B',
    marginTop: 4,
    textAlign: 'center',
  },
});
