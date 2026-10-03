import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final String? phone;
  final String location;
  final String role;
  final double rating;
  final int reviewsCount;
  final bool isVerified;
  final String? fcmToken;
  final List<String> savedParts;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.phone,
    this.location = 'India',
    this.role = 'buyer',
    this.rating = 5.0,
    this.reviewsCount = 0,
    this.isVerified = true,
    this.fcmToken,
    this.savedParts = const [],
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? data['name'] ?? 'Auto Enthusiast',
      photoURL: data['photoURL'] ?? data['photoUrl'] ?? data['avatarUrl'] ?? data['profileImage'] ?? data['profilePhoto'],
      phone: data['phone'] ?? data['phoneNumber'],
      location: data['location'] ?? 'India',
      role: data['role'] ?? 'buyer',
      rating: (data['rating'] is num) ? (data['rating'] as num).toDouble() : 5.0,
      reviewsCount: data['reviewsCount'] is int ? data['reviewsCount'] : 0,
      isVerified: data['isVerified'] != false,
      fcmToken: data['fcmToken'],
      savedParts: List<String>.from(data['savedParts'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phone': phone,
      'location': location,
      'role': role,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'isVerified': isVerified,
      'fcmToken': fcmToken,
      'savedParts': savedParts,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
