import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/categories_data.dart';
import '../models/spare_part.dart';
import '../providers/parts_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/category_card.dart';
import '../widgets/brand_card.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final partsProvider = Provider.of<PartsProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.car_repair, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.t('appName'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: const [
                    Icon(Icons.location_on, size: 12, color: AppColors.primary),
                    SizedBox(width: 2),
                    Text(
                      'All India (All Cities)',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Search Bar Trigger
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          lang.t('searchPlaceholder'),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ),
                      const Icon(Icons.tune, color: AppColors.textSecondary, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Categories Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lang.t('categories'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            lang.t('viewAll'),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 105,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: MASTER_CATEGORIES.length,
                      itemBuilder: (context, index) {
                        final cat = MASTER_CATEGORIES[index];
                        final isSelected = partsProvider.selectedCategory == cat.name;
                        return CategoryCard(
                          category: cat,
                          isSelected: isSelected,
                          onTap: () {
                            partsProvider.selectCategory(isSelected ? 'All' : cat.name);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Brands Filter Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      lang.t('topBrands'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: TOP_BRANDS.length,
                      itemBuilder: (context, index) {
                        final brand = TOP_BRANDS[index];
                        final name = brand['name'] as String;
                        final isSelected = partsProvider.selectedBrand == name;
                        return BrandCard(
                          brand: brand,
                          isSelected: isSelected,
                          onTap: () {
                            partsProvider.selectBrand(isSelected ? 'All' : name);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Parts Grid (Real-time Stream from Firestore)
          StreamBuilder<List<SparePart>>(
            stream: partsProvider.partsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              final parts = snapshot.data ?? [];

              if (parts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.search_off, size: 50, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No spare parts found for current filter',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
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
    );
  }
}
