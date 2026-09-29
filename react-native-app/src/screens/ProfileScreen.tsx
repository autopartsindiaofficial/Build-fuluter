import React, { useState, useEffect, useMemo } from 'react';
import { View, ScrollView, StyleSheet, TouchableOpacity, Image, Alert, ImageBackground, ActivityIndicator } from 'react-native';
import { Text, Icon, Divider } from 'react-native-paper';
import { getFirebaseAuth, getFirebaseFirestore, getCurrentUser } from '../services/firebase';
import { signOutFromGoogle } from '../services/googleAuth';
import { openNativeCamera, openNativeGallery } from '../services/imagePickerService';
import { uploadImageToCloudinary } from '../services/cloudinary';
import { UserProfilePopupModal } from '../components/UserProfilePopupModal';
import { EditProfileModal } from '../components/EditProfileModal';
import { UserAvatar } from '../components/UserAvatar';
import { ScalePressable } from '../components/animations/ScalePressable';
import { shareAppWithFriends } from '../utils/shareUtils';
import { useFavorites } from '../services/favorites';

export default function ProfileScreen({ navigation, route, user: initialUser }: any) {
  const { favorites } = useFavorites();
  const [activeUid, setActiveUid] = useState<string | null>(initialUser?.uid || null);
  const [userEmail, setUserEmail] = useState<string>(initialUser?.email || '');
  const [displayName, setDisplayName] = useState<string>(initialUser?.displayName || 'Auto Parts India User');
  const [displayPhotoUrl, setDisplayPhotoUrl] = useState<string | null>(initialUser?.photoURL || null);
  const [dbUserDoc, setDbUserDoc] = useState<any>(null);
  const [userAdsCount, setUserAdsCount] = useState<number>(0);
  const [followersCount, setFollowersCount] = useState<number>(0);
  const [followingCount, setFollowingCount] = useState<number>(0);
  const [reviewsCount, setReviewsCount] = useState<number>(0);
  const [avgRating, setAvgRating] = useState<number>(0);
  const [isUploadingCover, setIsUploadingCover] = useState(false);

  const [isEditProfileModalOpen, setIsEditProfileModalOpen] = useState(false);
  const [isPopupModalVisible, setIsPopupModalVisible] = useState(false);

  const SUPER_ADMIN_EMAILS = [
    'wwwautoparts2@gmail.com',
    'www.allahforgiveness877@gmail.com',
  ];

  const isAdmin = 
    dbUserDoc?.role === 'admin' || 
    SUPER_ADMIN_EMAILS.includes(userEmail?.toLowerCase().trim());

  useEffect(() => {
    let unsubscribeAuth = () => {};
    let unsubscribeDb = () => {};
    let unsubscribeAds = () => {};
    let unsubscribeFollowers = () => {};
    let unsubscribeFollowing = () => {};
    let unsubscribeReviews = () => {};

    try {
      const authInst = getFirebaseAuth();
      if (authInst && typeof authInst.onAuthStateChanged === 'function') {
        unsubscribeAuth = authInst.onAuthStateChanged((user) => {
          if (user) {
            setActiveUid(user.uid);
            setUserEmail(user.email || '');
            setDisplayName(user.displayName || 'Auto Parts India User');
            if (user.photoURL || user.profilePhoto) {
              setDisplayPhotoUrl(user.profilePhoto || user.photoURL);
            }

            const db = getFirebaseFirestore();
            if (db && typeof db.collection === 'function') {
              unsubscribeDb = db.collection('users').doc(user.uid).onSnapshot((doc: any) => {
                const exists = typeof doc?.exists === 'function' ? doc.exists() : Boolean(doc?.exists);
                if (exists) {
                  const data = typeof doc?.data === 'function' ? doc.data() : doc?.data;
                  if (data) {
                    setDbUserDoc(data);
                    if (data.displayName || data.name) setDisplayName(data.displayName || data.name);
                    const photo = data.profilePhoto || data.customPhoto || data.photoURL || data.profileImageUrl;
                    if (photo) {
                      setDisplayPhotoUrl(photo);
                    }
                  }
                }
              });

              // Query user active ads count
              unsubscribeAds = db.collection('spareParts')
                .where('sellerId', '==', user.uid)
                .onSnapshot((snap: any) => {
                  let count = 0;
                  snap?.forEach((docSnap: any) => {
                    const data = docSnap.data();
                    if (!data.isDeleted && data.status !== 'deleted') {
                      count++;
                    }
                  });
                  setUserAdsCount(count);
                }, () => {});

              // 1. Real Followers Count
              unsubscribeFollowers = db.collection('follows')
                .where('followingId', '==', user.uid)
                .onSnapshot((snap: any) => {
                  if (snap) {
                    setFollowersCount(snap.size || (snap.docs ? snap.docs.length : 0));
                  }
                }, () => {});

              // 2. Real Following Count
              unsubscribeFollowing = db.collection('follows')
                .where('followerId', '==', user.uid)
                .onSnapshot((snap: any) => {
                  if (snap) {
                    setFollowingCount(snap.size || (snap.docs ? snap.docs.length : 0));
                  }
                }, () => {});

              // 3. Real Reviews & Star Rating
              unsubscribeReviews = db.collection('reviews')
                .where('sellerId', '==', user.uid)
                .onSnapshot((snap: any) => {
                  if (snap && snap.docs) {
                    const revDocs = snap.docs.map((d: any) => d.data());
                    const count = revDocs.length;
                    setReviewsCount(count);
                    if (count > 0) {
                      const totalStars = revDocs.reduce((acc: number, r: any) => acc + (Number(r.rating) || 5), 0);
                      const avg = Math.round((totalStars / count) * 10) / 10;
                      setAvgRating(avg);
                    } else {
                      setAvgRating(0);
                    }
                  }
                }, () => {});
            }
          } else {
            setActiveUid(null);
            setUserEmail('');
            setDbUserDoc(null);
            setUserAdsCount(0);
            setFollowersCount(0);
            setFollowingCount(0);
            setReviewsCount(0);
            setAvgRating(0);
          }
        });
      }
    } catch (_) {}

    return () => {
      unsubscribeAuth();
      unsubscribeDb();
      unsubscribeAds();
      unsubscribeFollowers();
      unsubscribeFollowing();
      unsubscribeReviews();
    };
  }, []);

  // Screen focus listener to immediately refresh profile picture when returning
  useEffect(() => {
    if (!navigation || typeof navigation.addListener !== 'function') return;
    const unsubFocus = navigation.addListener('focus', async () => {
      const current = getCurrentUser();
      if (current?.uid) {
        setActiveUid(current.uid);
        if (current.displayName) setDisplayName(current.displayName);
        if (current.email) setUserEmail(current.email);
        const curPhoto = current.profilePhoto || current.photoURL;
        if (curPhoto) setDisplayPhotoUrl(curPhoto);

        try {
          const db = getFirebaseFirestore();
          if (db && typeof db.collection === 'function') {
            const snap = await db.collection('users').doc(current.uid).get();
            const exists = typeof snap?.exists === 'function' ? snap.exists() : Boolean(snap?.exists);
            if (exists) {
              const data = typeof snap?.data === 'function' ? snap.data() : snap?.data;
              if (data) {
                setDbUserDoc(data);
                if (data.displayName || data.name) setDisplayName(data.displayName || data.name);
                const cloudPhoto = data.profilePhoto || data.customPhoto || data.photoURL || data.profileImageUrl;
                if (cloudPhoto) setDisplayPhotoUrl(cloudPhoto);
              }
            }
          }
        } catch (_) {}
      }
    });

    return unsubFocus;
  }, [navigation]);

  // Calculate dynamic profile completion percentage
  const profileCompletion = useMemo(() => {
    let score = 30; // base score for account creation
    if (displayName && displayName !== 'Auto Parts India User') score += 20;
    if (displayPhotoUrl && !displayPhotoUrl.includes('placeholder')) score += 20;
    if (dbUserDoc?.phone || dbUserDoc?.phoneNumber) score += 15;
    if (dbUserDoc?.location || dbUserDoc?.district) score += 15;
    return Math.min(score, 100);
  }, [displayName, displayPhotoUrl, dbUserDoc]);

  const handleEditCoverDirectly = () => {
    Alert.alert(
      'Profile Cover Banner',
      'Update your shop/profile header banner with a real photo:',
      [
        {
          text: 'Take Photo (Camera)',
          onPress: async () => {
            const uri = await openNativeCamera();
            if (uri) {
              uploadAndSaveCover(uri);
            }
          },
        },
        {
          text: 'Choose from Gallery',
          onPress: async () => {
            const uri = await openNativeGallery();
            if (uri) {
              uploadAndSaveCover(uri);
            }
          },
        },
        {
          text: 'Edit All Profile Info',
          onPress: () => setIsEditProfileModalOpen(true),
        },
        ...(dbUserDoc?.coverUrl
          ? [
              {
                text: 'Reset to Default Banner',
                style: 'destructive' as const,
                onPress: async () => {
                  uploadAndSaveCover('');
                },
              },
            ]
          : []),
        { text: 'Cancel', style: 'cancel' },
      ]
    );
  };

  const uploadAndSaveCover = async (imageUri: string) => {
    if (!activeUid) {
      Alert.alert('Sign In', 'Please sign in to update your banner.');
      return;
    }

    setIsUploadingCover(true);
    try {
      let finalUrl = '';
      if (imageUri) {
        if (imageUri.startsWith('http')) {
          finalUrl = imageUri;
        } else {
          const uploaded = await uploadImageToCloudinary(imageUri, 'cover_photos');
          if (uploaded) {
            finalUrl = uploaded;
          }
        }
      }

      const db = getFirebaseFirestore();
      if (db && typeof db.collection === 'function') {
        await db.collection('users').doc(activeUid).set(
          {
            coverUrl: finalUrl,
            profileCover: finalUrl,
            updatedAt: Date.now(),
          },
          { merge: true }
        );
      }

      setDbUserDoc((prev: any) => ({ ...prev, coverUrl: finalUrl }));
      Alert.alert('Banner Updated', 'Your profile cover banner has been updated in real-time!');
    } catch (err: any) {
      console.warn('Cover upload failed:', err);
      Alert.alert('Upload Failed', 'Could not upload cover image. Please try again.');
    } finally {
      setIsUploadingCover(false);
    }
  };

  const handleSignOut = () => {
    Alert.alert(
      'Logout',
      'Are you sure you want to logout of your account?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Logout',
          style: 'destructive',
          onPress: async () => {
            try {
              await signOutFromGoogle();
              const authInst = getFirebaseAuth();
              if (authInst && typeof authInst.signOut === 'function') {
                await authInst.signOut();
              }
              if (navigation?.reset) {
                navigation.reset({
                  index: 0,
                  routes: [{ name: 'Auth' }],
                });
              } else {
                navigation.navigate('Auth');
              }
            } catch (err: any) {
              Alert.alert('Error', 'Failed to logout.');
            }
          },
        },
      ]
    );
  };

  return (
    <View style={styles.container}>
      <ScrollView 
        contentContainerStyle={styles.scrollContent} 
        showsVerticalScrollIndicator={false}
        scrollEventThrottle={16}
        bounces={true}
        alwaysBounceVertical={true}
        decelerationRate="normal"
        overScrollMode="never"
        keyboardShouldPersistTaps="handled"
        keyboardDismissMode="on-drag"
      >
        {/* TOP COVER BANNER - 100% REAL WITH DIRECT UPLOAD & FIRESTORE SYNC */}
        <View style={styles.coverContainer}>
          <ImageBackground
            source={{ 
              uri: dbUserDoc?.coverUrl || 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&q=80&w=800' 
            }}
            style={styles.coverImage}
            imageStyle={styles.coverImageStyle}
          >
            <View style={styles.coverOverlay}>
              <View style={styles.coverTagBox}>
                <Text style={styles.coverTagHeading}>
                  {dbUserDoc?.coverUrl ? 'OFFICIAL' : 'DRIVE'}
                </Text>
                <Text style={styles.coverTagSub}>
                  {dbUserDoc?.coverUrl ? 'PARTS SHOP' : 'A BETTER'}
                </Text>
                <Text style={styles.coverTagSub}>
                  {dbUserDoc?.coverUrl ? 'GARAGE' : 'TOMORROW'}
                </Text>
              </View>
              
              <TouchableOpacity 
                style={styles.editCoverBtn} 
                activeOpacity={0.8}
                onPress={handleEditCoverDirectly}
                disabled={isUploadingCover}
              >
                {isUploadingCover ? (
                  <ActivityIndicator size="small" color="#FFFFFF" style={{ marginRight: 4 }} />
                ) : (
                  <Icon source="camera-outline" size={14} color="#FFFFFF" />
                )}
                <Text style={styles.editCoverBtnText}>
                  {isUploadingCover ? 'Uploading...' : dbUserDoc?.coverUrl ? 'Change Cover' : 'Edit Cover'}
                </Text>
              </TouchableOpacity>
            </View>
          </ImageBackground>

          {/* AVATAR OVERLAP */}
          <View style={styles.avatarPositioner}>
            <ScalePressable
              onPress={() => {
                if (displayPhotoUrl && !displayPhotoUrl.includes('photo-1534528741775-53994a69daeb')) {
                  setIsPopupModalVisible(true);
                } else {
                  setIsEditProfileModalOpen(true);
                }
              }}
              style={styles.avatarGlowWrap}
              scaleTo={0.93}
            >
              <UserAvatar
                photoUrl={displayPhotoUrl}
                name={displayName}
                size={88}
                borderWidth={3.5}
                borderColor="#FFFFFF"
              />
              <TouchableOpacity 
                style={styles.avatarCameraBadge}
                activeOpacity={0.85}
                onPress={() => setIsEditProfileModalOpen(true)}
              >
                <Icon source="camera" size={13} color="#FFFFFF" />
              </TouchableOpacity>
            </ScalePressable>
          </View>
        </View>

        {/* USER IDENTIFICATION & REVIEWS */}
        <View style={styles.userHeaderArea}>
          <View style={styles.userNameRow}>
            <Text style={styles.profileName} numberOfLines={1}>{displayName}</Text>
            <Icon source="check-decagram" size={19} color="#0066FF" />
          </View>
          <Text style={styles.profileEmail} numberOfLines={1}>{userEmail || 'member@autopartsindia.com'}</Text>
          
          {/* STAR RATING ROW - 100% REAL FROM FIRESTORE */}
          <TouchableOpacity 
            style={styles.ratingRow}
            activeOpacity={0.8}
            onPress={() => {
              if (activeUid) {
                navigation.navigate('SellerProfile', {
                  sellerId: activeUid,
                  sellerName: displayName,
                  seller: {
                    id: activeUid,
                    name: displayName,
                    displayName: displayName,
                    profilePhoto: displayPhotoUrl,
                    email: userEmail,
                  }
                });
              }
            }}
          >
            {reviewsCount > 0 ? (
              <>
                {[1, 2, 3, 4, 5].map((star) => (
                  <Icon 
                    key={star} 
                    source={star <= Math.round(avgRating) ? "star" : "star-outline"} 
                    size={16} 
                    color="#F59E0B" 
                  />
                ))}
                <Text style={styles.ratingValueText}> {avgRating.toFixed(1)}</Text>
                <Text style={styles.ratingCountText}> ({reviewsCount} {reviewsCount === 1 ? 'review' : 'reviews'})</Text>
              </>
            ) : (
              <View style={{ flexDirection: 'row', alignItems: 'center', backgroundColor: '#EFF6FF', paddingHorizontal: 8, paddingVertical: 2, borderRadius: 12 }}>
                <Icon source="star" size={14} color="#0066FF" />
                <Text style={{ fontSize: 12, fontWeight: '700', color: '#0066FF', marginLeft: 4 }}>Verified Seller (0 Reviews)</Text>
              </View>
            )}
          </TouchableOpacity>
        </View>

        {/* STATS TRIPLE METRIC BAR - 100% REAL LIVE DATA */}
        <View style={styles.statsBar}>
          <TouchableOpacity 
            style={styles.statItem} 
            activeOpacity={0.7}
            onPress={() => navigation.navigate('MyAdsTab')}
          >
            <Text style={styles.statNumber}>{userAdsCount || 0}</Text>
            <Text style={styles.statLabel}>Active Ads</Text>
          </TouchableOpacity>

          <View style={styles.statDivider} />

          <TouchableOpacity 
            style={styles.statItem}
            activeOpacity={0.7}
            onPress={() => {
              if (activeUid) {
                navigation.navigate('SellerProfile', {
                  sellerId: activeUid,
                  sellerName: displayName,
                  seller: { id: activeUid, name: displayName }
                });
              }
            }}
          >
            <Text style={styles.statNumber}>{followersCount}</Text>
            <Text style={styles.statLabel}>Followers</Text>
          </TouchableOpacity>

          <View style={styles.statDivider} />

          <TouchableOpacity 
            style={styles.statItem}
            activeOpacity={0.7}
            onPress={() => {
              if (activeUid) {
                navigation.navigate('SellerProfile', {
                  sellerId: activeUid,
                  sellerName: displayName,
                  seller: { id: activeUid, name: displayName }
                });
              }
            }}
          >
            <Text style={styles.statNumber}>{reviewsCount}</Text>
            <Text style={styles.statLabel}>Reviews</Text>
          </TouchableOpacity>
        </View>

        {/* PROFILE COMPLETION CARD */}
        <TouchableOpacity 
          style={styles.completionCard}
          activeOpacity={0.8}
          onPress={() => setIsEditProfileModalOpen(true)}
        >
          <View style={styles.completionLeftIcon}>
            <View style={styles.circularIndicator}>
              <Icon source="progress-check" size={26} color="#10B981" />
            </View>
          </View>
          <View style={styles.completionInfo}>
            <View style={styles.completionTitleRow}>
              <Text style={styles.completionTitle}>Profile Completion</Text>
              <Text style={styles.completionPercent}>{profileCompletion}%</Text>
            </View>
            <View style={styles.progressBarTrack}>
              <View style={[styles.progressBarFill, { width: `${profileCompletion}%` }]} />
            </View>
            <Text style={styles.completionSubtext}>Complete your profile to gain more buyer trust.</Text>
          </View>
        </TouchableOpacity>

        {/* MODERN NAVIGATION MENU ITEMS */}
        <View style={styles.menuContainer}>
          {/* Admin Panel Entry */}
          {isAdmin && (
            <>
              <TouchableOpacity 
                style={[styles.menuItem, styles.adminMenuItem]} 
                onPress={() => navigation.navigate('Admin')}
                activeOpacity={0.7}
              >
                <View style={[styles.menuIconBox, { backgroundColor: '#FEF3C7' }]}>
                  <Icon source="shield-crown" size={20} color="#D97706" />
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={[styles.menuItemText, { fontWeight: '700', color: '#B45309' }]}>Admin Panel</Text>
                  <Text style={styles.adminSubText}>Control users, CMS, approvals</Text>
                </View>
                <View style={styles.adminBadge}>
                  <Text style={styles.adminBadgeText}>Control</Text>
                </View>
                <Icon source="chevron-right" size={18} color="#D97706" style={{ marginLeft: 6 }} />
              </TouchableOpacity>
              <Divider style={styles.divider} />
            </>
          )}

          {/* My Ads */}
          <TouchableOpacity 
            style={styles.menuItem} 
            onPress={() => navigation.navigate('MyAdsTab')}
            activeOpacity={0.7}
          >
            <View style={[styles.menuIconBox, { backgroundColor: '#EFF6FF' }]}>
              <Icon source="card-text-outline" size={20} color="#0066FF" />
            </View>
            <Text style={styles.menuItemText}>My Ads</Text>
            <Icon source="chevron-right" size={20} color="#94A3B8" />
          </TouchableOpacity>
          
          <Divider style={styles.divider} />
          
          {/* Wishlist */}
          <TouchableOpacity 
            style={styles.menuItem} 
            onPress={() => navigation.navigate('WishlistScreen')}
            activeOpacity={0.7}
          >
            <View style={[styles.menuIconBox, { backgroundColor: '#FEF2F2' }]}>
              <Icon source="heart-outline" size={20} color="#EF4444" />
            </View>
            <Text style={styles.menuItemText}>Wishlist</Text>
            {favorites.length > 0 && (
              <View style={styles.countBadgePill}>
                <Text style={styles.countBadgePillText}>{favorites.length}</Text>
              </View>
            )}
            <Icon source="chevron-right" size={20} color="#94A3B8" style={{ marginLeft: 6 }} />
          </TouchableOpacity>

          <Divider style={styles.divider} />

          {/* Recently Viewed */}
          <TouchableOpacity 
            style={styles.menuItem} 
            onPress={() => navigation.navigate('RecentlyViewedScreen')}
            activeOpacity={0.7}
          >
            <View style={[styles.menuIconBox, { backgroundColor: '#ECFDF5' }]}>
              <Icon source="history" size={20} color="#10B981" />
            </View>
            <Text style={styles.menuItemText}>Recently Viewed</Text>
            <Icon source="chevron-right" size={20} color="#94A3B8" />
          </TouchableOpacity>

          <Divider style={styles.divider} />

          {/* Settings */}
          <TouchableOpacity 
            style={styles.menuItem} 
            onPress={() => navigation.navigate('SettingsScreen')}
            activeOpacity={0.7}
          >
            <View style={[styles.menuIconBox, { backgroundColor: '#F1F5F9' }]}>
              <Icon source="cog-outline" size={20} color="#64748B" />
            </View>
            <Text style={styles.menuItemText}>Settings</Text>
            <Icon source="chevron-right" size={20} color="#94A3B8" />
          </TouchableOpacity>

          <Divider style={styles.divider} />

          {/* Help & Support */}
          <TouchableOpacity 
            style={styles.menuItem} 
            onPress={() => navigation.navigate('HelpSupportScreen')}
            activeOpacity={0.7}
          >
            <View style={[styles.menuIconBox, { backgroundColor: '#FFFBEB' }]}>
              <Icon source="lifebuoy" size={20} color="#F59E0B" />
            </View>
            <Text style={styles.menuItemText}>Help & Support</Text>
            <Icon source="chevron-right" size={20} color="#94A3B8" />
          </TouchableOpacity>

          <Divider style={styles.divider} />

          {/* Share App with Friends */}
          <TouchableOpacity 
            style={styles.menuItem} 
            onPress={shareAppWithFriends}
            activeOpacity={0.7}
          >
            <View style={[styles.menuIconBox, { backgroundColor: '#EFF6FF' }]}>
              <Icon source="share-variant-outline" size={20} color="#0066FF" />
            </View>
            <Text style={styles.menuItemText}>Share App with Friends</Text>
            <Icon source="chevron-right" size={20} color="#94A3B8" />
          </TouchableOpacity>

          <Divider style={styles.divider} />

          {/* Log Out */}
          <TouchableOpacity 
            style={styles.menuItem} 
            onPress={handleSignOut}
            activeOpacity={0.7}
          >
            <View style={[styles.menuIconBox, { backgroundColor: '#FEF2F2' }]}>
              <Icon source="logout" size={20} color="#EF4444" />
            </View>
            <Text style={[styles.menuItemText, { color: '#EF4444', fontWeight: '700' }]}>Log Out</Text>
            <Icon source="chevron-right" size={20} color="#FCA5A5" />
          </TouchableOpacity>
        </View>
      </ScrollView>

      {/* Profile Popup */}
      <UserProfilePopupModal
        visible={isPopupModalVisible}
        onDismiss={() => setIsPopupModalVisible(false)}
        userPhoto={displayPhotoUrl}
        userName={displayName}
      />

      {/* Edit Profile Details Modal */}
      <EditProfileModal
        visible={isEditProfileModalOpen}
        onDismiss={() => setIsEditProfileModalOpen(false)}
        initialName={displayName}
        initialPhoto={displayPhotoUrl}
        initialCover={dbUserDoc?.coverUrl || null}
        initialBio={dbUserDoc?.bio || ''}
        initialPhone={dbUserDoc?.phone || ''}
        initialLocation={dbUserDoc?.location || ''}
        onSaveSuccess={(data) => {
          setDisplayName(data.displayName);
          if (data.photoURL) setDisplayPhotoUrl(data.photoURL);
          if (data.coverUrl !== undefined) {
            setDbUserDoc((prev: any) => ({ ...prev, coverUrl: data.coverUrl }));
          }
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  scrollContent: {
    paddingBottom: 45,
  },
  coverContainer: {
    position: 'relative',
    marginBottom: 44,
  },
  coverImage: {
    width: '100%',
    height: 160,
    backgroundColor: '#0F172A',
  },
  coverImageStyle: {
    resizeMode: 'cover',
  },
  coverOverlay: {
    flex: 1,
    backgroundColor: 'rgba(15, 23, 42, 0.45)',
    padding: 16,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  coverTagBox: {
    paddingTop: 10,
  },
  coverTagHeading: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '900',
    letterSpacing: 1.5,
  },
  coverTagSub: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '800',
    letterSpacing: 1,
    lineHeight: 15,
  },
  editCoverBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    backgroundColor: 'rgba(15, 23, 42, 0.65)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
    marginTop: 8,
  },
  editCoverBtnText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '600',
  },
  avatarPositioner: {
    position: 'absolute',
    bottom: -40,
    left: 20,
  },
  avatarGlowWrap: {
    position: 'relative',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 6,
  },
  avatarCameraBadge: {
    position: 'absolute',
    bottom: 2,
    right: 2,
    backgroundColor: '#0066FF',
    width: 24,
    height: 24,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#FFFFFF',
    elevation: 4,
  },
  userHeaderArea: {
    paddingHorizontal: 20,
    marginTop: 4,
    marginBottom: 16,
  },
  userNameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  profileName: {
    fontSize: 20,
    fontWeight: '800',
    color: '#0F172A',
  },
  profileEmail: {
    fontSize: 13,
    color: '#64748B',
    marginTop: 2,
  },
  ratingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 6,
    gap: 2,
  },
  ratingValueText: {
    fontSize: 13,
    fontWeight: '700',
    color: '#0F172A',
    marginLeft: 4,
  },
  ratingCountText: {
    fontSize: 12.5,
    color: '#64748B',
  },
  statsBar: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    marginHorizontal: 16,
    borderRadius: 16,
    paddingVertical: 14,
    marginBottom: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  statItem: {
    flex: 1,
    alignItems: 'center',
  },
  statNumber: {
    fontSize: 18,
    fontWeight: '800',
    color: '#0F172A',
  },
  statLabel: {
    fontSize: 12,
    color: '#64748B',
    marginTop: 2,
    fontWeight: '500',
  },
  statDivider: {
    width: 1,
    height: 26,
    backgroundColor: '#E2E8F0',
  },
  completionCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    marginHorizontal: 16,
    borderRadius: 16,
    padding: 14,
    marginBottom: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  completionLeftIcon: {
    marginRight: 12,
  },
  circularIndicator: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#ECFDF5',
    justifyContent: 'center',
    alignItems: 'center',
  },
  completionInfo: {
    flex: 1,
  },
  completionTitleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  completionTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: '#0F172A',
  },
  completionPercent: {
    fontSize: 13,
    fontWeight: '800',
    color: '#10B981',
  },
  progressBarTrack: {
    height: 5,
    backgroundColor: '#E2E8F0',
    borderRadius: 3,
    marginVertical: 6,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    backgroundColor: '#10B981',
    borderRadius: 3,
  },
  completionSubtext: {
    fontSize: 11,
    color: '#64748B',
  },
  menuContainer: {
    backgroundColor: '#FFFFFF',
    marginHorizontal: 16,
    borderRadius: 16,
    paddingVertical: 4,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 13,
    paddingHorizontal: 16,
  },
  adminMenuItem: {
    backgroundColor: '#FFFDF5',
  },
  adminBadge: {
    backgroundColor: '#FEF3C7',
    borderWidth: 1,
    borderColor: '#FDE68A',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 6,
  },
  adminBadgeText: {
    color: '#D97706',
    fontSize: 11,
    fontWeight: '700',
  },
  adminSubText: {
    fontSize: 11.5,
    color: '#92400E',
    marginTop: 1,
  },
  menuIconBox: {
    width: 36,
    height: 36,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 14,
  },
  menuItemText: {
    flex: 1,
    fontSize: 14.5,
    fontWeight: '600',
    color: '#1E293B',
  },
  countBadgePill: {
    backgroundColor: '#EFF6FF',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#DBEAFE',
  },
  countBadgePillText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#0066FF',
  },
  divider: {
    backgroundColor: '#F1F5F9',
    height: 1,
    marginHorizontal: 16,
  },
});

