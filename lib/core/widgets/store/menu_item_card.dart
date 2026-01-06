import 'package:flutter/material.dart';
import '../../../models/menu_item.dart';
import '../../../models/item_model.dart';
import '../../../screen/user/store_screen/detail_item.dart'; // Ensure this import points to GuestDetailItem file

class MenuItemCard extends StatelessWidget {
  final ShopItem shopItem;
  // We keep this parameter to match your existing calls, 
  // though we primarily use shopItem.item for data.
  final MenuItem item;

  final int ? userId;

  const MenuItemCard({super.key, required this.shopItem, required this.item,this.userId});

  @override
  Widget build(BuildContext context) {
    final product = shopItem.item;
    final shopId = shopItem.shopId;

    // Theme Colors
    final Color freshMintGreen = const Color(0xFF4E8D7C);
    final Color espressoBrown = const Color(0xFF4B2C20);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GuestDetailItem(
                itemId: product.id,
                shopId: shopId,
                userId: userId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                width: 85,
                height: 85,
                color: Colors.grey[50],
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 85,
                      height: 85,
                      color: Colors.grey[100],
                      child: Icon(Icons.image_not_supported_outlined, size: 24, color: Colors.grey[400]),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 20, 
                        height: 20,
                        child: CircularProgressIndicator(
                          color: freshMintGreen,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(width: 16),

            // 2. Info Column
            Expanded(
              child: SizedBox(
                height: 85, // Match image height for alignment
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: espressoBrown,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        // Display description if available, else standard text
                        Text(
                          (product.description != null && product.description!.isNotEmpty) 
                              ? product.description! 
                              : "Delicious choice",
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                    
                    // Price and Add Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${(product.priceCents / 100).toStringAsFixed(2)}', 
                          style: TextStyle(
                            fontSize: 16,
                            color: freshMintGreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: freshMintGreen.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add, size: 20, color: freshMintGreen),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}