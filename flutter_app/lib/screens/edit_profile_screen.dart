import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/cloudinary_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final CloudinaryService _cloudinary = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _bioCtrl;

  File? _pickedImageFile;
  String? _currentPhotoUrl;
  String? _oldPhotoUrlToDelete;
  bool _photoRemoved = false;
  bool _isLoading = false;
  bool _isFetching = true;

  FirebaseFirestore get _db {
    try {
      return FirebaseFirestore.instanceFor(
        app: FirebaseFirestore.instance.app,
        databaseId: 'ai-studio-autopartsmarketp-6b6de595-2abc-431d-a6dc-0141a5eff96f',
      );
    } catch (_) {
      return FirebaseFirestore.instance;
    }
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
    _locationCtrl = TextEditingController(text: 'Chennai, Tamil Nadu');
    _bioCtrl = TextEditingController(text: 'Automobile spare parts enthusiast & trader');
    _currentPhotoUrl = user?.photoURL;
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isFetching = false);
      return;
    }

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            if (data['displayName'] != null) _nameCtrl.text = data['displayName'];
            if (data['phone'] != null) _phoneCtrl.text = data['phone'];
            if (data['location'] != null) _locationCtrl.text = data['location'];
            if (data['bio'] != null) _bioCtrl.text = data['bio'];
            if (data['photoURL'] != null || data['profilePhoto'] != null) {
              _currentPhotoUrl = data['photoURL'] ?? data['profilePhoto'];
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() => _pickedImageFile = File(picked.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Update Profile Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0075FF)),
                title: const Text('Take Photo with Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF0075FF)),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_currentPhotoUrl != null || _pickedImageFile != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                  title: const Text('Remove Photo', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _oldPhotoUrlToDelete = _currentPhotoUrl;
                      _currentPhotoUrl = null;
                      _pickedImageFile = null;
                      _photoRemoved = true;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      String? finalPhotoUrl = _photoRemoved ? null : _currentPhotoUrl;

      if (_pickedImageFile != null) {
        final uploaded = await _cloudinary.uploadImage(_pickedImageFile!.path);
        if (uploaded != null && uploaded.isNotEmpty) {
          if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
            CloudinaryService.deleteImage(_currentPhotoUrl!);
          }
          finalPhotoUrl = uploaded;
        }
      } else if (_photoRemoved && _oldPhotoUrlToDelete != null) {
        CloudinaryService.deleteImage(_oldPhotoUrlToDelete!);
      }

      final newName = _nameCtrl.text.trim();
      final newPhone = _phoneCtrl.text.trim();
      final newLocation = _locationCtrl.text.trim();
      final newBio = _bioCtrl.text.trim();

      // Update FirebaseAuth user object
      if (newName.isNotEmpty) {
        await user.updateDisplayName(newName);
      }
      await user.updatePhotoURL(finalPhotoUrl);

      // Update Firestore document
      await _db.collection('users').doc(user.uid).set({
        'id': user.uid,
        'uid': user.uid,
        'displayName': newName,
        'name': newName,
        'email': user.email ?? '',
        'phone': newPhone,
        'phoneNumber': newPhone,
        'location': newLocation,
        'bio': newBio,
        'photoURL': finalPhotoUrl,
        'profilePhoto': finalPhotoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Profile updated successfully!'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to update profile. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0075FF))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with camera badge
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF0075FF).withOpacity(0.12),
                      backgroundImage: _pickedImageFile != null
                          ? FileImage(_pickedImageFile!)
                          : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(_currentPhotoUrl!) as ImageProvider
                              : null),
                      child: (_pickedImageFile == null && (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty))
                          ? const Icon(Icons.person, size: 50, color: Color(0xFF0075FF))
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImagePickerModal,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0075FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _showImagePickerModal,
                child: const Text('Change Profile Photo', style: TextStyle(color: Color(0xFF0075FF), fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 20),

              // Full Name
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDecoration('Full Name *', Icons.person_outline),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 14),

              // Phone Number
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Contact Mobile Phone', Icons.phone_outlined),
              ),
              const SizedBox(height: 14),

              // Location
              TextFormField(
                controller: _locationCtrl,
                decoration: _inputDecoration('Location (City, State)', Icons.location_on_outlined),
              ),
              const SizedBox(height: 14),

              // Bio
              TextFormField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: _inputDecoration('About You / Seller Bio', Icons.info_outline),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0075FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Profile Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
      prefixIcon: Icon(icon, color: const Color(0xFF0075FF), size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0075FF), width: 1.5)),
    );
  }
}
