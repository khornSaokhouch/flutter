import 'package:flutter/material.dart';
import '../../../models/item_model.dart';

class CategoryTile extends StatelessWidget {
  final Category category;
  final String? iconAsset; // Optional local fallback
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryTile({
    super.key,
    required this.category,
    this.iconAsset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = category.imageUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(
              color: isSelected ? Colors.orange : Colors.transparent,
              width: 4.0,
            ),
          ),
        ),
        child: Column(
          children: [
            // Show network image if available, fallback to local asset, fallback to icon
            if (imageUrl != null && imageUrl.startsWith('http'))
              Image.network(
                imageUrl,
                width: 25,
                height: 25,
                color: isSelected ? Colors.orange : Colors.grey[700],
                errorBuilder: (context, error, stackTrace) =>
                iconAsset != null
                    ? Image.asset(iconAsset!, width: 25, height: 25, color: isSelected ? Colors.orange : Colors.grey[700])
                    : Icon(Icons.category, size: 25, color: Colors.grey),
              )
            else if (iconAsset != null)
              Image.asset(
                iconAsset!,
                width: 25,
                height: 25,
                color: isSelected ? Colors.orange : Colors.grey[700],
              )
            else
              Icon(Icons.category, size: 25, color: isSelected ? Colors.orange : Colors.grey[700]),
            const SizedBox(height: 8),
            Text(
              category.name.replaceAll(' ', '\n'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.orange : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
