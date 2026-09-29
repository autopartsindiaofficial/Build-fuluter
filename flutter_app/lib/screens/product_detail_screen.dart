import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/spare_part.dart';
import '../constants/app_colors.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/make_offer_dialog.dart';
import 'chat_room_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final SparePart part;

  const ProductDetailScreen({Key? key, required this.part}) : super(key: key);

  void _callPhone(String phone) async {
    final Uri uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AppAuthProvider>(context);
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: AppColors.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Part saved to your wishlist!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sharing ${part.title}...')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel / Hero Image
            AspectRatio(
              aspectRatio: 1.3,
              child: CachedNetworkImage(
                imageUrl: part.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.directions_car, size: 60, color: Colors.grey),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currencyFormatter.format(part.price),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          part.condition,
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    part.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Specification Grid
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildSpecRow('Car Brand', part.carBrand),
                        const Divider(),
                        _buildSpecRow('Car Model', part.carModel),
                        const Divider(),
                        _buildSpecRow('Category', part.category),
                        if (part.oemNumber != null && part.oemNumber!.isNotEmpty) ...[
                          const Divider(),
                          _buildSpecRow('OEM Part #', part.oemNumber!),
                        ],
                        const Divider(),
                        _buildSpecRow('Location', part.location),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    part.description ?? 'Genuine OEM automobile spare part in good working condition.',
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),

                  const SizedBox(height: 24),
                  // Seller Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: const Icon(Icons.person, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                part.contactName ?? 'Verified Seller',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: const [
                                  Icon(Icons.star, size: 14, color: Colors.amber),
                                  SizedBox(width: 2),
                                  Text('4.9 (48 reviews)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (part.contactPhone != null)
                          ElevatedButton.icon(
                            onPressed: () => _callPhone(part.contactPhone!),
                            icon: const Icon(Icons.call, size: 16),
                            label: const Text('Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final currentUserId = auth.user?.uid ?? 'guest_buyer';
                  final currentUserName = auth.userProfile?.displayName ?? 'Buyer';
                  showDialog(
                    context: context,
                    builder: (_) => MakeOfferDialog(
                      part: part,
                      currentUserId: currentUserId,
                      currentUserName: currentUserName,
                    ),
                  );
                },
                icon: const Icon(Icons.local_offer_outlined, color: AppColors.primary),
                label: Text(lang.t('makeOffer')),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  final currentUserId = auth.user?.uid ?? 'guest_user';
                  final conversationId = '${currentUserId}_${part.sellerId}_${part.id}';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(
                        conversationId: conversationId,
                        partTitle: part.title,
                        sellerName: part.contactName ?? 'Seller',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                label: Text(lang.t('chatWithSeller')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
