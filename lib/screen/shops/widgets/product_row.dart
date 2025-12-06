// lib/widgets/product_row.dart
import 'package:flutter/material.dart';
import 'package:frontend/models/shops_models/shop_item_owner_models.dart';
import 'package:frontend/screen/shops/screens/shop_product_detai.dart';

class ProductRow extends StatefulWidget {
  final int index;
  final ItemOwner itemOwner;
  final Color accentColor;
  final int shopId;
  final void Function(ItemOwner itemOwner)? onTap;
  final Future<void> Function(ItemOwner itemOwner, bool newStatus)? onToggleStatus;

  const ProductRow({
    super.key,
    required this.index,
    required this.itemOwner,
    required this.accentColor,
    required this.shopId,
    this.onTap,
    this.onToggleStatus,
  });

  @override
  State<ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<ProductRow> {
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    final itemOwner = widget.itemOwner;
    final item = itemOwner.item;
    final category = itemOwner.category;

    // Image resolution
    String? imageUrl;
    try {
      if (item?.imageUrl != null && item!.imageUrl.isNotEmpty) imageUrl = item!.imageUrl;
    } catch (_) {}

    // Price resolution
    double price = 0.0;
    try {
      final dynamic priceField = item?.priceCents;
      if (priceField != null) {
        if (priceField is num) {
          price = (priceField >= 100) ? (priceField / 100.0) : priceField.toDouble();
        } else if (priceField is String) {
          final parsed = double.tryParse(priceField) ?? 0.0;
          price = (parsed >= 100) ? (parsed / 100.0) : parsed;
        }
      }
    } catch (_) {}

    // Status Logic: 
    // Assuming backend logic: inactive == 1 means Active (based on your previous code snippet toggle logic).
    // Or if inactive == 1 means Inactive.
    // Standard interpretation: inactive=1 is INACTIVE. inactive=0 is ACTIVE.
    // Based on user snippet `final bool isActive = (inactiveVal == 1);` -> This implies 1 is Active in your specific DB.
    // I will respect that specific line from your provided code.
    final int inactiveVal = itemOwner.inactive ?? 0;
    final bool isActive = (inactiveVal == 1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: isActive ? Colors.transparent : Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!isActive) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('This product is inactive and cannot be opened.'), behavior: SnackBarBehavior.floating),
              );
              return;
            }
            if (widget.onTap != null) {
              widget.onTap!(itemOwner);
            } else if (item != null) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ShopProductDetailPage(itemId: item.id, shopId: widget.shopId)),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Image
                Stack(
                  children: [
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ColorFiltered(
                          colorFilter: isActive 
                              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                              : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                          child: (imageUrl != null && imageUrl.startsWith('http'))
                              ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.broken_image, color: Colors.grey[400]))
                              : Icon(Icons.image_not_supported_outlined, color: Colors.grey[400]),
                        ),
                      ),
                    ),
                    if (!isActive)
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          ),
                          alignment: Alignment.center,
                          child: const Text("OFF", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      )
                  ],
                ),
                
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item?.name.toString() ?? 'Unnamed',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "\$${price.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: isActive ? widget.accentColor : Colors.grey,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if(category != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                              child: Text(category.name, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                            )
                        ],
                      ),
                    ],
                  ),
                ),

                // Switch
                SizedBox(
                  height: 30,
                  child: _isToggling
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: isActive,
                            activeColor: widget.accentColor,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Colors.grey.shade300,
                            onChanged: (newStatus) async {
                              if (widget.onToggleStatus != null) {
                                setState(() => _isToggling = true);
                                try {
                                  await widget.onToggleStatus!(itemOwner, newStatus);
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                                } finally {
                                  if (mounted) setState(() => _isToggling = false);
                                }
                              }
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}