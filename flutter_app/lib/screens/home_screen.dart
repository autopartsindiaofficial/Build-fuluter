import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../models/spare_part.dart';
import '../providers/parts_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/product_card.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';
import 'location_select_screen.dart';
import 'all_categories_screen.dart';
import 'sell_part_screen.dart';

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

  late final Stream<QuerySnapshot> _bannersStream;
  late final Stream<QuerySnapshot> _categoriesStream;
  late final Stream<QuerySnapshot> _brandsStream;

  // Default Fallback Banners
  final List<Map<String, dynamic>> _defaultBanners = [
    {
      'title': 'UP TO 50% OFF',
      'subtitle': 'ON GENUINE AUTO SPARE PARTS',
      'tag': 'MEGA SAVINGS',
      'imageUrl': 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=800&q=80',
      'targetCategory': 'All',
    },
    {
      'title': 'TURBOCHARGERS & ENGINES',
      'subtitle': 'Precision Balanced OEM Grade Parts',
      'tag': 'HIGH PERFORMANCE',
      'imageUrl': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=800&q=80',
      'targetCategory': 'Engine & Mechanical',
    },
    {
      'title': 'BRAKE PADS & ROTORS',
      'subtitle': 'Ceramic Friction • Maximum Safety',
      'tag': 'SAFETY ESSENTIALS',
      'imageUrl': 'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?auto=format&fit=crop&w=800&q=80',
      'targetCategory': 'Suspension & Brakes',
    },
  ];

  // Default Categories Fallback
  final List<Map<String, dynamic>> _defaultCategories = [
    {
      'name': 'Engine & Mechanical',
      'imageUrl': 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788828857/categories/v40ctc1xzsul1nmquwno.png',
      'icon': Icons.engineering_rounded,
    },
    {
      'name': 'Body & Exterior',
      'imageUrl': 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788915211/categories/ssxl1agf8ydkau5aqv4h.png',
      'icon': Icons.directions_car_rounded,
    },
    {
      'name': 'Lights & Electricals',
      'imageUrl': 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788746594/categories/w1tym7epvnhv0f9aapuf.png',
      'icon': Icons.bolt_rounded,
    },
    {
      'name': 'Suspension & Brakes',
      'imageUrl': 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788808169/categories/ebbks7ce3jejqgtxlndo.png',
      'icon': Icons.car_repair_rounded,
    },
    {
      'name': 'Interior & Dashboard',
      'imageUrl': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=400&q=80',
      'icon': Icons.airline_seat_recline_extra_rounded,
    },
    {
      'name': 'Wheels & Tyres',
      'imageUrl': 'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?auto=format&fit=crop&w=400&q=80',
      'icon': Icons.album_rounded,
    },
  ];

  // Default Car Brands Fallback
  final List<Map<String, dynamic>> _defaultBrands = [
    {'name': 'Maruti Suzuki', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/Suzuki_logo_2.svg/320px-Suzuki_logo_2.svg.png'},
    {'name': 'Hyundai', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Hyundai_Motor_Company_logo.svg/320px-Hyundai_Motor_Company_logo.svg.png'},
    {'name': 'Tata Motors', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8e/Tata_logo.svg/320px-Tata_logo.svg.png'},
    {'name': 'Mahindra', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/Mahindra_%26_Mahindra_Logo.svg/320px-Mahindra_%26_Mahindra_Logo.svg.png'},
    {'name': 'Toyota', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ee/Toyota_logo_%282020%29.svg/320px-Toyota_logo_%282020%29.svg.png'},
    {'name': 'Honda', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Honda_Logo.svg/320px-Honda_Logo.svg.png'},
    {'name': 'Kia', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/KIA_logo2.svg/320px-KIA_logo2.svg.png'},
  ];

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
    _brandsStream = _db.collection('carBrands').where('active', isEqualTo: true).snapshots();
    _startBannerAutoScroll();
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
            // App Logo
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
              clipBehavior: Clip.antiAlias,
              child: Center(
                child: Image.asset(
                  'assets/app_logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.directions_car_filled_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
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
                    MaterialPageRoute(builder: (_) => const LocationSelectScreen()),
                  );
                  if (result != null && result is String) {
                    setState(() => _selectedCity = result);
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
          // Quick Language Switcher Pill
          GestureDetector(
            onTap: () {
              final newCode = lang.currentLanguage == 'ta' ? 'en' : 'ta';
              lang.setLanguage(newCode);
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
                    lang.currentLanguage == 'ta' ? 'தமிழ்' : 'English',
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
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                  builder: (_) => SearchScreen(initialQuery: tag),
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
                  List<Map<String, dynamic>> bannersList = [];
                  if (bannerSnap.hasData && bannerSnap.data!.docs.isNotEmpty) {
                    bannersList = bannerSnap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
                    bannersList.sort((a, b) => ((a['order'] ?? 0) as num).compareTo((b['order'] ?? 0) as num));
                  }
                  if (bannersList.isEmpty) {
                    bannersList = _defaultBanners;
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
                        List<Map<String, dynamic>> categoriesList = [];
                        if (catSnap.hasData && catSnap.data!.docs.isNotEmpty) {
                          categoriesList = catSnap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
                          categoriesList.sort((a, b) => ((a['order'] ?? 0) as num).compareTo((b['order'] ?? 0) as num));
                        }
                        if (categoriesList.isEmpty) {
                          categoriesList = _defaultCategories;
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
                          brandsList = brandSnap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
                          brandsList.sort((a, b) => ((a['order'] ?? 0) as num).compareTo((b['order'] ?? 0) as num));
                        }
                        if (brandsList.isEmpty) {
                          brandsList = _defaultBrands;
                        }

                        return SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: brandsList.length,
                            itemBuilder: (context, index) {
                              final brand = brandsList[index];
                              final name = (brand['name'] ?? '') as String;
                              final isSelected = partsProvider.selectedBrand == name;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  selected: isSelected,
                                  label: Text(name),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? Colors.white : const Color(0xFF334155),
                                  ),
                                  selectedColor: const Color(0xFF0075FF),
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  onSelected: (val) {
                                    partsProvider.selectBrand(isSelected ? 'All' : name);
                                  },
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

            // 5. Parts Grid Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                      _selectedCity == 'All India' ? 'Fresh Recommendations' : 'Spares in $_selectedCity',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded, size: 12, color: Color(0xFF10B981)),
                          SizedBox(width: 4),
                          Text('100% Genuine', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 6. Parts Grid (Real-time Stream from Firestore with ProductCard)
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

                var parts = snapshot.data ?? [];

                // Filter by selected city if not All India
                if (_selectedCity != 'All India') {
                  final cityQuery = _selectedCity.toLowerCase();
                  parts = parts.where((p) {
                    final loc = (p.location + ' ' + p.district).toLowerCase();
                    return loc.contains(cityQuery);
                  }).toList();
                }

                if (parts.isEmpty) {
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
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
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

                final screenWidth = MediaQuery.of(context).size.width;
                final crossAxisCount = screenWidth >= 900 ? 4 : (screenWidth >= 600 ? 3 : 2);
                final childAspectRatio = screenWidth < 360 ? 0.65 : 0.70;

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ProductCard(part: parts[index]),
                      childCount: parts.length,
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
