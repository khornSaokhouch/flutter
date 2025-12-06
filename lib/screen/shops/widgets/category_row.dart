import 'package:flutter/material.dart';
import '../../../models/shops_models/shop_categories_models.dart';

class CategoryRow extends StatefulWidget {
  final int index;
  final CategoryModel item;
  final Color accentColor;
  final VoidCallback? onTap;
  final Future<void> Function(int categoryId, bool newStatus)? onStatusChanged;
  final void Function(String action)? onMenuSelected;

  const CategoryRow({
    Key? key,
    required this.index,
    required this.item,
    required this.accentColor,
    this.onTap,
    this.onStatusChanged,
    this.onMenuSelected,
  }) : super(key: key);

  @override
  State<CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<CategoryRow> {
  bool _isToggling = false;

  // Logic: 1 = Active, 0 = Inactive
  bool get _canOpen => (widget.item.status == 1) && ((widget.item.pivot?.status ?? 1) == 1);

  // Theme Colors
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);

  @override
  Widget build(BuildContext context) {
    final bool isActive = _canOpen;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        // Subtle border to indicate active/inactive
        border: Border.all(
          color: isActive ? Colors.transparent : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!isActive) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('This category is currently inactive.'),
                  backgroundColor: Colors.grey[800],
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            if (widget.onTap != null) widget.onTap!();
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // 1. Image Section
                Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ColorFiltered(
                          // Gray out image if inactive
                          colorFilter: isActive 
                              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                              : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                          child: (widget.item.imageCategoryUrl.isNotEmpty)
                              ? Image.network(
                                  widget.item.imageCategoryUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(Icons.category, color: _freshMintGreen),
                                )
                              : Icon(Icons.category, color: _freshMintGreen),
                        ),
                      ),
                    ),
                    if (!isActive)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        left: 0,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "OFF",
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                  ],
                ),

                const SizedBox(width: 16),

                // 2. Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Details Chips
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildDetailChip("Variant Price", isActive),
                          _buildDetailChip("Addon Price", isActive),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Actions Section (Switch + Menu)
                Column(
                  children: [
                    // Switch
                    SizedBox(
                      height: 30,
                      child: _isToggling
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: widget.accentColor,
                              ),
                            )
                          : Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: isActive,
                                activeColor: _freshMintGreen,
                                activeTrackColor: _freshMintGreen.withOpacity(0.2),
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: Colors.grey[300],
                                onChanged: (val) async {
                                  if (widget.onStatusChanged == null) return;
                                  setState(() => _isToggling = true);
                                  try {
                                    await widget.onStatusChanged!(widget.item.id, val);
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Update failed: $e')),
                                    );
                                  } finally {
                                    if (mounted) setState(() => _isToggling = false);
                                  }
                                },
                              ),
                            ),
                    ),
                    // Menu
                    SizedBox(
                      height: 30,
                      child: PopupMenuButton<String>(
                        icon: Icon(Icons.more_horiz, color: Colors.grey[400]),
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (widget.onMenuSelected != null) widget.onMenuSelected!(value);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18, color: Colors.black54),
                                SizedBox(width: 8),
                                Text('Edit Name'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Remove', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.grey[100] : Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isActive ? Colors.grey[300]! : Colors.grey[200]!),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: isActive ? Colors.grey[600] : Colors.grey[400],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}