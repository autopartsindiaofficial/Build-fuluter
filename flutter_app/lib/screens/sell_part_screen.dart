import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../models/spare_part.dart';
import '../services/cloudinary_service.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import 'location_select_screen.dart';
import 'auth_screen.dart';

class SellPartScreen extends StatefulWidget {
  const SellPartScreen({Key? key}) : super(key: key);

  @override
  State<SellPartScreen> createState() => _SellPartScreenState();
}

class _SellPartScreenState extends State<SellPartScreen> {
  final _formKey = GlobalKey<FormState>();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _oemCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController(text: 'Chennai, Tamil Nadu');
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _directUrlCtrl = TextEditingController();

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

  // Brand to Model Cascading Map matching React Native
  final Map<String, List<String>> _brandModels = {
    'Maruti Suzuki': ['Swift', 'Baleno', 'Brezza', 'Dzire', 'Ertiga', 'Wagon R', 'Alto', 'Grand Vitara', 'Ciaz', 'Fronx', 'Jimny', 'XL6', 'Ignis', 'Celerio', 'Ritz'],
    'Hyundai': ['Creta', 'i20', 'Venue', 'Verna', 'Grand i10', 'Aura', 'Tucson', 'Exter', 'Alcazar', 'Santro', 'Eon'],
    'Tata': ['Nexon', 'Punch', 'Harrier', 'Safari', 'Altroz', 'Tiago', 'Tigor', 'Curvv', 'Hexa', 'Indica', 'Sumo'],
    'Mahindra': ['Thar', 'Scorpio-N', 'XUV700', 'Bolero', 'XUV300', 'Scorpio Classic', 'XUV400', 'Marazzo', 'Xylo'],
    'Toyota': ['Innova Crysta', 'Innova Hycross', 'Fortuner', 'Hyryder', 'Glanza', 'Hilux', 'Camry', 'Etios', 'Corolla Altis'],
    'Honda': ['City', 'Amaze', 'Elevate', 'WR-V', 'Jazz', 'Civic', 'BR-V', 'CR-V', 'Brio'],
    'Kia': ['Seltos', 'Sonet', 'Carens', 'Carnival', 'EV6'],
    'Volkswagen': ['Virtus', 'Taigun', 'Polo', 'Vento', 'Tiguan', 'Passat'],
    'Skoda': ['Slavia', 'Kushaq', 'Kodiaq', 'Octavia', 'Superb', 'Rapid'],
    'Ford': ['EcoSport', 'Endeavour', 'Figo', 'Aspire', 'Freestyle'],
  };

  // Categories & Sub-parts matching React Native MASTER_CATEGORY_PARTS
  final Map<String, List<String>> _categories = {
    'Engine & Mechanical': ['Turbocharger', 'Cylinder Head', 'Pistons & Rings', 'Timing Belt & Chain', 'Engine Oil Pump', 'Fuel Injector', 'Alternator', 'Starter Motor'],
    'Body & Exterior': ['Front Bumper', 'Rear Bumper', 'Headlight Assembly', 'Tail Light Assembly', 'Side Mirrors (ORVM)', 'Bonnet / Hood', 'Front Fender', 'Car Doors'],
    'Lights & Electricals': ['LED Headlights', 'Fog Lamps', 'Car Battery', 'ECU (Engine Control Unit)', 'Wiring Harness', 'Power Window Motor', 'Ignition Coil'],
    'Suspension & Brakes': ['Front Shock Absorbers', 'Brake Calipers & Pads', 'Brake Discs / Rotors', 'Steering Rack & Pinion', 'Lower Control Arm', 'Tie Rod Ends'],
    'Interior & Dashboard': ['Steering Wheel', 'Instrument Cluster', 'Dashboard Panel', 'AC Compressor', 'AC Cooling Coil', 'Seats & Upholstery'],
    'Transmission & Clutch': ['Clutch Plate & Pressure Plate', 'Gearbox Assembly', 'Flywheel', 'Driveshaft / Axle', 'Clutch Master Cylinder'],
  };

  late String _selectedBrand;
  late String _selectedModel;
  late String _selectedCategory;
  late String _selectedSubcategory;
  String _selectedFuelType = 'Petrol';
  String _selectedYear = '2022';
  String _selectedCondition = 'Used - Like New';
  bool _isNegotiable = true;
  bool _isSubmitting = false;

  final List<String> _fuelTypes = ['Petrol', 'Diesel', 'CNG', 'Electric', 'Hybrid'];
  final List<String> _years = List.generate(15, (index) => (DateTime.now().year - index).toString());
  final List<String> _conditions = [
    'Brand New (OEM)',
    'Used - Like New',
    'Used - Good',
    'Refurbished',
  ];

  final List<File> _selectedFiles = [];
  final List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _selectedBrand = _brandModels.keys.first;
    _selectedModel = _brandModels[_selectedBrand]!.first;
    _selectedCategory = _categories.keys.first;
    _selectedSubcategory = _categories[_selectedCategory]!.first;
    _autoGenerateTitle();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _oemCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _directUrlCtrl.dispose();
    super.dispose();
  }

  void _autoGenerateTitle() {
    _titleCtrl.text = '$_selectedBrand $_selectedModel $_selectedSubcategory ($_selectedYear)';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _selectedFiles.add(File(picked.path));
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _addDirectUrl() {
    final url = _directUrlCtrl.text.trim();
    if (url.isNotEmpty && url.startsWith('http')) {
      setState(() {
        _imageUrls.add(url);
        _directUrlCtrl.clear();
      });
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
                title: const Text('Choose from Photo Gallery'),
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

  Future<void> _submitAd() async {
    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    final user = auth.user;

    if (user == null) {
      final loggedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      if (loggedIn != true && auth.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in with Google to post your ad.')),
        );
        return;
      }
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedFiles.isEmpty && _imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload or attach at least 1 photo of the spare part.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      List<String> finalImages = List.from(_imageUrls);

      // Upload local images via Cloudinary
      for (var f in _selectedFiles) {
        final url = await _cloudinaryService.uploadImage(f.path);
        if (url != null && url.isNotEmpty) {
          finalImages.add(url);
        }
      }

      if (finalImages.isEmpty) {
        finalImages.add('https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=800&q=80');
      }

      final double price = double.tryParse(_priceCtrl.text.replaceAll(',', '').trim()) ?? 0;
      final docRef = _db.collection('spareParts').doc();

      final partData = {
        'id': docRef.id,
        'title': _titleCtrl.text.trim(),
        'carBrand': _selectedBrand,
        'carModel': _selectedModel,
        'category': _selectedCategory,
        'subcategory': _selectedSubcategory,
        'condition': _selectedCondition,
        'fuelType': _selectedFuelType,
        'year': _selectedYear,
        'price': price,
        'isNegotiable': _isNegotiable,
        'location': _locationCtrl.text.trim(),
        'district': _locationCtrl.text.split(',').first.trim(),
        'contactName': auth.userProfile?.displayName ?? user?.displayName ?? 'Verified Seller',
        'contactPhone': _phoneCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'imageUrl': finalImages.first,
        'images': finalImages,
        'sellerId': user!.uid,
        'sellerEmail': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'oemNumber': _oemCtrl.text.trim(),
        'views': 0,
        'status': 'active',
        'verified': true,
      };

      await docRef.set(partData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Your auto spare part is now LIVE on the marketplace!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting ad: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: Text(
          lang.t('postAd'),
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Photo Section
              _buildSectionHeader('Part Photos *', 'Add clear photos showing part labels & condition'),
              const SizedBox(height: 8),
              SizedBox(
                height: 105,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Add Photo Button
                    GestureDetector(
                      onTap: _showImagePickerSheet,
                      child: Container(
                        width: 105,
                        height: 105,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo_outlined, color: Color(0xFF0075FF), size: 28),
                            SizedBox(height: 4),
                            Text('Add Photo', style: TextStyle(color: Color(0xFF0075FF), fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),

                    // Local Picked Files
                    ..._selectedFiles.map((f) => Stack(
                          children: [
                            Container(
                              width: 105,
                              height: 105,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.file(f, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4,
                              right: 14,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedFiles.remove(f)),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        )),

                    // Attached Web URLs
                    ..._imageUrls.map((url) => Stack(
                          children: [
                            Container(
                              width: 105,
                              height: 105,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.network(url, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4,
                              right: 14,
                              child: GestureDetector(
                                onTap: () => setState(() => _imageUrls.remove(url)),
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

              // 2. Vehicle Compatibility
              _buildSectionHeader('Vehicle Compatibility', 'Select the car model this part fits'),
              const SizedBox(height: 10),

              // Car Brand Dropdown
              DropdownButtonFormField<String>(
                value: _selectedBrand,
                decoration: _inputDecoration('Car Brand *', Icons.directions_car),
                items: _brandModels.keys.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedBrand = val;
                      _selectedModel = _brandModels[val]!.first;
                      _autoGenerateTitle();
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Car Model Dropdown (Cascading)
              DropdownButtonFormField<String>(
                value: _selectedModel,
                decoration: _inputDecoration('Car Model *', Icons.car_repair),
                items: _brandModels[_selectedBrand]!.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedModel = val;
                      _autoGenerateTitle();
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Fuel Type & Year Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedFuelType,
                      decoration: _inputDecoration('Fuel Type', Icons.local_gas_station),
                      items: _fuelTypes.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFuelType = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedYear,
                      decoration: _inputDecoration('Year', Icons.calendar_today),
                      items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedYear = val;
                            _autoGenerateTitle();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 3. Category & Part Type
              _buildSectionHeader('Part Classification', 'Choose category and specific spare component'),
              const SizedBox(height: 10),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _inputDecoration('Category *', Icons.category),
                items: _categories.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                      _selectedSubcategory = _categories[val]!.first;
                      _autoGenerateTitle();
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Subcategory Dropdown (Cascading)
              DropdownButtonFormField<String>(
                value: _selectedSubcategory,
                decoration: _inputDecoration('Component / Subcategory *', Icons.subdirectory_arrow_right),
                items: _categories[_selectedCategory]!.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedSubcategory = val;
                      _autoGenerateTitle();
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Part Condition Chips
              const Text('Part Condition *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _conditions.map((cond) {
                  final isSelected = _selectedCondition == cond;
                  return ChoiceChip(
                    label: Text(cond),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0075FF),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE2E8F0))),
                    onSelected: (val) {
                      if (val) setState(() => _selectedCondition = cond);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // 4. Listing Details & Pricing
              _buildSectionHeader('Pricing & Details', 'Set an attractive market price'),
              const SizedBox(height: 10),

              // Title (Auto-generated & Editable)
              TextFormField(
                controller: _titleCtrl,
                decoration: _inputDecoration('Ad Title *', Icons.title),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter ad title' : null,
              ),
              const SizedBox(height: 12),

              // Price & Negotiable Switch
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Price (₹) *', Icons.currency_rupee),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter price' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Checkbox(
                          value: _isNegotiable,
                          activeColor: const Color(0xFF0075FF),
                          onChanged: (val) => setState(() => _isNegotiable = val ?? true),
                        ),
                        const Flexible(
                          child: Text('Negotiable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // OEM Part Number (Optional)
              TextFormField(
                controller: _oemCtrl,
                decoration: _inputDecoration('OEM Part # (Optional)', Icons.tag),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: _inputDecoration('Detailed Description', Icons.description),
              ),

              const SizedBox(height: 20),

              // 5. Location & Contact
              _buildSectionHeader('Location & Contact', 'Buyers in this area will see your listing'),
              const SizedBox(height: 10),

              // Location Picker Field
              InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LocationSelectScreen()),
                  );
                  if (result != null && result is String) {
                    setState(() => _locationCtrl.text = result);
                  }
                },
                child: IgnorePointer(
                  child: TextFormField(
                    controller: _locationCtrl,
                    decoration: _inputDecoration('Location (City, State) *', Icons.location_on),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Seller Phone Number
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Mobile Phone (For direct calls)', Icons.phone),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0075FF),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSubmitting ? null : _submitAd,
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                            SizedBox(width: 12),
                            Text('Publishing Your Ad...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : const Text(
                          '🚀 Post Spare Part Ad Now',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0075FF), width: 1.5),
      ),
    );
  }
}
