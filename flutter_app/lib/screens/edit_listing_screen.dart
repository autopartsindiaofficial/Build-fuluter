import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spare_part.dart';
import '../services/cloudinary_service.dart';

class EditListingScreen extends StatefulWidget {
  final SparePart part;

  const EditListingScreen({Key? key, required this.part}) : super(key: key);

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _categoryController;
  late TextEditingController _oemController;
  late TextEditingController _locationController;
  late TextEditingController _descController;
  late TextEditingController _phoneController;

  late String _selectedCondition;
  late bool _isNegotiable;
  late List<String> _currentImages;
  final List<String> _removedImages = [];
  final List<File> _newImages = [];
  bool _isLoading = false;

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

  final List<String> _conditions = [
    'Brand New (OEM)',
    'Used - Like New',
    'Used - Good',
    'Used - Fair',
    'Refurbished',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.part;
    _titleController = TextEditingController(text: p.title);
    _priceController = TextEditingController(text: p.price.toStringAsFixed(0));
    _brandController = TextEditingController(text: p.carBrand);
    _modelController = TextEditingController(text: p.carModel);
    _categoryController = TextEditingController(text: p.category);
    _oemController = TextEditingController(text: p.oemNumber ?? '');
    _locationController = TextEditingController(text: p.location);
    _descController = TextEditingController(text: p.description ?? '');
    _phoneController = TextEditingController(text: p.contactPhone ?? '');

    _selectedCondition = _conditions.contains(p.condition) ? p.condition : 'Used - Like New';
    _isNegotiable = p.isNegotiable;
    _currentImages = List<String>.from(p.imageUrls.isNotEmpty ? p.imageUrls : [p.imageUrl]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _categoryController.dispose();
    _oemController.dispose();
    _locationController.dispose();
    _descController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _newImages.add(File(picked.path));
        });
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📸 New photo added!'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Part Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentImages.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please keep or add at least one photo of the part.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Trigger deletion of removed images from Cloudinary storage
      if (_removedImages.isNotEmpty) {
        CloudinaryService.deleteImages(_removedImages);
      }

      List<String> finalImageUrls = List<String>.from(_currentImages);

      for (var f in _newImages) {
        final url = await _cloudinaryService.uploadImage(f.path);
        if (url != null && url.isNotEmpty) {
          finalImageUrls.add(url);
        }
      }

      final updatedData = {
        'title': _titleController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? widget.part.price,
        'isNegotiable': _isNegotiable,
        'carBrand': _brandController.text.trim(),
        'carModel': _modelController.text.trim(),
        'category': _categoryController.text.trim(),
        'condition': _selectedCondition,
        'oemNumber': _oemController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descController.text.trim(),
        'contactPhone': _phoneController.text.trim(),
        'imageUrl': finalImageUrls.isNotEmpty ? finalImageUrls.first : widget.part.imageUrl,
        'images': finalImageUrls,
        'imageUrls': finalImageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _db.collection('spareParts').doc(widget.part.id).update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Listing updated successfully!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update listing. Please try again.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Edit Spare Part Ad', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Photos Section
              const Text('Part Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    GestureDetector(
                      onTap: _showImagePickerSheet,
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo_outlined, color: Color(0xFF0075FF), size: 24),
                            SizedBox(height: 4),
                            Text('Add Photo', style: TextStyle(fontSize: 11, color: Color(0xFF0075FF), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    ..._currentImages.map((url) => Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4,
                              right: 14,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _removedImages.add(url);
                                    _currentImages.remove(url);
                                  });
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('🗑️ Photo removed from listing.'),
                                      backgroundColor: Color(0xFF475569),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        )),
                    ..._newImages.map((f) => Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.file(f, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4,
                              right: 14,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _newImages.remove(f));
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('🗑️ Photo removed.'),
                                      backgroundColor: Color(0xFF475569),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Ad Title *', Icons.title),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 12),

              // Price & Negotiable Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Price (₹) *', Icons.currency_rupee),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter price' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Text('Negotiable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        Switch(
                          value: _isNegotiable,
                          activeColor: const Color(0xFF0075FF),
                          onChanged: (val) => setState(() => _isNegotiable = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Car Brand & Model Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandController,
                      decoration: _inputDecoration('Car Brand', Icons.directions_car),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _modelController,
                      decoration: _inputDecoration('Car Model', Icons.car_repair),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category & OEM Part #
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: _inputDecoration('Category', Icons.category),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _oemController,
                      decoration: _inputDecoration('OEM # (Optional)', Icons.tag),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Condition
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: _inputDecoration('Condition', Icons.build_circle_outlined),
                items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCondition = val);
                },
              ),
              const SizedBox(height: 12),

              // Location & Phone
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('Location (City, State)', Icons.location_on),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Phone Number', Icons.phone),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: _inputDecoration('Description', Icons.description),
              ),
              const SizedBox(height: 30),

              // Save Changes Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0075FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isLoading ? null : _saveChanges,
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('💾 Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
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
