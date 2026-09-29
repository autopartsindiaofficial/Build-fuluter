import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _saveUserProfile(userCredential.user!);
      }
      return userCredential;
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  // Email & Password Sign In
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Email & Password Sign Up
  Future<UserCredential> signUpWithEmail(String email, String password, String name) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      await cred.user!.updateDisplayName(name);
      await _saveUserProfile(cred.user!, customName: name);
    }
    return cred;
  }

  // Save/Update User Profile in Firestore
  Future<void> _saveUserProfile(User user, {String? customName}) async {
    final userRef = _db.collection('users').doc(user.uid);
    final doc = await userRef.get();
    
    if (!doc.exists) {
      final profile = UserProfile(
        id: user.uid,
        email: user.email ?? '',
        displayName: customName ?? user.displayName ?? 'Auto Enthusiast',
        photoURL: user.photoURL,
        phone: user.phoneNumber,
        location: 'India',
        role: 'buyer',
      );
      await userRef.set(profile.toMap());
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
