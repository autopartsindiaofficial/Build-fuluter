import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  Image,
  TextInput,
  ActivityIndicator,
  Alert,
  ScrollView,
  Platform,
  SafeAreaView,
  KeyboardAvoidingView,
  TouchableWithoutFeedback,
  Keyboard,
} from 'react-native';
import { Icon } from 'react-native-paper';
import { getFirebaseAuth, getFirebaseFirestore, getCurrentUser, setCurrentAuthUser } from '../services/firebase';
import { openNativeCamera, openNativeGallery, promptImageSourceDialog } from '../services/imagePickerService';
import { uploadImageToCloudinary } from '../services/cloudinary';

interface EditProfileModalProps {
  visible: boolean;
  onDismiss: () => void;
  onSaveSuccess?: (updatedData: {
    displayName: string;
    photoURL?: string;
    coverUrl?: string;
    bio?: string;
    phone?: string;
    location?: string;
  }) => void;
  initialName?: string;
  initialPhoto?: string | null;
  initialCover?: string | null;
  initialBio?: string;
  initialPhone?: string;
  initialLocation?: string;
}

export const EditProfileModal: React.FC<EditProfileModalProps> = ({
  visible,
  onDismiss,
  onSaveSuccess,
  initialName = '',
  initialPhoto = null,
  initialCover = null,
  initialBio = '',
  initialPhone = '',
  initialLocation = '',
}) => {
  const [displayName, setDisplayName] = useState(initialName);
  const [photoUri, setPhotoUri] = useState<string | null>(initialPhoto);
  const [coverUri, setCoverUri] = useState<string | null>(initialCover);
  const [bio, setBio] = useState(initialBio);
  const [phone, setPhone] = useState(initialPhone);
  const [location, setLocation] = useState(initialLocation);

  const [isPhotoChanged, setIsPhotoChanged] = useState(false);
  const [isCoverChanged, setIsCoverChanged] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isUploadingPhoto, setIsUploadingPhoto] = useState(false);
  const [isUploadingCover, setIsUploadingCover] = useState(false);

  useEffect(() => {
    if (visible) {
      setDisplayName(initialName);
      setPhotoUri(initialPhoto);
      setCoverUri(initialCover);
      setBio(initialBio);
      setPhone(initialPhone);
      setLocation(initialLocation);
      setIsPhotoChanged(false);
      setIsCoverChanged(false);
      setIsSaving(false);
      setIsUploadingPhoto(false);
      setIsUploadingCover(false);
    }
  }, [visible, initialName, initialPhoto, initialCover, initialBio, initialPhone, initialLocation]);

  const handlePickPhoto = async () => {
    Alert.alert(
      'Profile Photo',
      'Select a source for your profile picture:',
      [
        {
          text: 'Take Photo (Camera)',
          onPress: async () => {
            const uri = await openNativeCamera();
            if (uri) {
              setPhotoUri(uri);
              setIsPhotoChanged(true);
            }
          },
        },
        {
          text: 'Choose from Gallery',
          onPress: async () => {
            const uri = await openNativeGallery();
            if (uri) {
              setPhotoUri(uri);
              setIsPhotoChanged(true);
            }
          },
        },
        ...(photoUri
          ? [
              {
                text: 'Remove Current Photo',
                style: 'destructive' as const,
                onPress: () => {
                  setPhotoUri('');
                  setIsPhotoChanged(true);
                },
              },
            ]
          : []),
        { text: 'Cancel', style: 'cancel' },
      ]
    );
  };

  const handlePickCover = async () => {
    Alert.alert(
      'Profile Cover Banner',
      'Select a header banner for your automotive shop profile:',
      [
        {
          text: 'Take Photo (Camera)',
          onPress: async () => {
            const uri = await openNativeCamera();
            if (uri) {
              setCoverUri(uri);
              setIsCoverChanged(true);
            }
          },
        },
        {
          text: 'Choose from Gallery',
          onPress: async () => {
            const uri = await openNativeGallery();
            if (uri) {
              setCoverUri(uri);
              setIsCoverChanged(true);
            }
          },
        },
        ...(coverUri
          ? [
              {
                text: 'Reset to Default Banner',
                style: 'destructive' as const,
                onPress: () => {
                  setCoverUri('');
                  setIsCoverChanged(true);
                },
              },
            ]
          : []),
        { text: 'Cancel', style: 'cancel' },
      ]
    );
  };

  const handleSave = async () => {
    if (!displayName.trim()) {
      Alert.alert('Name Required', 'Please enter your display name.');
      return;
    }

    setIsSaving(true);
    try {
      const currentUser = getCurrentUser();
      const uid = currentUser?.uid;
      if (!uid) {
        Alert.alert('Error', 'User not authenticated. Please log in again.');
        setIsSaving(false);
        return;
      }

      let finalPhotoUrl = photoUri;
      let finalCoverUrl = coverUri;

      // 1. Upload photo to Cloudinary if a local file URI was selected
      if (isPhotoChanged && photoUri && !photoUri.startsWith('http')) {
        setIsUploadingPhoto(true);
        try {
          const uploadedUrl = await uploadImageToCloudinary(photoUri, 'profile_photos');
          if (uploadedUrl) {
            finalPhotoUrl = uploadedUrl;
          }
        } catch (uploadErr) {
          console.warn('Cloudinary photo upload error:', uploadErr);
        } finally {
          setIsUploadingPhoto(false);
        }
      }

      // 2. Upload cover banner to Cloudinary if a local file URI was selected
      if (isCoverChanged && coverUri && !coverUri.startsWith('http')) {
        setIsUploadingCover(true);
        try {
          const uploadedCover = await uploadImageToCloudinary(coverUri, 'cover_photos');
          if (uploadedCover) {
            finalCoverUrl = uploadedCover;
          }
        } catch (coverErr) {
          console.warn('Cloudinary cover upload error:', coverErr);
        } finally {
          setIsUploadingCover(false);
        }
      }

      const trimmedName = displayName.trim();
      const trimmedBio = bio.trim();
      const trimmedPhone = phone.trim();
      const trimmedLocation = location.trim();

      // 3. Prepare user document payload
      const userPayload: any = {
        displayName: trimmedName,
        name: trimmedName,
        bio: trimmedBio,
        phone: trimmedPhone,
        location: trimmedLocation,
        updatedAt: Date.now(),
      };

      if (isPhotoChanged) {
        userPayload.photoURL = finalPhotoUrl || '';
        userPayload.profilePhoto = finalPhotoUrl || '';
        userPayload.profileImageUrl = finalPhotoUrl || '';
        userPayload.customPhoto = finalPhotoUrl || '';
        userPayload.photoDeleted = !finalPhotoUrl;
      }

      if (isCoverChanged) {
        userPayload.coverUrl = finalCoverUrl || '';
        userPayload.profileCover = finalCoverUrl || '';
        userPayload.coverDeleted = !finalCoverUrl;
      }

      // 4. Save to Firestore `users/{uid}`
      const db = getFirebaseFirestore();
      if (db && typeof db.collection === 'function') {
        await db.collection('users').doc(uid).set(userPayload, { merge: true });

        // Cascade update: Update seller info on all listings posted by this user
        try {
          const partsSnap = await db.collection('spareParts').where('sellerId', '==', uid).get();
          if (partsSnap && !partsSnap.empty) {
            const batchPromises: Promise<any>[] = [];
            partsSnap.forEach((docSnap: any) => {
              const updateObj: any = {
                sellerName: trimmedName,
              };
              if (isPhotoChanged) {
                updateObj.sellerPhoto = finalPhotoUrl || '';
                updateObj.sellerPhotoURL = finalPhotoUrl || '';
                updateObj.sellerAvatar = finalPhotoUrl || '';
              }
              if (trimmedPhone) updateObj.sellerPhone = trimmedPhone;
              if (trimmedLocation) updateObj.sellerLocation = trimmedLocation;

              batchPromises.push(docSnap.ref.update(updateObj).catch(() => {}));
            });
            await Promise.allSettled(batchPromises);
          }
        } catch (cascadePartsErr) {
          console.warn('Cascade parts update warning:', cascadePartsErr);
        }

        // Cascade update: Update chats where user is seller or buyer
        try {
          const sellerChats = await db.collection('chats').where('sellerId', '==', uid).get();
          if (sellerChats && !sellerChats.empty) {
            sellerChats.forEach((docSnap: any) => {
              const uObj: any = { sellerName: trimmedName };
              if (isPhotoChanged) uObj.sellerPhoto = finalPhotoUrl || '';
              docSnap.ref.update(uObj).catch(() => {});
            });
          }

          const buyerChats = await db.collection('chats').where('buyerId', '==', uid).get();
          if (buyerChats && !buyerChats.empty) {
            buyerChats.forEach((docSnap: any) => {
              const uObj: any = { buyerName: trimmedName };
              if (isPhotoChanged) uObj.buyerPhoto = finalPhotoUrl || '';
              docSnap.ref.update(uObj).catch(() => {});
            });
          }
        } catch (cascadeChatErr) {
          console.warn('Cascade chat update warning:', cascadeChatErr);
        }
      }

      // 5. Update Firebase Auth Profile
      const authInst = getFirebaseAuth();
      if (authInst?.currentUser && typeof authInst.currentUser.updateProfile === 'function') {
        const authPayload: any = { displayName: trimmedName };
        if (isPhotoChanged) authPayload.photoURL = finalPhotoUrl || '';
        try {
          await authInst.currentUser.updateProfile(authPayload);
        } catch (_) {}
      }

      // 6. Update Local Auth Session
      await setCurrentAuthUser({
        ...currentUser,
        displayName: trimmedName,
        name: trimmedName,
        bio: trimmedBio,
        phone: trimmedPhone,
        location: trimmedLocation,
        ...(isPhotoChanged
          ? {
              photoURL: finalPhotoUrl || '',
              profilePhoto: finalPhotoUrl || '',
              profileImageUrl: finalPhotoUrl || '',
              customPhoto: finalPhotoUrl || '',
              photoDeleted: !finalPhotoUrl,
            }
          : {}),
        ...(isCoverChanged
          ? {
              coverUrl: finalCoverUrl || '',
            }
          : {}),
      });

      // 7. Invoke Callback and Close
      if (onSaveSuccess) {
        onSaveSuccess({
          displayName: trimmedName,
          photoURL: finalPhotoUrl || undefined,
          coverUrl: finalCoverUrl || undefined,
          bio: trimmedBio,
          phone: trimmedPhone,
          location: trimmedLocation,
        });
      }

      Alert.alert('Profile Updated', 'Your profile details have been successfully saved!');
      onDismiss();
    } catch (err: any) {
      console.warn('Failed to save profile:', err);
      Alert.alert('Save Failed', err.message || 'Unable to update profile. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent={false}
      onRequestClose={onDismiss}
      statusBarTranslucent={false}
    >
      <SafeAreaView style={styles.safeArea}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}
          style={styles.container}
        >
          {/* Header Bar matching Reference Screenshot */}
          <View style={styles.headerBar}>
            <TouchableOpacity
              style={styles.headerIconBtn}
              onPress={onDismiss}
              activeOpacity={0.7}
              disabled={isSaving}
            >
              <Icon source="close" size={26} color="#0F172A" />
            </TouchableOpacity>

            <Text style={styles.headerTitle}>Edit Profile</Text>

            <TouchableOpacity
              style={styles.saveBtn}
              onPress={handleSave}
              activeOpacity={0.7}
              disabled={isSaving || isUploadingPhoto}
            >
              {isSaving || isUploadingPhoto ? (
                <ActivityIndicator size="small" color="#0066FF" />
              ) : (
                <Text style={styles.saveBtnText}>Save</Text>
              )}
            </TouchableOpacity>
          </View>

          <ScrollView
            contentContainerStyle={styles.scrollContent}
            keyboardShouldPersistTaps="handled"
            keyboardDismissMode="on-drag"
            showsVerticalScrollIndicator={false}
            scrollEventThrottle={16}
            bounces={true}
            alwaysBounceVertical={true}
            decelerationRate="normal"
            overScrollMode="never"
          >
            {/* Section: Basic information */}
            <Text style={styles.sectionHeading}>Basic information</Text>

            {/* Profile Cover Banner Card */}
            <View style={styles.coverSectionBlock}>
              <Text style={styles.inputSubLabel}>Profile Cover Banner</Text>
              <TouchableOpacity
                style={styles.coverPreviewCard}
                onPress={handlePickCover}
                activeOpacity={0.85}
                disabled={isSaving}
              >
                <Image
                  source={{
                    uri:
                      coverUri ||
                      'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&q=80&w=800',
                  }}
                  style={styles.coverPreviewImage}
                />
                <View style={styles.coverActionOverlay}>
                  <View style={styles.coverEditPill}>
                    <Icon source="camera-outline" size={16} color="#FFFFFF" />
                    <Text style={styles.coverEditPillText}>
                      {coverUri ? 'Change Banner' : 'Upload Shop Banner'}
                    </Text>
                  </View>
                </View>
              </TouchableOpacity>
            </View>

            {/* Profile Picture & Name Row */}
            <View style={styles.profileRow}>
              {/* Circular Avatar with Camera Banner Overlay */}
              <TouchableOpacity
                style={styles.avatarContainer}
                onPress={handlePickPhoto}
                activeOpacity={0.8}
                disabled={isSaving}
              >
                {photoUri ? (
                  <Image source={{ uri: photoUri }} style={styles.avatarImage} />
                ) : (
                  <View style={styles.avatarFallback}>
                    <Icon source="account" size={48} color="#94A3B8" />
                  </View>
                )}

                {/* Bottom Camera Overlay Banner matching Screenshot */}
                <View style={styles.cameraBannerOverlay}>
                  <Icon source="camera" size={18} color="#FFFFFF" />
                </View>
              </TouchableOpacity>

              {/* Enter your name input */}
              <View style={styles.nameInputContainer}>
                <Text style={styles.inputSubLabel}>Enter your name</Text>
                <TextInput
                  style={styles.underlinedInput}
                  value={displayName}
                  onChangeText={setDisplayName}
                  placeholder="e.g. Auto Parts India User"
                  placeholderTextColor="#94A3B8"
                  autoCapitalize="words"
                  maxLength={50}
                  editable={!isSaving}
                />
              </View>
            </View>

            {/* Something about you (Bio / About) */}
            <View style={styles.fieldBlock}>
              <Text style={styles.inputSubLabel}>Something about you</Text>
              <TextInput
                style={[styles.underlinedInput, styles.bioInput]}
                value={bio}
                onChangeText={setBio}
                placeholder="Write a few lines about your automotive shop, experience, or parts..."
                placeholderTextColor="#94A3B8"
                multiline
                numberOfLines={3}
                maxLength={300}
                editable={!isSaving}
              />
            </View>

            {/* Contact Phone (Optional but useful for Marketplace) */}
            <View style={styles.fieldBlock}>
              <Text style={styles.inputSubLabel}>Contact Phone Number</Text>
              <TextInput
                style={styles.underlinedInput}
                value={phone}
                onChangeText={setPhone}
                placeholder="e.g. +91 98765 43210"
                placeholderTextColor="#94A3B8"
                keyboardType="phone-pad"
                maxLength={20}
                editable={!isSaving}
              />
            </View>

            {/* City / Location */}
            <View style={styles.fieldBlock}>
              <Text style={styles.inputSubLabel}>City / Location</Text>
              <TextInput
                style={styles.underlinedInput}
                value={location}
                onChangeText={setLocation}
                placeholder="e.g. Chennai, Tamil Nadu"
                placeholderTextColor="#94A3B8"
                maxLength={60}
                editable={!isSaving}
              />
            </View>
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </Modal>
  );
};

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  headerBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
    backgroundColor: '#FFFFFF',
  },
  headerIconBtn: {
    padding: 6,
    marginLeft: -6,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#0F172A',
  },
  saveBtn: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    minWidth: 54,
    alignItems: 'flex-end',
    justifyContent: 'center',
  },
  saveBtnText: {
    fontSize: 16,
    fontWeight: '700',
    color: '#0066FF',
  },
  scrollContent: {
    paddingHorizontal: 20,
    paddingTop: 24,
    paddingBottom: 40,
  },
  sectionHeading: {
    fontSize: 18,
    fontWeight: '700',
    color: '#0F172A',
    marginBottom: 24,
  },
  coverSectionBlock: {
    marginBottom: 24,
  },
  coverPreviewCard: {
    width: '100%',
    height: 110,
    borderRadius: 12,
    overflow: 'hidden',
    position: 'relative',
    backgroundColor: '#0F172A',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  coverPreviewImage: {
    width: '100%',
    height: '100%',
  },
  coverActionOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(15, 23, 42, 0.38)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  coverEditPill: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(0, 0, 0, 0.65)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
  },
  coverEditPillText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '700',
    marginLeft: 6,
  },
  profileRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 28,
  },
  avatarContainer: {
    width: 90,
    height: 90,
    borderRadius: 45,
    backgroundColor: '#F1F5F9',
    overflow: 'hidden',
    position: 'relative',
    borderWidth: 1.5,
    borderColor: '#E2E8F0',
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarImage: {
    width: '100%',
    height: '100%',
    borderRadius: 45,
  },
  avatarFallback: {
    width: '100%',
    height: '100%',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#F8FAFC',
  },
  cameraBannerOverlay: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    height: 32,
    backgroundColor: '#0066FF',
    alignItems: 'center',
    justifyContent: 'center',
    opacity: 0.92,
  },
  nameInputContainer: {
    flex: 1,
    marginLeft: 18,
  },
  inputSubLabel: {
    fontSize: 13,
    color: '#64748B',
    marginBottom: 6,
    fontWeight: '500',
  },
  underlinedInput: {
    fontSize: 16,
    color: '#0F172A',
    fontWeight: '600',
    paddingVertical: 8,
    paddingHorizontal: 0,
    borderBottomWidth: 1.5,
    borderBottomColor: '#0F172A',
  },
  fieldBlock: {
    marginBottom: 28,
  },
  bioInput: {
    minHeight: 50,
    textAlignVertical: 'top',
    fontSize: 15,
    fontWeight: '400',
  },
});
