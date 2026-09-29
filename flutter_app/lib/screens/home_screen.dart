import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
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
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerPageController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  String _selectedCity = 'All India';

  // Default Fallback Banners matching React Native
  final List<Map<String, dynamic>> _defaultBanners = [
    {
      'title': 'UP TO 50% OFF',
      'subtitle': 'ON GENUINE AUTO SPARE PARTS',
      'tag': 'MEGA DEALS',
      'imageUrl': 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=800&q=80',
      'targetCategory': 'All',
    },
    {
      'title': 'TURBOCHARGERS & ENGINES',
      'subtitle': 'Precision Balanced OEM Grade',
      'tag': 'PERFORMANCE',
      'imageUrl': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=800&q=80',
      'targetCategory': 'Engine & Mechanical',
    },
    {
      'title': 'DISCS & SUSPENSION',
      'subtitle': 'Ceramic Friction Brake Pads',
      'tag': 'SAFETY & COMFORT',
      'imageUrl': 'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?auto=format&fit=crop&w=800&q=80',
      'targetCategory': 'Suspension & Brakes',
    },
  ];

  // Default Categories Fallback matching React Native
  final List<Map<String, dynamic>> _defaultCategories = [
    {
      'name': 'Engine & Mechanical',
      'imageUrl': 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788828857/categories/v40ctc1xzsul1nmquwno.png',
      'icon': Icons.engineering,
    },
    {
      'name': 'Body & Exterior',
      'imageUrl': 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788915211/categories/ssxl1agf8ydkau5aqv4h.png',
      'icon': Icons.directions_car,
    },
    {
      'name': 'Lights & Electricals',
      'imageUrl': 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788746594/categories/w1tym7epvnhv0f9aapuf.png',
      'icon': Icons.bolt,
    },
    {
      'name': 'Suspension & Brakes',
      'imageUrl': 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788808169/categories/ebbks7ce3jejqgtxlndo.png',
      'icon': Icons.car_repair,
    },
    {
      'name': 'Interior & Dashboard',
      'imageUrl': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=400&q=80',
      'icon': Icons.airline_seat_recline_extra,
    },
    {
      'name': 'Wheels & Tyres',
      'imageUrl': 'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?auto=format&fit=crop&w=400&q=80',
      'icon': Icons.album,
    },
  ];

  // Default Car Brands Fallback matching React Native
  final List<Map<String, dynamic>> _defaultBrands = [
    {'name': 'Maruti Suzuki', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/Suzuki_logo_2.svg/320px-Suzuki_logo_2.svg.png'},
    {'name': 'Hyundai', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Hyundai_Motor_Company_logo.svg/320px-Hyundai_Motor_Company_logo.svg.png'},
    {'name': 'Tata Motors', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8e/Tata_logo.svg/320px-Tata_logo.svg.png'},
    {'name': 'Mahindra', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/Mahindra_%26_Mahindra_Logo.svg/320px-Mahindra_%26_Mahindra_Logo.svg.png'},
    {'name': 'Toyota', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ee/Toyota_logo_%282020%29.svg/320px-Toyota_logo_%282020%29.svg.png'},
    {'name': 'Honda', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Honda_Logo.svg/320px-Honda_Logo.svg.png'},
    {'name': 'Kia', 'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/KIA_logo2.svg/320px-KIA_logo2.svg.png'},
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
    _startBannerAutoScroll();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    super.dispose();
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerPageController.hasClients) {
        int nextPage = _currentBannerIndex + 1;
        if (nextPage >= 3) nextPage = 0;
        _bannerPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
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
        elevation: 0.5,
        backgroundColor: Colors.white,
        titleSpacing: 12,
        title: Row(
          children: [
            // App Emblem
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF0075FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.car_repair, color: Color(0xFF0075FF), size: 22),
            ),
            const SizedBox(width: 10),
            // App Title & Location Selector Trigger
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.t('appName'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LocationSelectScreen()),
                      );
                      if (result != null && result is String) {
                        setState(() => _selectedCity = result);
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Color(0xFF0075FF)),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            _selectedCity,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
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
                    icon: const Icon(Icons.notifications_none, color: Color(0xFF0F172A), size: 24),
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
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF0075FF),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Search Bar Trigger (OLX India Style)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF0075FF), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lang.t('searchPlaceholder'),
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.tune, color: Color(0xFF64748B), size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2. Promotional Banners Carousel (Live from Firestore with fallback)
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('banners').where('active', isEqualTo: true).snapshots(),
                builder: (context, bannerSnap) {
                  List<Map<String, dynamic>> bannersList = [];
                  if (bannerSnap.hasData && bannerSnap.data!.docs.isNotEmpty) {
                    bannersList = bannerSnap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
                  }
                  if (bannersList.isEmpty) {
                    bannersList = _defaultBanners;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 140,
                          child: PageView.builder(
                            controller: _bannerPageController,
                            onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
                            itemCount: bannersList.length,
                            itemBuilder: (context, idx) {
                              final b = bannersList[idx];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
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
                                      // Dark Gradient Overlay
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.black.withOpacity(0.85),
                                                Colors.black.withOpacity(0.3),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Banner Text Content
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (b['tag'] != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0075FF),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  b['tag'],
                                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            const SizedBox(height: 6),
                                            Text(
                                              b['title'] ?? 'Genuine Spares',
                                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              b['subtitle'] ?? 'Best Price Guaranteed across India',
                                              style: const TextStyle(color: Colors.white70, fontSize: 11),
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
                        ),
                        const SizedBox(height: 8),
                        // Dot Indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            bannersList.length,
                            (i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _currentBannerIndex == i ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentBannerIndex == i ? const Color(0xFF0075FF) : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 3. Top Categories Section (Firestore CMS + Fallback)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lang.t('categories'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
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
                      stream: _db.collection('topCategories').where('active', isEqualTo: true).snapshots(),
                      builder: (context, catSnap) {
                        List<Map<String, dynamic>> categoriesList = [];
                        if (catSnap.hasData && catSnap.data!.docs.isNotEmpty) {
                          categoriesList = catSnap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
                        }
                        if (categoriesList.isEmpty) {
                          categoriesList = _defaultCategories;
                        }

                        return SizedBox(
                          height: 96,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            itemCount: categoriesList.length,
                            itemBuilder: (context, index) {
                              final cat = categoriesList[index];
                              final isSelected = partsProvider.selectedCategory == cat['name'];

                              return GestureDetector(
                                onTap: () {
                                  partsProvider.selectCategory(isSelected ? 'All' : cat['name']);
                                },
                                child: Container(
                                  width: 82,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF0075FF).withOpacity(0.12) : Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFE2E8F0),
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.02),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(15),
                                          child: cat['imageUrl'] != null && (cat['imageUrl'] as String).isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: cat['imageUrl'],
                                                  fit: BoxFit.cover,
                                                  errorWidget: (_, __, ___) => Icon(cat['icon'] ?? Icons.category, color: const Color(0xFF0075FF)),
                                                )
                                              : Icon(cat['icon'] ?? Icons.category, color: const Color(0xFF0075FF)),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        cat['name'] ?? '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

            // 4. Car Brands Carousel (Live Firestore CMS + Fallback)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(
                        lang.t('topBrands'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    StreamBuilder<QuerySnapshot>(
                      stream: _db.collection('carBrands').where('active', isEqualTo: true).snapshots(),
                      builder: (context, brandSnap) {
                        List<Map<String, dynamic>> brandsList = [];
                        if (brandSnap.hasData && brandSnap.data!.docs.isNotEmpty) {
                          brandsList = brandSnap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
                        }
                        if (brandsList.isEmpty) {
                          brandsList = _defaultBrands;
                        }

                        return SizedBox(
                          height: 42,
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
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : const Color(0xFF334155),
                                  ),
                                  selectedColor: const Color(0xFF0075FF),
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFE2E8F0)),
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

            // Active Filters Badge Indicator
            if (partsProvider.selectedCategory != 'All' || partsProvider.selectedBrand != 'All')
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Text('Filtered By: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      if (partsProvider.selectedCategory != 'All')
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(12)),
                          child: Text(partsProvider.selectedCategory, style: const TextStyle(fontSize: 11, color: Color(0xFF3730A3), fontWeight: FontWeight.bold)),
                        ),
                      if (partsProvider.selectedBrand != 'All')
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(12)),
                          child: Text(partsProvider.selectedBrand, style: const TextStyle(fontSize: 11, color: Color(0xFF3730A3), fontWeight: FontWeight.bold)),
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          partsProvider.selectCategory('All');
                          partsProvider.selectBrand('All');
                        },
                        child: const Text('Clear All', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),

            // 5. Parts Grid (Real-time Stream from Firestore with OLX-Hierarchy ProductCard)
            StreamBuilder<List<SparePart>>(
              stream: partsProvider.partsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
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
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: const Icon(Icons.search_off, size: 40, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No spare parts found',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try changing your city, brand, or category filter.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.70,
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
