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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Spare Parts Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
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
              // Left Vertical Category Selector
              Container(
                width: 100,
                color: Colors.white,
                child: ListView.builder(
                  itemCount: activeCategories.length,
                  itemBuilder: (context, index) {
                    final cat = activeCategories[index];
                    final isSelected = cat.id == selectedCat.id;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedCatId = cat.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.background : Colors.white,
                          border: Border(
                            left: BorderSide(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(cat.bgColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: cat.imageUrl != null && cat.imageUrl!.isNotEmpty
                                  ? CachedNetworkImage(imageUrl: cat.imageUrl!, fit: BoxFit.contain, errorWidget: (_, __, ___) => Icon(Icons.directions_car, color: Color(cat.primaryColor), size: 20))
                                  : Icon(Icons.directions_car, color: Color(cat.primaryColor), size: 20),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat.name,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Right Content: Category Details & Sub-parts
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Color(selectedCat.bgColor),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(selectedCat.primaryColor).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedCat.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(selectedCat.primaryColor),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedCat.description,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Popular Sub-Components',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedCat.popularParts.map((partName) {
                          return ActionChip(
                            label: Text(partName, style: const TextStyle(fontSize: 12)),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.border),
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
                      const Text(
                        'Available Parts in this Category',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: Text('No parts listed in this category yet.')),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: parts.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
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
