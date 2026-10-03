import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../models/spare_part.dart';
import '../providers/parts_provider.dart';
import '../providers/language_provider.dart';
import '../constants/location_coordinates_helper.dart';
import '../widgets/product_card.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';
import 'location_select_screen.dart';
import 'all_categories_screen.dart';
import 'sell_part_screen.dart';
import 'nearby_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerPageController = PageController();
  final ValueNotifier<int> _currentBannerIndex = ValueNotifier<int>(0);
  Timer? _bannerTimer;
  String _selectedCity = 'All India';
  Position? _userGpsPosition;

  late final Stream<QuerySnapshot> _bannersStream;
  late final Stream<QuerySnapshot> _categoriesStream;
  late final Stream<QuerySnapshot> _brandsStream;

  final List<String> _quickTags = [
    'Headlight',
    'Bumper',
    'Brake Pads',
    'Turbocharger',
    'Clutch Plate',
    'Mirror',
  ];

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
    _bannersStream = _db.collection('banners').where('active', isEqualTo: true).snapshots();
    _categoriesStream = _db.collection('topCategories').where('active', isEqualTo: true).snapshots();
    _brandsStream = _db.collection('carBrands').snapshots();
    _startBannerAutoScroll();
    _loadSavedLocation();
    _detectUserGpsPosition();
  }

  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('user_selected_city');
      if (saved != null && saved.isNotEmpty && mounted) {
        setState(() => _selectedCity = saved);
      }
    } catch (_) {}
  }

  Future<void> _detectUserGpsPosition() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getLastKnownPosition();
        if (pos != null && mounted) {
          setState(() => _userGpsPosition = pos);
        }
      }
    } catch (_) {}
  }

  LatLng _getUserReferenceCoords() {
    if (_userGpsPosition != null) {
      return LatLng(_userGpsPosition!.latitude, _userGpsPosition!.longitude);
    }
    if (_selectedCity != 'All India' && _selectedCity.isNotEmpty) {
      return LocationCoordinatesHelper.getCoordinatesForLocation(_selectedCity, _selectedCity);
    }
    return const LatLng(13.0827, 80.2707); // Default Chennai/TN Hub
  }

  double _getDistanceInKm(SparePart p, LatLng ref) {
    final pLat = p.latitude ?? LocationCoordinatesHelper.getCoordinatesForLocation(p.location, p.district).latitude;
    final pLng = p.longitude ?? LocationCoordinatesHelper.getCoordinatesForLocation(p.location, p.district).longitude;
    return LocationCoordinatesHelper.calculateDistanceInKm(ref.latitude, ref.longitude, pLat, pLng);
  }

  static const Map<String, String> _defaultBrandLogos = {
    'maruti': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/Suzuki_logo_2.svg/320px-Suzuki_logo_2.svg.png',
    'maruti suzuki': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/Suzuki_logo_2.svg/320px-Suzuki_logo_2.svg.png',
    'suzuki': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/Suzuki_logo_2.svg/320px-Suzuki_logo_2.svg.png',
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

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    _currentBannerIndex.dispose();
    super.dispose();
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerPageController.hasClients) {
        int nextPage = _currentBannerIndex.value + 1;
        if (nextPage >= 3) nextPage = 0;
        _bannerPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _handleRefresh() async {
    final partsProvider = Provider.of<PartsProvider>(context, listen: false);
    partsProvider.fetchParts();
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final partsProvider = Provider.of<PartsProvider>(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 16,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFF1F5F9),
            height: 1,
          ),
        ),
        title: Row(
          children: [
            // Automotive Emblem Badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0075FF), Color(0xFF0052B4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0075FF).withOpacity(0.24),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.directions_car_filled_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Location Selector with Live GPS Pill
            Expanded(
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LocationSelectScreen(selectedLocation: _selectedCity)),
                  );
                  if (result != null && result is String && mounted) {
                    setState(() => _selectedCity = result);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('user_selected_city', result);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LOCATION',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF0075FF)),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              _selectedCity,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Nearby Spares Map Button
          IconButton(
            icon: const Icon(Icons.map_rounded, color: Color(0xFF0075FF), size: 24),
            tooltip: 'Nearby Spares Map',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NearbyMapScreen()),
              );
            },
          ),

          // Quick Language Switcher Pill (Supports English, Tamil, Hindi)
          GestureDetector(
            onTap: () {
              // Cycle: en -> ta -> hi -> en
              String newCode = 'en';
              if (lang.currentLanguage == 'en') {
                newCode = 'ta';
              } else if (lang.currentLanguage == 'ta') {
                newCode = 'hi';
              } else {
                newCode = 'en';
              }
              lang.setLanguage(newCode);
            },
            onLongPress: () {
              // Show Language Selection BottomSheet
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (ctx) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select Language / மொழி / भाषा', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                          title: const Text('English', style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: lang.currentLanguage == 'en' ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0075FF)) : null,
                          onTap: () {
                            lang.setLanguage('en');
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          leading: const Text('🇮🇳', style: TextStyle(fontSize: 24)),
                          title: const Text('தமிழ் (Tamil)', style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: lang.currentLanguage == 'ta' ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0075FF)) : null,
                          onTap: () {
                            lang.setLanguage('ta');
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          leading: const Text('🇮🇳', style: TextStyle(fontSize: 24)),
                          title: const Text('हिंदी (Hindi)', style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: lang.currentLanguage == 'hi' ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0075FF)) : null,
                          onTap: () {
                            lang.setLanguage('hi');
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0075FF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0075FF).withOpacity(0.2), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language_rounded, color: Color(0xFF0075FF), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    lang.currentLanguage == 'ta' ? 'தமிழ்' : (lang.currentLanguage == 'hi' ? 'हिंदी' : 'English'),
                    style: const TextStyle(
                      color: Color(0xFF0075FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Notifications Bell with Unread Badge
          StreamBuilder<QuerySnapshot>(
            stream: currentUserId != null
                ? _db.collection('users').doc(currentUserId).collection('notifications').where('read', isEqualTo: false).snapshots()
                : const Stream.empty(),
            builder: (context, notifSnap) {
              final unreadCount = notifSnap.data?.docs.length ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A), size: 24),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF0075FF),
        child: CustomScrollView(
          key: const PageStorageKey<String>('home_scroll_view'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Search Bar Trigger (High-end Marketplace Style)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SearchScreen(
                              initialLocation: _selectedCity != 'All India' ? _selectedCity : null,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: Color(0xFF0075FF), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                lang.t('searchPlaceholder'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.tune_rounded, color: Color(0xFF475569), size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Quick Search Keywords Rail
                    SizedBox(
                      height: 28,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _quickTags.length,
                        itemBuilder: (context, i) {
                          final tag = _quickTags[i];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SearchScreen(
                                    initialQuery: tag,
                                    initialLocation: _selectedCity != 'All India' ? _selectedCity : null,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Promotional Banners Carousel (Live from Firestore with fallback)
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot>(
                stream: _bannersStream,
                builder: (context, bannerSnap) {
                  if (bannerSnap.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 145,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }

                  List<Map<String, dynamic>> bannersList = [];
                  if (bannerSnap.hasData && bannerSnap.data!.docs.isNotEmpty) {
                    bannersList = bannerSnap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
                    bannersList.sort((a, b) => ((a['order'] ?? 0) as num).compareTo((b['order'] ?? 0) as num));
                  }
                  if (bannersList.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 145,
                          child: PageView.builder(
                            controller: _bannerPageController,
                            onPageChanged: (idx) => _currentBannerIndex.value = idx,
                            itemCount: bannersList.length,
                            itemBuilder: (context, idx) {
                              final b = bannersList[idx];
                              return GestureDetector(
                                onTap: () {
                                  final target = (b['targetCategory'] ?? b['targetLink'] ?? '').toString().trim();
                                  if (target.isNotEmpty && target != 'All') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => SearchScreen(initialQuery: target)),
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Stack(
                                      children: [
                                        // Background Image
                                        Positioned.fill(
                                          child: CachedNetworkImage(
                                            imageUrl: b['imageUrl'] ?? '',
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => Container(color: const Color(0xFF1E293B)),
                                          ),
                                        ),
                                        // Dark Gradient Overlay with specular finish
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.black.withOpacity(0.85),
                                                  Colors.black.withOpacity(0.35),
                                                ],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Banner Content
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              if (b['tag'] != null && (b['tag'] as String).isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFF0075FF), Color(0xFF0056C6)],
                                                    ),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    b['tag'],
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w900,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(height: 6),
                                              Text(
                                                b['title'] ?? 'Genuine Spares',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                b['subtitle'] ?? 'Best Price Guaranteed across India',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.85),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Dot Indicators
                        ValueListenableBuilder<int>(
                          valueListenable: _currentBannerIndex,
                          builder: (context, activeIdx, _) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                bannersList.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: activeIdx == i ? 18 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: activeIdx == i ? const Color(0xFF0075FF) : const Color(0xFFCBD5E1),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 3. Top Categories Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0075FF),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                lang.t('categories'),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AllCategoriesScreen()));
                            },
                            child: Text(
                              lang.t('viewAll'),
                              style: const TextStyle(color: Color(0xFF0075FF), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: _categoriesStream,
                      builder: (context, catSnap) {
                        if (catSnap.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 100,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }

                        List<Map<String, dynamic>> categoriesList = [];
                        if (catSnap.hasData && catSnap.data!.docs.isNotEmpty) {
                          categoriesList = catSnap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
                          categoriesList.sort((a, b) => ((a['order'] ?? 0) as num).compareTo((b['order'] ?? 0) as num));
                        }
                        if (categoriesList.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: categoriesList.length,
                            itemBuilder: (context, index) {
                              final cat = categoriesList[index];
                              final isSelected = partsProvider.selectedCategory == cat['name'];

                              return GestureDetector(
                                onTap: () {
                                  partsProvider.selectCategory(isSelected ? 'All' : cat['name']);
                                },
                                child: Container(
                                  width: 84,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF0075FF).withOpacity(0.12) : Colors.white,
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFE2E8F0),
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF0F172A).withOpacity(0.04),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(17),
                                          child: cat['imageUrl'] != null && (cat['imageUrl'] as String).isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: cat['imageUrl'],
                                                  fit: BoxFit.cover,
                                                  errorWidget: (_, __, ___) => Icon(cat['icon'] ?? Icons.category_rounded, color: const Color(0xFF0075FF)),
                                                )
                                              : Icon(cat['icon'] ?? Icons.category_rounded, color: const Color(0xFF0075FF)),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        cat['name'] ?? '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                          color: isSelected ? const Color(0xFF0075FF) : const Color(0xFF334155),
                                        ),
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 4. Car Brands Filter Rail
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0075FF),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            lang.t('topBrands'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    StreamBuilder<QuerySnapshot>(
                      stream: _brandsStream,
                      builder: (context, brandSnap) {
                        List<Map<String, dynamic>> brandsList = [];
                        if (brandSnap.hasData && brandSnap.data!.docs.isNotEmpty) {
                          brandsList = brandSnap.data!.docs.map((d) {
                            final data = d.data() as Map<String, dynamic>;
                            return {...data, 'id': d.id};
                          }).where((d) => d['active'] != false).toList();

                          brandsList.sort((a, b) => ((a['order'] ?? 0) as num).compareTo((b['order'] ?? 0) as num));
                        }

                        // If Firestore has no brands, supply standard Indian top car brands with verified logos
                        if (brandsList.isEmpty) {
                          brandsList = [
                            {'name': 'Maruti Suzuki', 'logoUrl': _defaultBrandLogos['maruti suzuki']},
                            {'name': 'Hyundai', 'logoUrl': _defaultBrandLogos['hyundai']},
                            {'name': 'Tata Motors', 'logoUrl': _defaultBrandLogos['tata motors']},
                            {'name': 'Mahindra', 'logoUrl': _defaultBrandLogos['mahindra']},
                            {'name': 'Toyota', 'logoUrl': _defaultBrandLogos['toyota']},
                            {'name': 'Honda', 'logoUrl': _defaultBrandLogos['honda']},
                            {'name': 'Kia', 'logoUrl': _defaultBrandLogos['kia']},
                            {'name': 'Volkswagen', 'logoUrl': _defaultBrandLogos['volkswagen']},
                            {'name': 'Skoda', 'logoUrl': _defaultBrandLogos['skoda']},
                            {'name': 'Ford', 'logoUrl': _defaultBrandLogos['ford']},
                          ];
                        }

                        // Total items: 1 (All Brands) + brandsList.length
                        return SizedBox(
                          height: 98,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: brandsList.length + 1,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              // Item 0: All Brands button
                              if (index == 0) {
                                final isSelected = partsProvider.selectedBrand == 'All';
                                return GestureDetector(
                                  onTap: () => partsProvider.selectBrand('All'),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF0075FF) : Colors.white,
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFE2E8F0),
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isSelected
                                                  ? const Color(0xFF0075FF).withOpacity(0.3)
                                                  : const Color(0xFF0F172A).withOpacity(0.04),
                                              blurRadius: isSelected ? 8 : 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.directions_car_filled_rounded,
                                            size: 26,
                                            color: isSelected ? Colors.white : const Color(0xFF0075FF),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'All Brands',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                          color: isSelected ? const Color(0xFF0075FF) : const Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final brand = brandsList[index - 1];
                              final name = (brand['name'] ?? '') as String;
                              final isSelected = partsProvider.selectedBrand == name;
                              final logoUrl = _resolveBrandLogo(brand);

                              return GestureDetector(
                                onTap: () {
                                  partsProvider.selectBrand(isSelected ? 'All' : name);
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFE2E8F0),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isSelected
                                                ? const Color(0xFF0075FF).withOpacity(0.24)
                                                : const Color(0xFF0F172A).withOpacity(0.04),
                                            blurRadius: isSelected ? 8 : 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: (logoUrl != null && logoUrl.isNotEmpty)
                                            ? CachedNetworkImage(
                                                imageUrl: logoUrl,
                                                fit: BoxFit.contain,
                                                placeholder: (_, __) => const Center(
                                                  child: SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF0075FF)),
                                                  ),
                                                ),
                                                errorWidget: (_, __, ___) => Center(
                                                  child: Icon(Icons.directions_car_rounded, color: const Color(0xFF0075FF).withOpacity(0.7), size: 24),
                                                ),
                                              )
                                            : Center(
                                                child: Text(
                                                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'B',
                                                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0075FF), fontSize: 20),
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: 68,
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                          color: isSelected ? const Color(0xFF0075FF) : const Color(0xFF334155),
                                        ),
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Active Filters Banner (If any filter applied)
            if (partsProvider.selectedCategory != 'All' || partsProvider.selectedBrand != 'All')
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt_rounded, size: 16, color: Color(0xFF1D4ED8)),
                        const SizedBox(width: 6),
                        const Text('Filtered By: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
                        if (partsProvider.selectedCategory != 'All')
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            child: Text(partsProvider.selectedCategory, style: const TextStyle(fontSize: 11, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold)),
                          ),
                        if (partsProvider.selectedBrand != 'All')
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            child: Text(partsProvider.selectedBrand, style: const TextStyle(fontSize: 11, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold)),
                          ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            partsProvider.selectCategory('All');
                            partsProvider.selectBrand('All');
                          },
                          child: const Text('Reset', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 6. Parts Grid (Real-time Stream from Firestore with Location-Aware Prioritization)
            StreamBuilder<List<SparePart>>(
              stream: partsProvider.partsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF0075FF)),
                    ),
                  );
                }

                var allParts = snapshot.data ?? [];

                // Filter out deleted/inactive parts
                allParts = allParts.where((p) {
                  if (p.isDeleted == true) return false;
                  final s = p.status.toLowerCase().trim();
                  return s != 'inactive' && s != 'rejected' && s != 'deleted' && s != 'hidden';
                }).toList();

                if (allParts.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
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
                              child: const Icon(Icons.car_crash_rounded, size: 48, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Spare Parts Found',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Try changing your location or clearing filters to see all parts.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0075FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                              label: const Text('Post the First Spare Part', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const SellPartScreen()));
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final userRefCoords = _getUserReferenceCoords();
                final userCityQuery = _selectedCity.trim().toLowerCase();
                final primaryUserCity = userCityQuery.split(',').first.trim();

                final List<SparePart> localParts = [];
                final List<SparePart> nearbyParts = [];

                if (_selectedCity == 'All India') {
                  if (_userGpsPosition != null) {
                    for (var p in allParts) {
                      final dist = _getDistanceInKm(p, userRefCoords);
                      if (dist <= 25.0) {
                        localParts.add(p);
                      } else {
                        nearbyParts.add(p);
                      }
                    }
                  } else {
                    localParts.addAll(allParts);
                  }
                } else {
                  for (var p in allParts) {
                    final pLoc = '${p.location} ${p.district}'.toLowerCase();
                    final dist = _getDistanceInKm(p, userRefCoords);
                    if (pLoc.contains(userCityQuery) || pLoc.contains(primaryUserCity) || primaryUserCity.contains(p.district.toLowerCase()) || dist <= 25.0) {
                      localParts.add(p);
                    } else {
                      nearbyParts.add(p);
                    }
                  }
                }

                // Sort local parts: unsold first, then newest
                localParts.sort((a, b) {
                  if (a.isSold != b.isSold) return a.isSold ? 1 : -1;
                  return b.createdAt.compareTo(a.createdAt);
                });

                // Sort nearby parts: ALWAYS by closest distance first!
                nearbyParts.sort((a, b) {
                  if (a.isSold != b.isSold) return a.isSold ? 1 : -1;
                  final distA = _getDistanceInKm(a, userRefCoords);
                  final distB = _getDistanceInKm(b, userRefCoords);
                  return distA.compareTo(distB);
                });

                final screenWidth = MediaQuery.of(context).size.width;
                final crossAxisCount = screenWidth >= 900 ? 4 : (screenWidth >= 600 ? 3 : 2);
                final childAspectRatio = screenWidth < 360 ? 0.65 : 0.70;

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Local Ads Section (User's location first)
                        if (localParts.isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0075FF),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedCity == 'All India' ? 'Fresh Recommendations' : 'Spares in $_selectedCity (${localParts.length})',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded, size: 12, color: Color(0xFF10B981)),
                                    SizedBox(width: 4),
                                    Text('100% Genuine', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: localParts.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: childAspectRatio,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemBuilder: (context, index) {
                              final p = localParts[index];
                              return ProductCard(
                                part: p,
                                distanceInKm: _getDistanceInKm(p, userRefCoords),
                              );
                            },
                          ),
                        ] else if (_selectedCity != 'All India') ...[
                          // Notice banner when 0 exact listings in city
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Color(0xFF0075FF), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'No listings inside $_selectedCity yet',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E3A8A)),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Showing closest spare parts available from nearby areas (sorted by proximity):',
                                        style: TextStyle(fontSize: 11.5, color: Color(0xFF3B82F6), fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // 2. Nearby Spares Section (Pakkathu ads sorted by proximity)
                        if (nearbyParts.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.near_me_rounded, color: Color(0xFF0075FF), size: 14),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nearby Parts from Surrounding Areas (${nearbyParts.length})',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _selectedCity == 'All India' ? 'Sorted by closest distance to you' : 'Closest parts neighboring $_selectedCity',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: nearbyParts.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: childAspectRatio,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemBuilder: (context, index) {
                              final p = nearbyParts[index];
                              return ProductCard(
                                part: p,
                                distanceInKm: _getDistanceInKm(p, userRefCoords),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
