import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_colors.dart';
import '../models/spare_part.dart';
import '../providers/language_provider.dart';
import '../constants/location_coordinates_helper.dart';
import 'product_detail_screen.dart';
import 'location_select_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategory;
  final String? initialBrand;
  final String? initialLocation;

  const SearchScreen({
    Key? key,
    this.initialQuery,
    this.initialCategory,
    this.initialBrand,
    this.initialLocation,
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All Categories';
  String _selectedBrand = 'All Brands';
  String _selectedCondition = 'All Conditions';
  String _selectedLocation = 'All India';
  String _sortBy = 'newest'; // 'newest', 'price_low', 'price_high', 'distance'
  List<String> _recentSearches = [];
  Position? _userPosition;

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

  static const Map<String, String> _defaultBrandLogos = {
    'maruti': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/Suzuki_logo_2.svg/320px-Suzuki_logo_2.svg.png',
    'maruti suzuki': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/Suzuki_logo_2.svg/320px-Suzuki_logo_2.svg.png',
    'hyundai': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Hyundai_Motor_Company_logo.svg/320px-Hyundai_Motor_Company_logo.svg.png',
    'tata': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8e/Tata_logo.svg/320px-Tata_logo.svg.png',
    'tata motors': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8e/Tata_logo.svg/320px-Tata_logo.svg.png',
    'mahindra': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/Mahindra_%26_Mahindra_Logo.svg/320px-Mahindra_%26_Mahindra_Logo.svg.png',
    'toyota': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ee/Toyota_logo_%282020%29.svg/320px-Toyota_logo_%282020%29.svg.png',
    'honda': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Honda_Logo.svg/320px-Honda_Logo.svg.png',
    'kia': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/KIA_logo2.svg/320px-KIA_logo2.svg.png',
    'volkswagen': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Volkswagen_logo_2019.svg/320px-Volkswagen_logo_2019.svg.png',
    'skoda': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/75/Skoda_Auto_logo_%282023%29.svg/320px-Skoda_Auto_logo_%282023%29.svg.png',
    'ford': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Ford_motor_company_logo.svg/320px-Ford_motor_company_logo.svg.png',
    'renault': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b7/Renault_2021.svg/320px-Renault_2021.svg.png',
    'nissan': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Nissan_2020_logo.svg/320px-Nissan_2020_logo.svg.png',
    'bmw': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/BMW.svg/320px-BMW.svg.png',
    'mercedes': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Mercedes-Logo.svg/320px-Mercedes-Logo.svg.png',
    'mercedes-benz': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Mercedes-Logo.svg/320px-Mercedes-Logo.svg.png',
    'audi': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/Audi-Logo_2016.svg/320px-Audi-Logo_2016.svg.png',
  };

  final List<Map<String, dynamic>> _defaultCategoriesList = [
    {
      'name': 'Engine & Mechanical',
      'icon': Icons.engineering_rounded,
      'color': Color(0xFFEF4444),
      'subtitle': 'Pistons, Filters, Belts',
    },
    {
      'name': 'Body & Exterior',
      'icon': Icons.directions_car_rounded,
      'color': Color(0xFF0075FF),
      'subtitle': 'Bumpers, Bonnets, Doors',
    },
    {
      'name': 'Lights & Electricals',
      'icon': Icons.highlight_rounded,
      'color': Color(0xFFF59E0B),
      'subtitle': 'Headlights, Tail lamps',
    },
    {
      'name': 'Suspension & Brakes',
      'icon': Icons.build_circle_rounded,
      'color': Color(0xFF10B981),
      'subtitle': 'Discs, Pads, Shocks',
    },
    {
      'name': 'Interior & Dashboard',
      'icon': Icons.airline_seat_recline_extra_rounded,
      'color': Color(0xFF8B5CF6),
      'subtitle': 'Seats, Consoles, Audio',
    },
    {
      'name': 'Transmission & Clutch',
      'icon': Icons.settings_suggest_rounded,
      'color': Color(0xFF06B6D4),
      'subtitle': 'Clutch plates, Gearbox',
    },
    {
      'name': 'AC & Cooling',
      'icon': Icons.ac_unit_rounded,
      'color': Color(0xFF3B82F6),
      'subtitle': 'Compressors, Radiators',
    },
    {
      'name': 'Wheels & Tyres',
      'icon': Icons.tire_repair_rounded,
      'color': Color(0xFF64748B),
      'subtitle': 'Alloys, Rims, Hubs',
    },
  ];

  final List<String> _popularBrands = [
    'All Brands',
    'Maruti Suzuki',
    'Hyundai',
    'Tata',
    'Mahindra',
    'Toyota',
    'Honda',
    'Kia',
    'Volkswagen',
    'Skoda',
    'Ford',
  ];

  final List<String> _categories = [
    'All Categories',
    'Engine & Mechanical',
    'Body & Exterior',
    'Lights & Electricals',
    'Suspension & Brakes',
    'Interior & Dashboard',
    'Transmission & Clutch',
  ];

  final List<String> _popularLocations = [
    'All India',
    'Chennai',
    'Coimbatore',
    'Madurai',
    'Salem',
    'Tiruchirappalli',
    'Tiruppur',
    'Erode',
    'Vellore',
    'Bengaluru',
    'Hyderabad',
    'Mumbai',
    'Delhi NCR',
  ];

  final List<String> _trendingSuggestions = [
    'Swift Bumper',
    'Creta Headlight',
    'Thar Grille',
    'Innova Brake Disc',
    'Nexon Tail Light',
    'Brezza Mirror',
    'Fortuner Shock Absorber',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) _searchCtrl.text = widget.initialQuery!;
    if (widget.initialCategory != null) _selectedCategory = widget.initialCategory!;
    if (widget.initialBrand != null) _selectedBrand = widget.initialBrand!;
    if (widget.initialLocation != null && widget.initialLocation!.isNotEmpty) {
      _selectedLocation = widget.initialLocation!;
    } else {
      _loadSavedLocation();
    }
    _loadRecentSearches();
    _loadDynamicFilters();
    _detectUserPosition();
  }

  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('user_selected_city');
      if (saved != null && saved.isNotEmpty && widget.initialLocation == null && mounted) {
        setState(() => _selectedLocation = saved);
      }
    } catch (_) {}
  }

  Future<void> _detectUserPosition() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getLastKnownPosition();
        if (pos != null && mounted) {
          setState(() => _userPosition = pos);
        }
      }
    } catch (_) {}
  }

  LatLng _getUserReferenceCoords() {
    if (_userPosition != null) {
      return LatLng(_userPosition!.latitude, _userPosition!.longitude);
    }
    if (_selectedLocation != 'All India' && _selectedLocation.isNotEmpty) {
      return LocationCoordinatesHelper.getCoordinatesForLocation(_selectedLocation, _selectedLocation);
    }
    return const LatLng(13.0827, 80.2707); // Default Chennai/TN Hub
  }

  double _getDistanceForPart(SparePart part) {
    final ref = _getUserReferenceCoords();
    final lat = part.latitude ?? LocationCoordinatesHelper.getCoordinatesForLocation(part.location, part.district).latitude;
    final lng = part.longitude ?? LocationCoordinatesHelper.getCoordinatesForLocation(part.location, part.district).longitude;
    return LocationCoordinatesHelper.calculateDistanceInKm(ref.latitude, ref.longitude, lat, lng);
  }

  Future<void> _loadDynamicFilters() async {
    try {
      final catSnap = await _db.collection('topCategories').where('active', isEqualTo: true).get();
      if (catSnap.docs.isNotEmpty) {
        for (var doc in catSnap.docs) {
          final name = (doc.data()['name'] as String? ?? '').trim();
          if (name.isNotEmpty && !_categories.contains(name)) {
            _categories.add(name);
          }
        }
      }

      final brandSnap = await _db.collection('carBrands').where('active', isEqualTo: true).get();
      if (brandSnap.docs.isNotEmpty) {
        for (var doc in brandSnap.docs) {
          final name = (doc.data()['name'] as String? ?? '').trim();
          if (name.isNotEmpty && !_popularBrands.contains(name)) {
            _popularBrands.add(name);
          }
        }
      }

      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('recent_part_searches') ?? [];
      setState(() => _recentSearches = list);
    } catch (_) {}
  }

  Future<void> _saveSearchQuery(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      var list = prefs.getStringList('recent_part_searches') ?? [];
      list.remove(clean);
      list.insert(0, clean);
      if (list.length > 8) list = list.sublist(0, 8);
      await prefs.setStringList('recent_part_searches', list);
      setState(() => _recentSearches = list);
    } catch (_) {}
  }

  Future<void> _clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_part_searches');
      setState(() => _recentSearches = []);
    } catch (_) {}
  }

  void _clearSearch() {
    setState(() {
      _searchCtrl.clear();
      _selectedCategory = 'All Categories';
      _selectedBrand = 'All Brands';
      _selectedLocation = 'All India';
      _selectedCondition = 'All Conditions';
      _sortBy = 'newest';
    });
  }

  bool get _isSearchActive {
    return _searchCtrl.text.trim().isNotEmpty ||
        _selectedCategory != 'All Categories' ||
        _selectedBrand != 'All Brands' ||
        _selectedLocation != 'All India' ||
        _selectedCondition != 'All Conditions';
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCategory != 'All Categories') count++;
    if (_selectedBrand != 'All Brands') count++;
    if (_selectedCondition != 'All Conditions') count++;
    if (_selectedLocation != 'All India') count++;
    if (_sortBy != 'newest') count++;
    return count;
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(dt);
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSelectScreen(selectedLocation: _selectedLocation),
      ),
    );
    if (result != null && result is String && mounted) {
      setState(() {
        _selectedLocation = result;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_selected_city', result);
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.tune_rounded, color: Color(0xFF0075FF), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Filters & Location',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'All Categories';
                        _selectedBrand = 'All Brands';
                        _selectedCondition = 'All Conditions';
                        _selectedLocation = 'All India';
                        _sortBy = 'newest';
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Reset All', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFF1F5F9)),
              Expanded(
                child: ListView(
                  children: [
                    // Location Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Location / City', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                        TextButton.icon(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          icon: const Icon(Icons.map_rounded, size: 14, color: Color(0xFF0075FF)),
                          label: const Text('Map / GPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0075FF))),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LocationSelectScreen(selectedLocation: _selectedLocation)),
                            );
                            if (result != null && result is String) {
                              setModalState(() => _selectedLocation = result);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _popularLocations.map((loc) {
                        return _buildModalChip(loc, loc, _selectedLocation, (val) => setModalState(() => _selectedLocation = val));
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Sort By
                    const Text('Sort By', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildModalChip('newest', '✨ Newest First', _sortBy, (val) => setModalState(() => _sortBy = val)),
                        _buildModalChip('price_low', '₹ Price: Low to High', _sortBy, (val) => setModalState(() => _sortBy = val)),
                        _buildModalChip('price_high', '₹ Price: High to Low', _sortBy, (val) => setModalState(() => _sortBy = val)),
                        if (_userPosition != null)
                          _buildModalChip('distance', '📍 Nearest to Me', _sortBy, (val) => setModalState(() => _sortBy = val)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Condition
                    const Text('Part Condition', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildModalChip('All Conditions', 'All', _selectedCondition, (val) => setModalState(() => _selectedCondition = val)),
                        _buildModalChip('Brand New', '✨ Brand New', _selectedCondition, (val) => setModalState(() => _selectedCondition = val)),
                        _buildModalChip('Used', '🔧 Used / Pre-owned', _selectedCondition, (val) => setModalState(() => _selectedCondition = val)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Car Brand
                    const Text('Car Brand', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _popularBrands.map((b) {
                        return _buildModalChip(b, b, _selectedBrand, (val) => setModalState(() => _selectedBrand = val));
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Category
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _categories.map((c) {
                        return _buildModalChip(c, c, _selectedCategory, (val) => setModalState(() => _selectedCategory = val));
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0075FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalChip(String value, String label, String currentSelected, Function(String) onSelect) {
    final isSelected = currentSelected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0075FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            if (_isSearchActive) {
              _clearSearch();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        titleSpacing: 0,
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: false,
            textInputAction: TextInputAction.search,
            onChanged: (val) {
              setState(() {});
            },
            onSubmitted: (val) {
              _saveSearchQuery(val);
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'Search spare parts, car, city (e.g. Swift Bumper Chennai)...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0075FF), size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel_rounded, color: Color(0xFF94A3B8), size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          // Filter Trigger with active count badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: Color(0xFF0F172A), size: 22),
                onPressed: _showFilterModal,
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  top: 10,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0075FF),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_activeFilterCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Row(
              children: [
                // Quick Location Pill
                InkWell(
                  onTap: _openLocationPicker,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: _selectedLocation != 'All India' ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedLocation != 'All India' ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: _selectedLocation != 'All India' ? const Color(0xFF0075FF) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            _selectedLocation,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _selectedLocation != 'All India' ? const Color(0xFF0075FF) : const Color(0xFF334155),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
                if (_selectedLocation != 'All India') ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() => _selectedLocation = 'All India'),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  _selectedLocation == 'All India' ? 'All India Market' : 'Location Active',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isSearchActive ? _buildSearchResultsView() : _buildDiscoveryView(),
    );
  }

  // 1. Initial Discovery View (Shown before searching: Categories, Car Brands & Locations)
  Widget _buildDiscoveryView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Trending Search Chips
        Row(
          children: const [
            Icon(Icons.trending_up_rounded, color: Color(0xFF0075FF), size: 16),
            SizedBox(width: 6),
            Text(
              'Trending Searches',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF334155)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _trendingSuggestions.map((s) {
            return GestureDetector(
              onTap: () {
                _searchCtrl.text = s;
                _saveSearchQuery(s);
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_rounded, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      s,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Recent Searches
        if (_recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.history_rounded, color: Color(0xFF64748B), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Recent Searches',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF334155)),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _clearRecentSearches,
                child: const Text('Clear', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _recentSearches.map((q) {
              return GestureDetector(
                onTap: () {
                  _searchCtrl.text = q;
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_rounded, size: 12, color: Color(0xFF0075FF)),
                      const SizedBox(width: 4),
                      Text(q, style: const TextStyle(fontSize: 11.5, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // 2. Browse by City / Location Rail
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Browse by City / Location',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            GestureDetector(
              onTap: _openLocationPicker,
              child: const Text('Map / GPS', style: TextStyle(fontSize: 12, color: Color(0xFF0075FF), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: _popularLocations.map((loc) {
            final isSelected = _selectedLocation == loc;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedLocation = loc;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0075FF) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      loc == 'All India' ? Icons.public_rounded : Icons.location_on_rounded,
                      size: 13,
                      color: isSelected ? Colors.white : const Color(0xFF0075FF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      loc,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // 3. Explore by Categories Section (with Logos & Icons)
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            const Text(
              'Explore by Categories',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _defaultCategoriesList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final cat = _defaultCategoriesList[index];
            final Color catColor = cat['color'] as Color;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = cat['name'];
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(cat['icon'] as IconData, color: catColor, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            cat['name'],
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cat['subtitle'],
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // 4. Popular Car Brands (with Logos)
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            const Text(
              'Browse by Car Brands',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        StreamBuilder<QuerySnapshot>(
          stream: _db.collection('carBrands').snapshots(),
          builder: (context, brandSnap) {
            List<Map<String, dynamic>> brandsList = [];

            if (brandSnap.hasData && brandSnap.data!.docs.isNotEmpty) {
              brandsList = brandSnap.data!.docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                return {...data, 'id': d.id};
              }).where((d) => d['active'] != false).toList();

              brandsList.sort((a, b) => ((a['order'] ?? 0) as num).compareTo((b['order'] ?? 0) as num));
            }

            // Fallback to top Indian brands if Firestore collection is empty
            if (brandsList.isEmpty) {
              brandsList = [
                {'name': 'Maruti Suzuki', 'logoUrl': _defaultBrandLogos['maruti suzuki']},
                {'name': 'Hyundai', 'logoUrl': _defaultBrandLogos['hyundai']},
                {'name': 'Tata Motors', 'logoUrl': _defaultBrandLogos['tata']},
                {'name': 'Mahindra', 'logoUrl': _defaultBrandLogos['mahindra']},
                {'name': 'Toyota', 'logoUrl': _defaultBrandLogos['toyota']},
                {'name': 'Honda', 'logoUrl': _defaultBrandLogos['honda']},
                {'name': 'Kia', 'logoUrl': _defaultBrandLogos['kia']},
                {'name': 'Volkswagen', 'logoUrl': _defaultBrandLogos['volkswagen']},
                {'name': 'Skoda', 'logoUrl': _defaultBrandLogos['skoda']},
                {'name': 'Ford', 'logoUrl': _defaultBrandLogos['ford']},
                {'name': 'Renault', 'logoUrl': _defaultBrandLogos['renault']},
                {'name': 'Nissan', 'logoUrl': _defaultBrandLogos['nissan']},
              ];
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: brandsList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.05,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final brand = brandsList[index];
                final brandName = brand['name'] ?? '';
                final String? logoUrl = _resolveBrandLogo(brand);

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedBrand = brandName;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: logoUrl != null && logoUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: logoUrl,
                                    height: 38,
                                    width: 48,
                                    fit: BoxFit.contain,
                                    placeholder: (_, __) => const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF0075FF)),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => const Icon(Icons.directions_car_rounded, size: 28, color: Color(0xFF0075FF)),
                                  )
                                : const Icon(Icons.directions_car_rounded, size: 28, color: Color(0xFF0075FF)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          brandName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  String? _resolveBrandLogo(Map<String, dynamic> brand) {
    final direct = (brand['logoUrl'] ?? brand['imageUrl'] ?? brand['iconUrl'] ?? brand['logo'] ?? brand['image'])?.toString().trim();
    if (direct != null && direct.isNotEmpty && direct.startsWith('http')) {
      return direct;
    }
    final name = (brand['name'] ?? '').toString().trim().toLowerCase();
    for (var key in _defaultBrandLogos.keys) {
      if (name == key || name.contains(key) || key.contains(name)) {
        return _defaultBrandLogos[key];
      }
    }
    return null;
  }

  // 2. Search Results View (Shown AFTER searching with Location-Aware Rectangular Ad Cards)
  Widget _buildSearchResultsView() {
    return Column(
      children: [
        // Active Filter Chips & Reset Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              const Icon(Icons.filter_list_rounded, size: 14, color: Color(0xFF0075FF)),
              const SizedBox(width: 6),
              const Text('Active: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_searchCtrl.text.isNotEmpty)
                        _buildFilterBadge('Query: "${_searchCtrl.text}"', () {
                          _searchCtrl.clear();
                          setState(() {});
                        }),
                      if (_selectedLocation != 'All India')
                        _buildFilterBadge('📍 $_selectedLocation', () {
                          setState(() => _selectedLocation = 'All India');
                        }),
                      if (_selectedBrand != 'All Brands')
                        _buildFilterBadge(_selectedBrand, () {
                          setState(() => _selectedBrand = 'All Brands');
                        }),
                      if (_selectedCategory != 'All Categories')
                        _buildFilterBadge(_selectedCategory, () {
                          setState(() => _selectedCategory = 'All Categories');
                        }),
                      if (_selectedCondition != 'All Conditions')
                        _buildFilterBadge(_selectedCondition, () {
                          setState(() => _selectedCondition = 'All Conditions');
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _clearSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Clear All', style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),

        // Live Firestore Ads Stream with Full Accuracy Filter Logic
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('spareParts').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF0075FF)));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              var parts = snapshot.data!.docs.map((d) => SparePart.fromFirestore(d)).toList();

              // 1. Core Validity & Deletion Filter (Accurate ad display logic)
              parts = parts.where((p) {
                if (p.isDeleted == true) return false;
                final s = p.status.toLowerCase().trim();
                if (s == 'inactive' || s == 'rejected' || s == 'deleted' || s == 'hidden') return false;
                return true;
              }).toList();

              // 2. Multi-token Smart Search (Matches Title, Brand, Model, Category, Subcategory, Location, District, OEM, Description)
              final query = _searchCtrl.text.trim().toLowerCase();
              if (query.isNotEmpty) {
                final tokens = query.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
                parts = parts.where((p) {
                  final searchableContent = [
                    p.title,
                    p.carBrand,
                    p.carModel,
                    p.category,
                    p.subcategory,
                    p.location,
                    p.district,
                    p.oemNumber ?? '',
                    p.description ?? '',
                  ].join(' ').toLowerCase();

                  return tokens.every((token) => searchableContent.contains(token));
                }).toList();
              }

              // 3. Category Filter
              if (_selectedCategory != 'All Categories') {
                parts = parts.where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
              }

              // 4. Brand Filter
              if (_selectedBrand != 'All Brands') {
                parts = parts.where((p) => p.carBrand.toLowerCase() == _selectedBrand.toLowerCase()).toList();
              }

              // 5. Condition Filter
              if (_selectedCondition != 'All Conditions') {
                parts = parts.where((p) {
                  if (_selectedCondition == 'Brand New') {
                    return p.condition.toLowerCase().contains('new');
                  } else {
                    return !p.condition.toLowerCase().contains('new');
                  }
                }).toList();
              }

              // 6. Location-Aware Partition: User's location ads first, then nearby ads
              final userRefCoords = _getUserReferenceCoords();
              final locQuery = _selectedLocation.trim().toLowerCase();
              final primaryCity = locQuery.split(',').first.trim();

              final List<SparePart> localParts = [];
              final List<SparePart> nearbyParts = [];

              if (_selectedLocation == 'All India') {
                if (_userPosition != null) {
                  for (var p in parts) {
                    final dist = _getDistanceForPart(p);
                    if (dist <= 25.0) {
                      localParts.add(p);
                    } else {
                      nearbyParts.add(p);
                    }
                  }
                } else {
                  localParts.addAll(parts);
                }
              } else {
                for (var p in parts) {
                  final fullLoc = '${p.location} ${p.district}'.toLowerCase();
                  final dist = _getDistanceForPart(p);
                  if (fullLoc.contains(locQuery) || fullLoc.contains(primaryCity) || primaryCity.contains(p.district.toLowerCase()) || dist <= 25.0) {
                    localParts.add(p);
                  } else {
                    nearbyParts.add(p);
                  }
                }
              }

              // Sort local parts
              if (_sortBy == 'price_low') {
                localParts.sort((a, b) => a.price.compareTo(b.price));
                nearbyParts.sort((a, b) => a.price.compareTo(b.price));
              } else if (_sortBy == 'price_high') {
                localParts.sort((a, b) => b.price.compareTo(a.price));
                nearbyParts.sort((a, b) => b.price.compareTo(a.price));
              } else {
                localParts.sort((a, b) {
                  if (a.isSold != b.isSold) return a.isSold ? 1 : -1;
                  return b.createdAt.compareTo(a.createdAt);
                });
                // ALWAYS sort nearby ads by closest proximity to user!
                nearbyParts.sort((a, b) {
                  if (a.isSold != b.isSold) return a.isSold ? 1 : -1;
                  final distA = _getDistanceForPart(a);
                  final distB = _getDistanceForPart(b);
                  return distA.compareTo(distB);
                });
              }

              if (localParts.isEmpty && nearbyParts.isEmpty) {
                return _buildEmptyState();
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // Total result count summary
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${parts.length} Spare ${parts.length == 1 ? 'Part' : 'Parts'} Found',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        if (_selectedLocation != 'All India')
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF0075FF)),
                              const SizedBox(width: 3),
                              Text(
                                'Location: $_selectedLocation',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0075FF)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // 1. Local User Location Ads (Shown First)
                  if (localParts.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 14,
                          decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedLocation == 'All India' ? 'Direct Matches' : 'In $_selectedLocation (${localParts.length})',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Text('Local Listings', style: TextStyle(color: Color(0xFF047857), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...localParts.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRectangularPartCard(p, isLocal: true),
                    )),
                  ] else if (_selectedLocation != 'All India') ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF0075FF), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No matching parts inside $_selectedLocation. Showing closest matches nearby (nearest first):',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 2. Nearby Neighboring Ads (Shown Second, sorted by distance)
                  if (nearbyParts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 14,
                          decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Nearby Spares from Surrounding Areas (${nearbyParts.length})',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Text('Nearest First', style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...nearbyParts.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRectangularPartCard(p, isLocal: false),
                    )),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBadge(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 13, color: Color(0xFF1D4ED8)),
          ),
        ],
      ),
    );
  }

  // Rectangular Ad Card with Accurate Status, Sold Overlay & Location Distance
  Widget _buildRectangularPartCard(SparePart part, {bool isLocal = false}) {
    final isNew = part.condition.toLowerCase().contains('new');
    final double? distance = _getDistanceForPart(part);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(part: part)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Rectangular Photo on Left (120 x 120)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: part.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0075FF)),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.car_repair_rounded, color: Color(0xFF94A3B8), size: 36),
                      ),
                    ),

                    // Sold Overlay Badge
                    if (part.isSold)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SOLD',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                          ),
                        ),
                      )
                    else
                      // Condition Badge on Photo
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isNew ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            isNew ? 'Brand New' : 'Used',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),

                    // Image count if > 1
                    if (part.imageUrls.length > 1)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_library_rounded, size: 10, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                '${part.imageUrls.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 2. Details Column on Right
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      part.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: part.isSold ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Car Brand & Model Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                      ),
                      child: Text(
                        '${part.carBrand} ${part.carModel.isNotEmpty ? '• ${part.carModel}' : ''}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D4ED8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Price & Date Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          part.isSold ? '₹${part.price.toStringAsFixed(0)} (Sold)' : '₹${part.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: part.isSold ? const Color(0xFF94A3B8) : const Color(0xFF0075FF),
                            decoration: part.isSold ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        Text(
                          _formatDate(part.createdAt),
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Location & Distance Row
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: isLocal ? const Color(0xFF10B981) : const Color(0xFF0075FF),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            isLocal
                                ? '${part.location.split(',').first.trim()} • Local Area'
                                : '${part.location.split(',').first.trim()} • ${distance.toStringAsFixed(0)} km away',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isLocal ? const Color(0xFF047857) : const Color(0xFF64748B),
                              fontWeight: isLocal ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isLocal)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
                            ),
                            child: const Text(
                              'In Your City',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                            ),
                            child: Text(
                              '${distance.toStringAsFixed(0)} km',
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Matching Spare Parts',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              _selectedLocation != 'All India'
                  ? 'No parts found in "$_selectedLocation". Try expanding your search to "All India" or check your spelling.'
                  : 'Try searching with another car brand, model, city, or category name.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0075FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset All Search Filters', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _clearSearch,
            ),
          ],
        ),
      ),
    );
  }
}
