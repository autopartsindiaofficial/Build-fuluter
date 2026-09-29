import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = true;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AppAuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      if (user != null) {
        await _fetchUserProfile(user.uid);
      } else {
        _userProfile = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        _userProfile = UserProfile.fromFirestore(doc);
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithGoogle();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithEmail(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signUpWithEmail(email, password, name);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
