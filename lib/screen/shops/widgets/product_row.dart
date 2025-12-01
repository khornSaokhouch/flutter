// lib/widgets/product_row.dart
import 'package:flutter/material.dart';
import 'package:frontend/models/shops_models/shop_item_owner_models.dart';
import 'package:frontend/screen/shops/screens/shop_product_detai.dart';

/// ProductRow displays a single ItemOwner row (image, title, category, price, stock, status).
/// - Calls [onTap] when row tapped (if provided). If not provided, it navigates to ShopProductDetail when item exists.
/// - Calls [onToggleStatus] when switch toggled (receives ItemOwner and newStatus bool).
/// - Shows a per-row loader while toggle Future is running.
class ProductRow extends StatefulWidget {
  final int index;
  final ItemOwner itemOwner;
  final Color accentColor;

  final int shopId;

  /// Optional callback when the whole row is tapped.
  final void Function(ItemOwner itemOwner)? onTap;

  /// Toggle callback: should perform network update. If omitted, widget will call nothing.
  /// Return/await the Future so the widget can show/hide its internal loader.
  final Future<void> Function(ItemOwner itemOwner, bool newStatus)? onToggleStatus;

  const ProductRow({
    super.key,
    required this.index,
    required this.itemOwner,
    required this.accentColor,
    this.onTap,
    this.onToggleStatus, required this.shopId,
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

    // defensive image resolution
    String? imageUrl;
    try {
      final dynamic possible = item?.imageUrl;
      if (possible is String && possible.isNotEmpty) imageUrl = possible;
    } catch (_) {
      imageUrl = null;
    }

    // price resolution (same logic as original)
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
    } catch (_) {
      price = 0.0;
    }

    final int inactiveVal = itemOwner.inactive ?? 0;
    final bool isActive = (inactiveVal == 1);

    final double contentIndent = 24 + 12 + 48 + 12;
    final int? id = itemOwner.id;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          // Determine active state: inactive == 1 means ACTIVE in your backend
          final int inactiveVal = itemOwner.inactive ?? 0;
          final bool isOn = inactiveVal == 1; // ACTIVE only when == 1

          // If inactive, block navigation
          if (!isOn) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This product is inactive and cannot be opened.')),
            );
            return;
          }

          // If parent provided custom onTap, call it
          if (widget.onTap != null) {
            widget.onTap!(itemOwner);
            return;
          }

          // Default navigation
          if (item != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ShopProductDetailPage(itemId:item.id, shopId:widget.shopId),
                //   builder: (_) => ShopProductDetailPage(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item details unavailable')),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${widget.index + 1}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: imageUrl != null && imageUrl.startsWith('http')
                            ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.broken_image, size: 22, color: Colors.grey),
                          ),
                        )
                            : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported_outlined, size: 22, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item?.name.toString() ?? 'Unnamed Item',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(category?.name.toString() ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (value) {
                        // parent can implement via onTap approach if needed
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              // Price
              Padding(
                padding: EdgeInsets.only(left: contentIndent, right: 16),
                child: Row(
                  children: [
                    const Text('Price', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const Spacer(),
                    Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Stock
              Padding(
                padding: EdgeInsets.only(left: contentIndent, right: 16),
                child: Row(
                  children: [
                    const Text('Stock', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const Spacer(),
                    const Text('0', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Status row
              Padding(
                padding: EdgeInsets.only(left: contentIndent, right: 16, bottom: 10),
                child: Row(
                  children: [
                    const Text('Status', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const Spacer(),
                    if (_isToggling)
                      const SizedBox(
                        width: 36,
                        height: 24,
                        child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                      )
                    else
                      Switch(
                        value: isActive,
                        activeThumbColor: Colors.white,
                        activeTrackColor: widget.accentColor,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey.shade400,
                        onChanged: (id == null)
                            ? null
                            : (newStatus) async {
                          if (widget.onToggleStatus == null) return;
                          setState(() => _isToggling = true);
                          try {
                            await widget.onToggleStatus!(itemOwner, newStatus);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
                          } finally {
                            if (mounted) setState(() => _isToggling = false);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
