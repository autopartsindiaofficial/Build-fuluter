import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/spare_part.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import '../providers/parts_provider.dart';
import '../widgets/product_card.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AppAuthProvider>(context);
    final partsProvider = Provider.of<PartsProvider>(context);
    final firebaseService = FirebaseService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Parts / Wishlist', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<SparePart>>(
        stream: firebaseService.getSparePartsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final allParts = snapshot.data ?? [];
          final localSavedIds = partsProvider.wishlistPartIds;
          final userSavedIds = auth.userProfile?.savedParts ?? [];
          final combinedIds = {...localSavedIds, ...userSavedIds};

          final savedParts = allParts.where((p) => combinedIds.contains(p.id)).toList();

          if (savedParts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No saved spare parts yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: savedParts.length,
            itemBuilder: (context, index) {
              final part = savedParts[index];
              return ProductCard(part: part);
            },
          );
        },
      ),
    );
  }
}
