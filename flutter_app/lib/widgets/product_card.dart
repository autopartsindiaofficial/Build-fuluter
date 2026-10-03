import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/spare_part.dart';
import '../constants/app_colors.dart';
import '../providers/parts_provider.dart';
import '../screens/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final SparePart part;
  final double? distanceInKm;

  const ProductCard({Key? key, required this.part, this.distanceInKm}) : super(key: key);

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final partsProvider = Provider.of<PartsProvider>(context);
    final isFav = partsProvider.isFavorite(part.id);
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(part: part),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  part.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: part.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 32),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.directions_car_filled_rounded, size: 36, color: Color(0xFF94A3B8)),
                        ),

                  // Sold Overlay Badge
                  if (part.isSold)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.55),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SOLD',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Condition Badge (Top Left)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: part.condition.toLowerCase().contains('new')
                            ? const Color(0xFF0075FF)
                            : const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        part.condition.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  // Wishlist Heart Button (Top Right)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => partsProvider.toggleWishlist(part.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Body Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Price
                  Text(
                    currencyFormatter.format(part.price),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Title
                  Text(
                    part.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Brand & Model
                  Text(
                    '${part.carBrand} • ${part.carModel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Location & Time Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                distanceInKm != null
                                    ? (distanceInKm! <= 15.0
                                        ? '${part.location.split(',').first.trim()} • Local'
                                        : '${part.location.split(',').first.trim()} • ${distanceInKm!.toStringAsFixed(0)} km away')
                                    : part.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: distanceInKm != null ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                  fontWeight: distanceInKm != null ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatDate(part.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
