import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../constants/categories_data.dart';
import '../models/spare_part.dart';
import '../services/firebase_service.dart';
import '../widgets/product_card.dart';
import 'search_screen.dart';

class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  String _selectedCatId = MASTER_CATEGORIES.first.id;

  static const List<Map<String, String>> TOP_CAR_BRANDS = [
    {'name': 'Maruti Suzuki', 'asset': 'assets/brands/maruti_suzuki.png'},
    {'name': 'Hyundai', 'asset': 'assets/brands/hyundai.png'},
    {'name': 'Mahindra', 'asset': 'assets/brands/mahindra.png'},
    {'name': 'Toyota', 'asset': 'assets/brands/toyota.png'},
    {'name': 'Tata Motors', 'asset': 'assets/brands/tata.png'},
    {'name': 'Honda', 'asset': 'assets/brands/honda.png'},
    {'name': 'Kia', 'asset': 'assets/brands/kia.png'},
    {'name': 'Volkswagen', 'asset': 'assets/brands/volkswagen.png'},
    {'name': 'Skoda', 'asset': 'assets/brands/skoda.png'},
    {'name': 'Ford', 'asset': 'assets/brands/ford.png'},
    {'name': 'BMW', 'asset': 'assets/brands/bmw.png'},
    {'name': 'Mercedes-Benz', 'asset': 'assets/brands/mercedes.png'},
  ];

  static const List<Map<String, dynamic>> BUDGET_FILTERS = [
    {'label': '< ₹2K', 'sub': 'Below ₹2,000', 'min': 0, 'max': 2000},
    {'label': '₹2K-5K', 'sub': '₹2,000 - ₹5,000', 'min': 2000, 'max': 5000},
    {'label': '₹5K-10K', 'sub': '₹5,000 - ₹10,000', 'min': 5000, 'max': 10000},
    {'label': '> ₹10K', 'sub': '₹10,000 & Above', 'min': 10000, 'max': 9999999},
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

  void _openSearchWithBrand(String brandName, String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          initialBrand: brandName,
          initialCategory: categoryName == 'All' ? null : categoryName,
        ),
      ),
    );
  }

  void _openSearchWithBudget(int minPrice, int maxPrice, String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          initialCategory: categoryName == 'All' ? null : categoryName,
        ),
      ),
    );
  }

  void _showAllBrandsModal(String categoryName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Car Brand', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: TOP_CAR_BRANDS.length,
                  itemBuilder: (_, index) {
                    final b = TOP_CAR_BRANDS[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _openSearchWithBrand(b['name']!, categoryName);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              b['asset']!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(Icons.directions_car_rounded, color: Color(0xFF0075FF)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            b['name']!,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Categories & Brands', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('topCategories').where('active', isEqualTo: true).snapshots(),
        builder: (context, snapshot) {
          List<CategoryData> activeCategories = List.from(MASTER_CATEGORIES);

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final liveDocs = snapshot.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
            liveDocs.sort((a, b) => ((a['order'] ?? 0) as num).compareTo((b['order'] ?? 0) as num));

            for (var live in liveDocs) {
              final name = live['name'] as String? ?? '';
              if (name.isEmpty) continue;
              final exists = activeCategories.any((c) => c.name.toLowerCase() == name.toLowerCase());
              if (!exists) {
                activeCategories.add(
                  CategoryData(
                    id: live['id'] ?? name.toLowerCase().replaceAll(' ', '_'),
                    name: name,
                    description: 'Genuine OEM and aftermarket $name parts',
                    imageUrl: live['imageUrl'],
                    popularParts: ['$name Kit', 'OEM $name', 'Replacement $name'],
                    primaryColor: 0xFF0075FF,
                    bgColor: 0xFFEFF6FF,
                  ),
                );
              }
            }
          }

          final selectedCat = activeCategories.firstWhere(
            (c) => c.id == _selectedCatId,
            orElse: () => activeCategories.first,
          );

          return Row(
            children: [
              // 1. LEFT VERTICAL CATEGORY RAIL (OLX STYLE)
              Container(
                width: 96,
                color: Colors.white,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: activeCategories.length,
                  itemBuilder: (context, index) {
                    final cat = activeCategories[index];
                    final isSelected = cat.id == selectedCat.id;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedCatId = cat.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                          border: Border(
                            left: BorderSide(
                              color: isSelected ? const Color(0xFF0075FF) : Colors.transparent,
                              width: 3.5,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: cat.imageUrl != null && cat.imageUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: cat.imageUrl!,
                                      fit: BoxFit.contain,
                                      errorWidget: (_, __, ___) => const Icon(Icons.category_rounded, color: Color(0xFF0075FF), size: 20),
                                    )
                                  : const Icon(Icons.category_rounded, color: Color(0xFF0075FF), size: 20),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              cat.name,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                color: isSelected ? const Color(0xFF0075FF) : const Color(0xFF334155),
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 2. RIGHT CONTENT AREA (OLX STYLE BRANDS, BUDGET & SUB-PARTS)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Header Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedCat.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedCat.description,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0075FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SearchScreen(initialCategory: selectedCat.name),
                                  ),
                                );
                              },
                              child: const Text('View All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SECTION 1: POPULAR CAR BRANDS (OLX CIRCULAR LOGOS STYLE)
                      Row(
                        children: [
                          Container(width: 3.5, height: 14, decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 6),
                          const Text(
                            'Popular Car Brands',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: 6, // Top 5 brands + 1 "View All" circular button
                        itemBuilder: (context, index) {
                          if (index == 5) {
                            // "View All" Brand Button
                            return GestureDetector(
                              onTap: () => _showAllBrandsModal(selectedCat.name),
                              child: Column(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF0075FF), size: 18),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'View All',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF0075FF)),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          final brand = TOP_CAR_BRANDS[index];
                          return GestureDetector(
                            onTap: () => _openSearchWithBrand(brand['name']!, selectedCat.name),
                            child: Column(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0F172A).withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(9),
                                  child: Image.asset(
                                    brand['asset']!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.directions_car_rounded, color: Color(0xFF0075FF)),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  brand['name']!,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // SECTION 2: PARTS BY BUDGET (OLX STYLE)
                      Row(
                        children: [
                          Container(width: 3.5, height: 14, decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 6),
                          const Text(
                            'Parts By Budget',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: BUDGET_FILTERS.map((b) {
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _openSearchWithBudget(b['min'] as int, b['max'] as int, selectedCat.name),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      b['label'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF0075FF)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      b['sub'] as String,
                                      style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B)),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // SECTION 3: POPULAR SUB-COMPONENTS
                      Row(
                        children: [
                          Container(width: 3.5, height: 14, decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 6),
                          const Text(
                            'Popular Spare Parts',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedCat.popularParts.map((partName) {
                          return ActionChip(
                            label: Text(partName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SearchScreen(
                                    initialQuery: partName,
                                    initialCategory: selectedCat.name,
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // SECTION 4: RECENTLY LISTED PARTS IN THIS CATEGORY
                      Row(
                        children: [
                          Container(width: 3.5, height: 14, decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 6),
                          const Text(
                            'Recent Listed Spares',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<List<SparePart>>(
                        stream: FirebaseService().getSparePartsStream(category: selectedCat.name),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                          }
                          final parts = snapshot.data ?? [];
                          if (parts.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: const Center(
                                child: Text('No parts listed in this category yet.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              ),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: parts.take(4).length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ProductCard(part: parts[index]),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
