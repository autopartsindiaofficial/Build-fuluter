import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/categories_data.dart';
import '../constants/app_colors.dart';

class CategoryCard extends StatelessWidget {
  final MasterCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryCard({
    Key? key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Color(category.bgColor),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: category.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: category.imageUrl!,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => Icon(
                        Icons.settings,
                        color: Color(category.primaryColor),
                      ),
                    )
                  : Icon(
                      Icons.directions_car,
                      color: Color(category.primaryColor),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
