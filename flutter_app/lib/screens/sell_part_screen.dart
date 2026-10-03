import 'dart:async';
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
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'location_select_screen.dart';
import 'map_location_picker_screen.dart';
import '../constants/location_coordinates_helper.dart';
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
  final TextEditingController _customModelCtrl = TextEditingController();
  final TextEditingController _customSubcategoryCtrl = TextEditingController();

  StreamSubscription<QuerySnapshot>? _categoriesSub;
  StreamSubscription<QuerySnapshot>? _brandsSub;

  double? _selectedLatitude = 13.0827;
  double? _selectedLongitude = 80.2707;
  String _selectedDistrict = 'Chennai';
  bool _isDetectingGps = false;
  GoogleMapController? _miniMapController;

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
    'Maruti Suzuki': ['Swift', 'Baleno', 'Brezza', 'Dzire', 'Ertiga', 'Wagon R', 'Alto', 'Grand Vitara', 'Ciaz', 'Fronx', 'Jimny', 'XL6', 'Ignis', 'Celerio', 'Ritz', 'Other / Custom Model'],
    'Hyundai': ['Creta', 'i20', 'Venue', 'Verna', 'Grand i10', 'Aura', 'Tucson', 'Exter', 'Alcazar', 'Santro', 'Eon', 'Other / Custom Model'],
    'Tata': ['Nexon', 'Punch', 'Harrier', 'Safari', 'Altroz', 'Tiago', 'Tigor', 'Curvv', 'Hexa', 'Indica', 'Sumo', 'Other / Custom Model'],
    'Mahindra': ['Thar', 'Scorpio-N', 'XUV700', 'Bolero', 'XUV300', 'Scorpio Classic', 'XUV400', 'Marazzo', 'Xylo', 'Other / Custom Model'],
    'Toyota': ['Innova Crysta', 'Innova Hycross', 'Fortuner', 'Hyryder', 'Glanza', 'Hilux', 'Camry', 'Etios', 'Corolla Altis', 'Other / Custom Model'],
    'Honda': ['City', 'Amaze', 'Elevate', 'WR-V', 'Jazz', 'Civic', 'BR-V', 'CR-V', 'Brio', 'Other / Custom Model'],
    'Kia': ['Seltos', 'Sonet', 'Carens', 'Carnival', 'EV6', 'Other / Custom Model'],
    'Volkswagen': ['Virtus', 'Taigun', 'Polo', 'Vento', 'Tiguan', 'Passat', 'Other / Custom Model'],
    'Skoda': ['Slavia', 'Kushaq', 'Kodiaq', 'Octavia', 'Superb', 'Rapid', 'Other / Custom Model'],
    'Ford': ['EcoSport', 'Endeavour', 'Figo', 'Aspire', 'Freestyle', 'Other / Custom Model'],
  };

  // Categories & Sub-parts (Live synced + default fallback)
  final Map<String, List<String>> _categories = {
    'Engine & Mechanical': ['Turbocharger', 'Cylinder Head', 'Pistons & Rings', 'Timing Belt & Chain', 'Engine Oil Pump', 'Fuel Injector', 'Alternator', 'Starter Motor', 'Other / Custom Component'],
    'Body & Exterior': ['Front Bumper', 'Rear Bumper', 'Headlight Assembly', 'Tail Light Assembly', 'Side Mirrors (ORVM)', 'Bonnet / Hood', 'Front Fender', 'Car Doors', 'Other / Custom Component'],
    'Lights & Electricals': ['LED Headlights', 'Fog Lamps', 'Car Battery', 'ECU (Engine Control Unit)', 'Wiring Harness', 'Power Window Motor', 'Ignition Coil', 'Other / Custom Component'],
    'Suspension & Brakes': ['Front Shock Absorbers', 'Brake Calipers & Pads', 'Brake Discs / Rotors', 'Steering Rack & Pinion', 'Lower Control Arm', 'Tie Rod Ends', 'Other / Custom Component'],
    'Interior & Dashboard': ['Steering Wheel', 'Instrument Cluster', 'Dashboard Panel', 'AC Compressor', 'AC Cooling Coil', 'Seats & Upholstery', 'Other / Custom Component'],
    'Transmission & Clutch': ['Clutch Plate & Pressure Plate', 'Gearbox Assembly', 'Flywheel', 'Driveshaft / Axle', 'Clutch Master Cylinder', 'Other / Custom Component'],
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
    _subscribeToDynamicTaxonomy();
  }

  void _subscribeToDynamicTaxonomy() {
    // 1. Categories & Subcategories Live Listener from Admin Panel
    _categoriesSub = _db.collection('topCategories').snapshots().listen((catSnap) {
      if (!mounted) return;
      for (var doc in catSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['active'] == false) continue;
        final name = (data['name'] ?? data['category'] ?? data['title'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        List<String> subList = [];
        final rawSub = data['subcategories'] ?? data['subCategories'] ?? data['subparts'] ?? data['items'] ?? data['components'];
        if (rawSub is String && rawSub.trim().isNotEmpty) {
          subList = rawSub.split(RegExp(r'[,;\n\r]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        } else if (rawSub is List) {
          subList = rawSub.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        }

        if (subList.isEmpty) {
          subList = ['$name Assembly', 'OEM $name', 'Replacement $name Parts'];
        }
        if (!subList.contains('Other / Custom Component')) {
          subList.add('Other / Custom Component');
        }

        _categories[name] = subList;
      }

      // Safety check to ensure selected values exist
      if (!_categories.containsKey(_selectedCategory)) {
        _selectedCategory = _categories.keys.first;
      }
      if (!_categories[_selectedCategory]!.contains(_selectedSubcategory)) {
        _selectedSubcategory = _categories[_selectedCategory]!.first;
      }
      setState(() {});
    }, onError: (_) {});

    // 2. Car Brands & Models / Sub-brands Live Listener from Admin Panel
    _brandsSub = _db.collection('carBrands').snapshots().listen((brandSnap) {
      if (!mounted) return;
      for (var doc in brandSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['active'] == false) continue;
        final name = (data['name'] ?? data['brand'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        List<String> modelList = [];
        final rawModels = data['models'] ?? data['subBrands'] ?? data['subbrands'] ?? data['sub_brands'] ?? data['carModels'] ?? data['variants'];
        if (rawModels is String && rawModels.trim().isNotEmpty) {
          modelList = rawModels.split(RegExp(r'[,;\n\r]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        } else if (rawModels is List) {
          modelList = rawModels.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        }

        if (modelList.isEmpty) {
          modelList = ['All Models', 'Standard Spec', 'Base Spec', 'Top Spec'];
        }
        if (!modelList.contains('Other / Custom Model')) {
          modelList.add('Other / Custom Model');
        }

        _brandModels[name] = modelList;
      }

      // Safety check to ensure selected values exist
      if (!_brandModels.containsKey(_selectedBrand)) {
        _selectedBrand = _brandModels.keys.first;
      }
      if (!_brandModels[_selectedBrand]!.contains(_selectedModel)) {
        _selectedModel = _brandModels[_selectedBrand]!.first;
      }
      setState(() {});
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _categoriesSub?.cancel();
    _brandsSub?.cancel();
    _customModelCtrl.dispose();
    _customSubcategoryCtrl.dispose();
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _oemCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isDetectingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable GPS / Location services on your phone')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission permanently denied. Enable in device settings.')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final address = await LocationCoordinatesHelper.reverseGeocode(pos.latitude, pos.longitude);

      setState(() {
        _selectedLatitude = pos.latitude;
        _selectedLongitude = pos.longitude;
        if (address != null && address.isNotEmpty) {
          _locationCtrl.text = address;
          final parts = address.split(', ');
          if (parts.length >= 2) {
            _selectedDistrict = parts[parts.length - 2];
          } else {
            _selectedDistrict = parts.first;
          }
        } else {
          _locationCtrl.text = 'GPS Pin (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';
        }
      });

      _miniMapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 14.5),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Location updated: ${_locationCtrl.text}'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not detect GPS: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetectingGps = false);
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          initialPosition: (_selectedLatitude != null && _selectedLongitude != null)
              ? LatLng(_selectedLatitude!, _selectedLongitude!)
              : const LatLng(13.0827, 80.2707),
          initialAddress: _locationCtrl.text,
        ),
      ),
    );

    if (result != null && result is LocationResult) {
      setState(() {
        _selectedLatitude = result.latitude;
        _selectedLongitude = result.longitude;
        _selectedDistrict = result.district;
        _locationCtrl.text = result.address;
      });

      _miniMapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(result.latitude, result.longitude), zoom: 14.5),
        ),
      );
    }
  }

  void _autoGenerateTitle() {
    final modelName = (_selectedModel == 'Other / Custom Model' && _customModelCtrl.text.trim().isNotEmpty)
        ? _customModelCtrl.text.trim()
        : (_selectedModel == 'Other / Custom Model' ? '' : _selectedModel);
    final subcatName = (_selectedSubcategory == 'Other / Custom Component' && _customSubcategoryCtrl.text.trim().isNotEmpty)
        ? _customSubcategoryCtrl.text.trim()
        : (_selectedSubcategory == 'Other / Custom Component' ? '' : _selectedSubcategory);

    String title = _selectedBrand;
    if (modelName.isNotEmpty) title += ' $modelName';
    if (subcatName.isNotEmpty) title += ' $subcatName';
    title += ' ($_selectedYear)';
    _titleCtrl.text = title.trim();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> pickedList = await _picker.pickMultiImage(imageQuality: 80);
        if (pickedList.isNotEmpty) {
          setState(() {
            for (final f in pickedList) {
              _selectedFiles.add(File(f.path));
            }
          });
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📸 ${pickedList.length} photo(s) added to listing!'),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          }
          return;
        }
      }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please allow Camera & Photo permissions in Android Settings to select images.'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

      final finalModel = (_selectedModel == 'Other / Custom Model' && _customModelCtrl.text.trim().isNotEmpty)
          ? _customModelCtrl.text.trim()
          : _selectedModel;
      final finalSubcategory = (_selectedSubcategory == 'Other / Custom Component' && _customSubcategoryCtrl.text.trim().isNotEmpty)
          ? _customSubcategoryCtrl.text.trim()
          : _selectedSubcategory;

      final partData = {
        'id': docRef.id,
        'title': _titleCtrl.text.trim(),
        'carBrand': _selectedBrand,
        'carModel': finalModel,
        'category': _selectedCategory,
        'subcategory': finalSubcategory,
        'condition': _selectedCondition,
        'fuelType': _selectedFuelType,
        'year': _selectedYear,
        'price': price,
        'isNegotiable': _isNegotiable,
        'location': _locationCtrl.text.trim(),
        'district': _selectedDistrict.isNotEmpty ? _selectedDistrict : _locationCtrl.text.split(',').first.trim(),
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
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

              // Car Brand & Model Cascading Section
              Builder(builder: (context) {
                final safeBrand = _brandModels.containsKey(_selectedBrand) ? _selectedBrand : _brandModels.keys.first;
                final modelsList = _brandModels[safeBrand] ?? ['Standard Spec', 'Other / Custom Model'];
                final safeModel = modelsList.contains(_selectedModel) ? _selectedModel : modelsList.first;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: safeBrand,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B), size: 24),
                      decoration: _inputDecoration('Car Brand *', Icons.directions_car_rounded),
                      items: _brandModels.keys.map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis))).toList(),
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

                    DropdownButtonFormField<String>(
                      value: safeModel,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B), size: 24),
                      decoration: _inputDecoration('Car Model / Sub-brand *', Icons.car_repair_rounded),
                      items: modelsList.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedModel = val;
                            _autoGenerateTitle();
                          });
                        }
                      },
                    ),

                    if (safeModel == 'Other / Custom Model') ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _customModelCtrl,
                        decoration: _inputDecoration('Specify Model / Sub-brand Name *', Icons.edit_rounded).copyWith(
                          hintText: 'e.g. Swift 2024 ZXi+ / Scorpio Classic S11',
                        ),
                        onChanged: (_) => _autoGenerateTitle(),
                        validator: (val) => (safeModel == 'Other / Custom Model' && (val == null || val.trim().isEmpty))
                            ? 'Please specify the vehicle model / variant'
                            : null,
                      ),
                    ],
                  ],
                );
              }),
              const SizedBox(height: 14),

              // Fuel Type & Year Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedFuelType,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B), size: 24),
                      decoration: _inputDecoration('Fuel Type', Icons.local_gas_station_rounded),
                      items: _fuelTypes.map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFuelType = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedYear,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B), size: 24),
                      decoration: _inputDecoration('Year', Icons.calendar_today_rounded),
                      items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y, overflow: TextOverflow.ellipsis))).toList(),
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
              _buildSectionHeader('Part Category & Component', 'Select the component category and exact part name'),
              const SizedBox(height: 12),

              Builder(builder: (context) {
                final safeCategory = _categories.containsKey(_selectedCategory) ? _selectedCategory : _categories.keys.first;
                final subList = _categories[safeCategory] ?? ['General Component', 'Other / Custom Component'];
                final safeSubcategory = subList.contains(_selectedSubcategory) ? _selectedSubcategory : subList.first;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: safeCategory,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B), size: 24),
                      decoration: _inputDecoration('Category *', Icons.category_rounded),
                      items: _categories.keys.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
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
                      value: safeSubcategory,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B), size: 24),
                      decoration: _inputDecoration('Subcategory / Part Component *', Icons.subdirectory_arrow_right_rounded),
                      items: subList.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSubcategory = val;
                            _autoGenerateTitle();
                          });
                        }
                      },
                    ),

                    if (safeSubcategory == 'Other / Custom Component') ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _customSubcategoryCtrl,
                        decoration: _inputDecoration('Specify Component / Subcategory Name *', Icons.build_rounded).copyWith(
                          hintText: 'e.g. Roof Rail / Window Regulator / Spoiler',
                        ),
                        onChanged: (_) => _autoGenerateTitle(),
                        validator: (val) => (safeSubcategory == 'Other / Custom Component' && (val == null || val.trim().isEmpty))
                            ? 'Please specify component or subcategory name'
                            : null,
                      ),
                    ],
                  ],
                );
              }),
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
                isExpanded: true,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B), size: 24),
                decoration: _inputDecoration('Condition *', Icons.verified_rounded),
                items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
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

              // 5. Seller Location & Map Pin
              _buildSectionHeader('Seller Location & Map Pin', 'Buyers will see your map location & calculate distance'),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location status chip
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0075FF).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFF0075FF)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _locationCtrl.text.isNotEmpty ? _locationCtrl.text : 'Select Location',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_selectedLatitude != null && _selectedLongitude != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'GPS: ${_selectedLatitude!.toStringAsFixed(4)}, ${_selectedLongitude!.toStringAsFixed(4)}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Action Buttons (Map Pick, GPS, District)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0075FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.map_rounded, size: 16),
                            label: const Text('Pick on Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: _openMapPicker,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: _isDetectingGps
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0075FF)),
                                  )
                                : const Icon(Icons.my_location_rounded, size: 16, color: Color(0xFF10B981)),
                            label: Text(_isDetectingGps ? 'Detecting...' : 'Current GPS', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: _isDetectingGps ? null : _detectCurrentLocation,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.list_alt_rounded, size: 18, color: Color(0xFF0F172A)),
                          tooltip: 'Select from City List',
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LocationSelectScreen()),
                            );
                            if (result != null && result is String) {
                              final coords = LocationCoordinatesHelper.getCoordinatesForLocation(result);
                              setState(() {
                                _locationCtrl.text = result;
                                _selectedDistrict = result;
                                _selectedLatitude = coords.latitude;
                                _selectedLongitude = coords.longitude;
                              });
                              _miniMapController?.animateCamera(
                                CameraUpdate.newLatLng(coords),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Mini Embedded Google Map Preview
                    if (_selectedLatitude != null && _selectedLongitude != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 130,
                          width: double.infinity,
                          child: Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(_selectedLatitude!, _selectedLongitude!),
                                  zoom: 13.5,
                                ),
                                zoomControlsEnabled: false,
                                scrollGesturesEnabled: false,
                                zoomGesturesEnabled: false,
                                tiltGesturesEnabled: false,
                                rotateGesturesEnabled: false,
                                myLocationButtonEnabled: false,
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('part_location'),
                                    position: LatLng(_selectedLatitude!, _selectedLongitude!),
                                  ),
                                },
                                onMapCreated: (ctrl) => _miniMapController = ctrl,
                                onTap: (_) => _openMapPicker(),
                              ),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: InkWell(
                                  onTap: _openMapPicker,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.92),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_location_alt_rounded, size: 14, color: Color(0xFF0075FF)),
                                        SizedBox(width: 4),
                                        Text('Adjust Pin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
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
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w700),
      prefixIcon: Icon(icon, color: const Color(0xFF0075FF), size: 20),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0075FF), width: 1.5)),
    );
  }
}
