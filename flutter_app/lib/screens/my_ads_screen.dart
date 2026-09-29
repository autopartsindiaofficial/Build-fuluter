import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../models/spare_part.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import 'product_detail_screen.dart';

class MyAdsScreen extends StatelessWidget {
  const MyAdsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AppAuthProvider>(context);
    final firebaseService = FirebaseService();
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Listed Ads')),
        body: const Center(child: Text('Please log in to view your ads.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Listed Ads', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<SparePart>>(
        stream: firebaseService.getSparePartsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final myParts = (snapshot.data ?? [])
              .where((p) => p.sellerId == auth.user!.uid)
              .toList();

          if (myParts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    "You haven't listed any spare parts yet.",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myParts.length,
            itemBuilder: (context, index) {
              final part = myParts[index];

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: CachedNetworkImage(
                            imageUrl: part.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.directions_car, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              part.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormatter.format(part.price),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: part.isSold ? Colors.grey.shade200 : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    part.isSold ? 'SOLD' : 'ACTIVE',
                                    style: TextStyle(
                                      color: part.isSold ? Colors.grey.shade700 : Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'view') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProductDetailScreen(part: part)),
                            );
                          } else if (value == 'toggle_sold') {
                            await firebaseService.updateSparePart(part.id, {'isSold': !part.isSold});
                          } else if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Ad?'),
                                content: const Text('Are you sure you want to permanently delete this listing?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await firebaseService.deleteSparePart(part.id);
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'view', child: Text('View Details')),
                          PopupMenuItem(
                            value: 'toggle_sold',
                            child: Text(part.isSold ? 'Mark as Active' : 'Mark as Sold'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Listing', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
