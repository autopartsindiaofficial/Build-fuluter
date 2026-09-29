import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class BrandCard extends StatelessWidget {
  final Map<String, dynamic> brand;
  final bool isSelected;
  final VoidCallback onTap;

  const BrandCard({
    Key? key,
    required this.brand,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = brand['name'] as String;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_filled_outlined,
              size: 16,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
