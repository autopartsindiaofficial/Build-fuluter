import React, { useState } from 'react';
import {
  Modal,
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import MaterialCommunityIcons from 'react-native-vector-icons/MaterialCommunityIcons';

interface MakeOfferModalProps {
  visible: boolean;
  partTitle?: string;
  listedPrice?: number;
  onClose: () => void;
  onSubmitOffer: (offerPrice: number) => void;
}

export const MakeOfferModal: React.FC<MakeOfferModalProps> = ({
  visible,
  partTitle = 'Auto Spare Part',
  listedPrice = 0,
  onClose,
  onSubmitOffer,
}) => {
  const [customPrice, setCustomPrice] = useState('');
  const [errorMsg, setErrorMsg] = useState('');

  if (!visible) return null;

  const quickDiscounts = [10, 15, 20, 25];

  const handleSelectDiscount = (percent: number) => {
    if (!listedPrice) return;
    const calculated = Math.round(listedPrice * (1 - percent / 100));
    setCustomPrice(String(calculated));
    setErrorMsg('');
  };

  const handleSubmit = () => {
    const num = Number(customPrice.replace(/[^0-9]/g, ''));
    if (!num || num <= 0) {
      setErrorMsg('Please enter a valid offer amount');
      return;
    }
    if (listedPrice > 0 && num > listedPrice * 1.5) {
      setErrorMsg('Offer cannot be significantly higher than listed price');
      return;
    }
    setErrorMsg('');
    onSubmitOffer(num);
    setCustomPrice('');
    onClose();
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="slide"
      onRequestClose={onClose}
    >
      <KeyboardAvoidingView
        style={styles.overlay}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <TouchableOpacity style={styles.backdrop} activeOpacity={1} onPress={onClose} />

        <View style={styles.modalCard}>
          {/* Header */}
          <View style={styles.headerRow}>
            <View style={styles.tagCircle}>
              <MaterialCommunityIcons name="tag-text-outline" size={22} color="#0066FF" />
            </View>
            <View style={{ flex: 1, marginLeft: 10 }}>
              <Text style={styles.title}>Make an Offer</Text>
              <Text style={styles.subTitle} numberOfLines={1}>{partTitle}</Text>
            </View>
            <TouchableOpacity onPress={onClose} style={styles.closeBtn}>
              <MaterialCommunityIcons name="close" size={20} color="#64748B" />
            </TouchableOpacity>
          </View>

          {/* Listed Price Banner */}
          <View style={styles.listedPriceBanner}>
            <Text style={styles.listedPriceLabel}>Original Asking Price:</Text>
            <Text style={styles.listedPriceVal}>
              ₹{Number(listedPrice || 0).toLocaleString('en-IN')}
            </Text>
          </View>

          {/* Quick Discount Chips */}
          {listedPrice > 0 && (
            <View style={styles.quickChipSection}>
              <Text style={styles.quickChipTitle}>Quick Offer Presets:</Text>
              <View style={styles.chipsRow}>
                {quickDiscounts.map((percent) => {
                  const val = Math.round(listedPrice * (1 - percent / 100));
                  const isSelected = customPrice === String(val);
                  return (
                    <TouchableOpacity
                      key={`discount-${percent}`}
                      style={[styles.chip, isSelected && styles.chipActive]}
                      onPress={() => handleSelectDiscount(percent)}
                      activeOpacity={0.8}
                    >
                      <Text style={[styles.chipText, isSelected && styles.chipTextActive]}>
                        -{percent}% (₹{val.toLocaleString('en-IN')})
                      </Text>
                    </TouchableOpacity>
                  );
                })}
              </View>
            </View>
          )}

          {/* Offer Input Field */}
          <View style={styles.inputSection}>
            <Text style={styles.inputLabel}>Your Offered Price (₹)</Text>
            <View style={styles.inputWrapper}>
              <Text style={styles.rupeeSymbol}>₹</Text>
              <TextInput
                style={styles.textInput}
                keyboardType="numeric"
                placeholder={listedPrice ? String(Math.round(listedPrice * 0.9)) : '0'}
                placeholderTextColor="#94A3B8"
                value={customPrice}
                onChangeText={(txt) => {
                  setCustomPrice(txt);
                  setErrorMsg('');
                }}
              />
            </View>
            {errorMsg ? <Text style={styles.errorText}>{errorMsg}</Text> : null}
          </View>

          {/* Send Offer Button */}
          <TouchableOpacity
            style={styles.submitBtn}
            onPress={handleSubmit}
            activeOpacity={0.85}
          >
            <MaterialCommunityIcons name="send" size={18} color="#FFFFFF" />
            <Text style={styles.submitBtnText}>Send Offer to Seller</Text>
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    justifyContent: 'flex-end',
    backgroundColor: 'rgba(15, 23, 42, 0.65)',
  },
  backdrop: {
    flex: 1,
  },
  modalCard: {
    backgroundColor: '#0F172A',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    padding: 20,
    borderWidth: 1,
    borderColor: '#1E293B',
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
  },
  tagCircle: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(0, 102, 255, 0.15)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  title: {
    color: '#F8FAFC',
    fontSize: 18,
    fontWeight: '800',
  },
  subTitle: {
    color: '#94A3B8',
    fontSize: 12,
    fontWeight: '500',
  },
  closeBtn: {
    padding: 6,
  },
  listedPriceBanner: {
    backgroundColor: '#1E293B',
    borderRadius: 12,
    paddingHorizontal: 14,
    paddingVertical: 10,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  listedPriceLabel: {
    color: '#94A3B8',
    fontSize: 13,
    fontWeight: '600',
  },
  listedPriceVal: {
    color: '#60A5FA',
    fontSize: 16,
    fontWeight: '800',
  },
  quickChipSection: {
    marginBottom: 16,
  },
  quickChipTitle: {
    color: '#CBD5E1',
    fontSize: 12,
    fontWeight: '700',
    marginBottom: 8,
  },
  chipsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  chip: {
    backgroundColor: '#1E293B',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#334155',
  },
  chipActive: {
    backgroundColor: '#0066FF',
    borderColor: '#3B82F6',
  },
  chipText: {
    color: '#CBD5E1',
    fontSize: 12,
    fontWeight: '600',
  },
  chipTextActive: {
    color: '#FFFFFF',
    fontWeight: '800',
  },
  inputSection: {
    marginBottom: 20,
  },
  inputLabel: {
    color: '#F8FAFC',
    fontSize: 13,
    fontWeight: '700',
    marginBottom: 8,
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#1E293B',
    borderRadius: 12,
    borderWidth: 1.5,
    borderColor: '#3B82F6',
    paddingHorizontal: 14,
  },
  rupeeSymbol: {
    color: '#3B82F6',
    fontSize: 20,
    fontWeight: '800',
    marginRight: 6,
  },
  textInput: {
    flex: 1,
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: '800',
    paddingVertical: 12,
  },
  errorText: {
    color: '#EF4444',
    fontSize: 12,
    marginTop: 6,
    fontWeight: '600',
  },
  submitBtn: {
    backgroundColor: '#0066FF',
    paddingVertical: 14,
    borderRadius: 14,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 8,
  },
  submitBtnText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '800',
  },
});
