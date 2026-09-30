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

  // Brand to Model Cascading Map (Live synced + default fallback)
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

  // Categories & Sub-parts (Live synced + default fallback)
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

  @override
  void initState() {
    super.initState();
    _selectedBrand = _brandModels.keys.first;
    _selectedModel = _brandModels[_selectedBrand]!.first;
    _selectedCategory = _categories.keys.first;
    _selectedSubcategory = _categories[_selectedCategory]!.first;
    _autoGenerateTitle();
    _loadDynamicTaxonomy();
  }

  Future<void> _loadDynamicTaxonomy() async {
    try {
      // Sync dynamic topCategories from admin
      final catSnap = await _db.collection('topCategories').where('active', isEqualTo: true).get();
      if (catSnap.docs.isNotEmpty) {
        for (var doc in catSnap.docs) {
          final data = doc.data();
          final name = (data['name'] as String? ?? '').trim();
          if (name.isNotEmpty) {
            List<String> subList = [];
            if (data['subcategories'] is String && (data['subcategories'] as String).isNotEmpty) {
              subList = (data['subcategories'] as String).split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            } else if (data['subcategories'] is List) {
              subList = List<String>.from(data['subcategories']);
            }
            if (subList.isEmpty) {
              subList = ['$name Assembly', 'OEM $name', 'Replacement $name Parts'];
            }
            _categories[name] = subList;
          }
        }
      }

      // Sync dynamic carBrands from admin
      final brandSnap = await _db.collection('carBrands').where('active', isEqualTo: true).get();
      if (brandSnap.docs.isNotEmpty) {
        for (var doc in brandSnap.docs) {
          final data = doc.data();
          final name = (data['name'] as String? ?? '').trim();
          if (name.isNotEmpty) {
            List<String> modelList = [];
            if (data['models'] is String && (data['models'] as String).isNotEmpty) {
              modelList = (data['models'] as String).split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            } else if (data['models'] is List) {
              modelList = List<String>.from(data['models']);
            }
            if (modelList.isEmpty) {
              modelList = ['All Models', 'Standard Spec', 'Base Spec', 'Top Spec'];
            }
            _brandModels[name] = modelList;
          }
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _oemCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
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
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📸 Photo added to listing!'),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: const [
                  Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF0075FF), size: 24),
                  SizedBox(width: 8),
                  Text('Add Part Photos', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF0075FF).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0075FF)),
                ),
                title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Snap clear photo of OEM label & connectors', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF10B981)),
                ),
                title: const Text('Choose from Photo Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Select multiple photos from device', style: TextStyle(fontSize: 12)),
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

    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least 1 photo of the spare part.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      List<String> finalImages = [];

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
            content: Text('🎉 Ad posted successfully! Your part is now live on the marketplace.'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Ad Posted Successfully! 🎉',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F172A)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Your spare part "${_titleCtrl.text.trim()}" is now LIVE on Auto Parts India marketplace for buyers across India.',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0075FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: const Text('Done / View Marketplace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to post listing. Please check your connection and try again.'), backgroundColor: Colors.red),
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
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          lang.t('postAd'),
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A)),
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
              // 1. Photo Section
              _buildSectionHeader('Part Photos *', 'Add photos showing OEM tags, connectors & condition'),
              const SizedBox(height: 10),
              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Add Photo Trigger Card
                    GestureDetector(
                      onTap: _showImagePickerSheet,
                      child: Container(
                        width: 105,
                        height: 105,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo_rounded, color: Color(0xFF0075FF), size: 28),
                            SizedBox(height: 6),
                            Text('Add Photo', style: TextStyle(color: Color(0xFF0075FF), fontSize: 11, fontWeight: FontWeight.w800)),
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
                                borderRadius: BorderRadius.circular(16),
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
                                  setState(() => _selectedFiles.remove(f));
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
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Vehicle Compatibility
              _buildSectionHeader('Vehicle Compatibility', 'Select the exact automobile model this part belongs to'),
              const SizedBox(height: 12),

              // Car Brand Dropdown
              DropdownButtonFormField<String>(
                value: _selectedBrand,
                decoration: _inputDecoration('Car Brand *', Icons.directions_car_rounded),
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
              const SizedBox(height: 14),

              // Car Model Dropdown (Cascading)
              DropdownButtonFormField<String>(
                value: _selectedModel,
                decoration: _inputDecoration('Car Model *', Icons.car_repair_rounded),
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
              const SizedBox(height: 14),

              // Fuel Type & Year Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedFuelType,
                      decoration: _inputDecoration('Fuel Type', Icons.local_gas_station_rounded),
                      items: _fuelTypes.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFuelType = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedYear,
                      decoration: _inputDecoration('Year', Icons.calendar_today_rounded),
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

              const SizedBox(height: 24),

              // 3. Category & Part Identification
              _buildSectionHeader('Part Category', 'Select the component category and type'),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _inputDecoration('Category *', Icons.category_rounded),
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
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _selectedSubcategory,
                decoration: _inputDecoration('Subcategory *', Icons.subdirectory_arrow_right_rounded),
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
              const SizedBox(height: 14),

              // OEM Part Number Field
              TextFormField(
                controller: _oemCtrl,
                decoration: _inputDecoration('OEM / Part Number (Recommended)', Icons.tag_rounded).copyWith(
                  hintText: 'e.g. 71711M68K00-799',
                ),
              ),

              const SizedBox(height: 24),

              // 4. Listing Details & Pricing
              _buildSectionHeader('Pricing & Condition', 'Set your desired price and terms'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _titleCtrl,
                decoration: _inputDecoration('Listing Title *', Icons.title_rounded),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: _inputDecoration('Condition *', Icons.verified_rounded),
                items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCondition = val);
                },
              ),
              const SizedBox(height: 14),

              // Price Row with Negotiable Switch
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Price (₹) *', Icons.currency_rupee_rounded).copyWith(
                        hintText: 'e.g. 3500',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter price';
                        if (double.tryParse(val.replaceAll(',', '').trim()) == null) return 'Invalid number';
                        return null;
                      },
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
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Describe condition, mileage used, warranty, reason for selling...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),

              const SizedBox(height: 24),

              // 5. Seller Location & Contact
              _buildSectionHeader('Seller Location & Contact', 'Buyers will call or chat with you here'),
              const SizedBox(height: 12),

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
                    decoration: _inputDecoration('Location / District *', Icons.location_on_rounded).copyWith(
                      suffixIcon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Contact Phone (Optional)', Icons.call_rounded).copyWith(
                  hintText: 'Buyers can direct call you if provided',
                ),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submitAd,
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Publishing Spare Part...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.cloud_upload_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('POST AUTO SPARE PART NOW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
          ],
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
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
