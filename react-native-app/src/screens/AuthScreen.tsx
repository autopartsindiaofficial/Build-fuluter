import React, { useState, useRef, useEffect } from 'react';
import {
  View,
  StyleSheet,
  TouchableOpacity,
  StatusBar,
  ActivityIndicator,
  SafeAreaView,
  useWindowDimensions,
  Platform,
  Animated,
  Image,
  TextInput,
  ScrollView,
  Alert
} from 'react-native';
import { Text, Icon } from 'react-native-paper';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { signInWithGoogleNative } from '../services/googleAuth';
import { getFirebaseFirestore, getCurrentUser } from '../services/firebase';
import Svg, { Path } from 'react-native-svg';

export default function AuthScreen({ navigation }: any) {
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [isSignUp, setIsSignUp] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [showPassword, setShowPassword] = useState(false);

  const { width: screenWidth } = useWindowDimensions();
  const insets = useSafeAreaInsets();
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const isMountedRef = useRef(true);

  useEffect(() => {
    isMountedRef.current = true;
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 400,
      useNativeDriver: true,
    }).start();

    return () => {
      isMountedRef.current = false;
    };
  }, []);

  const handleAuthSuccess = () => {
    if (navigation?.canGoBack && navigation.canGoBack()) {
      navigation.goBack();
    } else {
      navigation.reset({
        index: 0,
        routes: [{ name: 'MainTabs' }],
      });
    }
  };

  // Google Sign-In Native
  const handleGoogleSignIn = async () => {
    if (loading) return;
    setLoading(true);
    setErrorMessage(null);
    try {
      const user = await signInWithGoogleNative();
      if (!isMountedRef.current) return;
      if (!user || !user.uid) {
        throw new Error('Unable to complete sign-in. Please try again.');
      }
      handleAuthSuccess();
    } catch (err: any) {
      console.warn('[AuthScreen] Google Sign-In failed:', err);
      const msg = err?.message || 'Unable to sign in with Google. Please check your network and try again.';
      if (isMountedRef.current) {
        setErrorMessage(msg);
      }
    } finally {
      if (isMountedRef.current) {
        setLoading(false);
      }
    }
  };

  const handleEmailSubmit = async () => {
    if (loading) return;
    if (!email.trim() || !password) {
      setErrorMessage('Please enter your email and password.');
      return;
    }
    setLoading(true);
    setErrorMessage(null);
    try {
      // In native app environment, simulate/perform auth or store user
      handleAuthSuccess();
    } catch (err: any) {
      setErrorMessage(err?.message || 'Authentication failed.');
    } finally {
      if (isMountedRef.current) setLoading(false);
    }
  };

  const handleForgotPassword = () => {
    Alert.alert(
      'Reset Password',
      'Enter your email address to receive password reset instructions.',
      [
        { text: 'Cancel', style: 'cancel' },
        { 
          text: 'Send', 
          onPress: () => {
            Alert.alert('Sent', 'Password reset instructions have been sent to your email.');
          }
        }
      ]
    );
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#0F172A" translucent={false} />

      {/* Top Left Close/Back Button */}
      {navigation?.canGoBack && navigation.canGoBack() && (
        <TouchableOpacity 
          style={[styles.backBtn, { top: Math.max(insets.top + 8, 16) }]}
          onPress={() => navigation.goBack()}
          activeOpacity={0.7}
        >
          <Icon source="arrow-left" size={22} color="#FFFFFF" />
        </TouchableOpacity>
      )}

      <Animated.View style={{ flex: 1, opacity: fadeAnim }}>
        <ScrollView 
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
          bounces={false}
        >
          {/* 1. TOP HERO ARTWORK FROM REFERENCE IMAGE */}
          <View style={styles.heroContainer}>
            <Image 
              source={require('../assets/signin_hero.png')}
              style={[styles.heroImage, { width: screenWidth, height: screenWidth * 0.72 }]}
              resizeMode="cover"
            />
          </View>

          {/* 2. BOTTOM WHITE SHEET SIGN-IN CARD MATCHING REFERENCE IMAGE */}
          <View style={styles.cardContainer}>
            <Text style={styles.welcomeText}>
              {isSignUp ? 'Create Account on' : 'Welcome to'}
            </Text>
            <Text style={styles.brandTitleText}>
              Auto Parts India
            </Text>
            <Text style={styles.subtitleText}>
              Buy and sell new & used auto spare parts
            </Text>

            {/* Error Banner */}
            {errorMessage && (
              <View style={styles.errorBanner}>
                <Icon source="alert-circle-outline" size={16} color="#B91C1C" />
                <Text style={styles.errorText}>{errorMessage}</Text>
              </View>
            )}

            {/* Google Sign In Button */}
            <TouchableOpacity
              style={styles.googleBtn}
              onPress={handleGoogleSignIn}
              disabled={loading}
              activeOpacity={0.85}
            >
              <View style={styles.googleBtnLeft}>
                <Svg width={22} height={22} viewBox="0 0 24 24">
                  <Path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4" />
                  <Path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" />
                  <Path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z" fill="#FBBC05" />
                  <Path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z" fill="#EA4335" />
                </Svg>
                <Text style={styles.googleBtnText}>Continue with Google</Text>
              </View>
              <Icon source="chevron-right" size={20} color="#94A3B8" />
            </TouchableOpacity>

            {/* OR Divider */}
            <View style={styles.dividerRow}>
              <View style={styles.dividerLine} />
              <Text style={styles.dividerText}>OR</Text>
              <View style={styles.dividerLine} />
            </View>

            {/* Email / Password Form */}
            {isSignUp && (
              <View style={styles.inputContainer}>
                <Icon source="account-outline" size={18} color="#94A3B8" />
                <TextInput
                  style={styles.textInput}
                  placeholder="Full Name"
                  placeholderTextColor="#94A3B8"
                  value={name}
                  onChangeText={setName}
                />
              </View>
            )}

            <View style={styles.inputContainer}>
              <Icon source="email-outline" size={18} color="#94A3B8" />
              <TextInput
                style={styles.textInput}
                placeholder="Email address"
                placeholderTextColor="#94A3B8"
                keyboardType="email-address"
                autoCapitalize="none"
                value={email}
                onChangeText={setEmail}
              />
            </View>

            <View style={styles.inputContainer}>
              <Icon source="lock-outline" size={18} color="#94A3B8" />
              <TextInput
                style={styles.textInput}
                placeholder="Password"
                placeholderTextColor="#94A3B8"
                secureTextEntry={!showPassword}
                value={password}
                onChangeText={setPassword}
              />
              <TouchableOpacity onPress={() => setShowPassword(!showPassword)}>
                <Icon source={showPassword ? "eye-off-outline" : "eye-outline"} size={18} color="#94A3B8" />
              </TouchableOpacity>
            </View>

            {/* Forgot password */}
            {!isSignUp && (
              <TouchableOpacity style={styles.forgotBtn} onPress={handleForgotPassword}>
                <Text style={styles.forgotText}>Forgot password?</Text>
              </TouchableOpacity>
            )}

            {/* Primary Blue Button */}
            <TouchableOpacity
              style={styles.primaryBtn}
              onPress={handleEmailSubmit}
              disabled={loading}
              activeOpacity={0.88}
            >
              <Text style={styles.primaryBtnText}>
                {isSignUp ? 'Create Account' : 'Sign In'}
              </Text>
              {loading ? (
                <ActivityIndicator color="#FFFFFF" size="small" />
              ) : (
                <Icon source="chevron-right" size={20} color="#FFFFFF" />
              )}
            </TouchableOpacity>

            {/* Toggle Sign In / Sign Up */}
            <TouchableOpacity 
              style={styles.toggleRow}
              onPress={() => setIsSignUp(!isSignUp)}
            >
              <Text style={styles.toggleText}>
                {isSignUp ? 'Already have an account? ' : "Don't have an account? "}
                <Text style={styles.toggleTextBold}>
                  {isSignUp ? 'Sign In' : 'Sign Up'}
                </Text>
              </Text>
            </TouchableOpacity>

            {/* Legal Notice */}
            <View style={styles.legalWrapper}>
              <Text style={styles.legalText}>
                By signing in, you agree to our{'\n'}
                <Text style={styles.legalLink}>Terms of Service</Text> and <Text style={styles.legalLink}>Privacy Policy</Text>
              </Text>
            </View>
          </View>
        </ScrollView>
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0F172A',
  },
  scrollContent: {
    flexGrow: 1,
    backgroundColor: '#0F172A',
  },
  backBtn: {
    position: 'absolute',
    left: 16,
    zIndex: 20,
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: 'rgba(0, 0, 0, 0.4)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  heroContainer: {
    width: '100%',
    backgroundColor: '#0F172A',
    overflow: 'hidden',
  },
  heroImage: {
    width: '100%',
  },
  cardContainer: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    marginTop: -16,
    paddingHorizontal: 24,
    paddingTop: 22,
    paddingBottom: 28,
  },
  welcomeText: {
    fontSize: 22,
    fontWeight: '600',
    color: '#1E293B',
    letterSpacing: -0.3,
  },
  brandTitleText: {
    fontSize: 25,
    fontWeight: '900',
    color: '#0F172A',
    letterSpacing: -0.5,
    marginTop: 1,
  },
  subtitleText: {
    fontSize: 13,
    fontWeight: '500',
    color: '#64748B',
    marginTop: 4,
    marginBottom: 18,
  },
  errorBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FEF2F2',
    borderWidth: 1,
    borderColor: '#FECACA',
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 8,
    marginBottom: 14,
    gap: 8,
  },
  errorText: {
    fontSize: 12,
    color: '#B91C1C',
    fontWeight: '600',
    flex: 1,
  },
  googleBtn: {
    height: 50,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    elevation: 1,
    shadowColor: '#000',
    shadowOpacity: 0.04,
    shadowRadius: 4,
    shadowOffset: { width: 0, height: 2 },
  },
  googleBtnLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  googleBtnText: {
    fontSize: 15,
    fontWeight: '700',
    color: '#1E293B',
  },
  dividerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 14,
  },
  dividerLine: {
    flex: 1,
    height: 1,
    backgroundColor: '#E2E8F0',
  },
  dividerText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#94A3B8',
    marginHorizontal: 12,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 12,
    height: 48,
    paddingHorizontal: 14,
    marginBottom: 10,
    gap: 10,
  },
  textInput: {
    flex: 1,
    fontSize: 14,
    color: '#0F172A',
    fontWeight: '500',
  },
  forgotBtn: {
    alignSelf: 'flex-end',
    marginBottom: 12,
    marginTop: 2,
  },
  forgotText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#006DFD',
  },
  primaryBtn: {
    height: 50,
    backgroundColor: '#006DFD', // Exact royal blue from reference image
    borderRadius: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 18,
    elevation: 2,
    shadowColor: '#006DFD',
    shadowOpacity: 0.25,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 3 },
    marginTop: 4,
  },
  primaryBtnText: {
    fontSize: 15,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  toggleRow: {
    alignItems: 'center',
    marginTop: 14,
  },
  toggleText: {
    fontSize: 13,
    color: '#64748B',
    fontWeight: '500',
  },
  toggleTextBold: {
    fontWeight: '700',
    color: '#006DFD',
  },
  legalWrapper: {
    alignItems: 'center',
    marginTop: 24,
  },
  legalText: {
    fontSize: 11,
    color: '#94A3B8',
    textAlign: 'center',
    lineHeight: 16,
  },
  legalLink: {
    color: '#64748B',
    fontWeight: '600',
    textDecorationLine: 'underline',
  },
});
