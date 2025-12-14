import 'package:flutter/material.dart';
import '../../../models/shop.dart';
import '../../utils/message_utils.dart';
import '../../utils/utils.dart'; // Keep your import

class ShopCard extends StatelessWidget {
  final Shop shop;
  final VoidCallback? onTap;

  const ShopCard({
    super.key,
    required this.shop,
    this.onTap,
  });

  bool get isOpen => shop.status == 1;



  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06), // Soft shadow
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // 1. SHOP IMAGE (Large & Rounded)
                Hero(
                  tag: 'shop_${shop.name}', // Optional animation tag
                  child: Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[200],
                      image: (shop.imageUrl != null && shop.imageUrl!.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(shop.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (shop.imageUrl == null || shop.imageUrl!.isEmpty)
                        ? const Icon(Icons.store_rounded, size: 30, color: Colors.grey)
                        : null,
                  ),
                ),
                
                const SizedBox(width: 16),

                // 2. SHOP INFO COLUMN
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Status Badge (Open/Closed)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              shop.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          _buildStatusBadge(),
                        ],
                      ),
                      
                      const SizedBox(height: 8),

                      // Location Row
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, 
                               size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shop.location ?? 'No location info',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),

                      // Time Row
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, 
                               size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            (shop.openTime != null && shop.closeTime != null)
                                ? '${formatTimeToAmPm(context, shop.openTime)} - ${formatTimeToAmPm(context, shop.closeTime)}'
                                : 'Hours unavailable',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
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
        ),
      ),
    );
  }

  // Helper Widget for the "Open/Closed" Pill
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen 
            ? const Color(0xFFE8F5E9)  // Light Green bg
            : const Color(0xFFFFEBEE), // Light Red bg
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          color: isOpen 
              ? const Color(0xFF2E7D32) // Dark Green text
              : const Color(0xFFC62828), // Dark Red text
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}