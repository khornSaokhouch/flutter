import 'package:flutter/material.dart';
import '../../../models/shops_models/item_owner_model.dart';
import '../../../models/shops_models/shop_item_owner_models.dart';
import '../../../server/shops_server/item_owner_service.dart';

class AddProductSheet extends StatefulWidget {
  final List<Map<String, dynamic>> initialItems;
  final int shopId;
  final int categoryId;
  final String categoryName;
  final Future<List<Map<String, dynamic>>> Function()? onRefreshRequested;
  final void Function(List<ItemOwner>)? onCreated;

  const AddProductSheet({
    super.key,
    this.initialItems = const [],
    required this.shopId,
    required this.categoryId,
    required this.categoryName,
    this.onRefreshRequested,
    this.onCreated,
  });

  @override
  State<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<AddProductSheet> {
  late List<Map<String, dynamic>> _items;
  
  // Tracking selections
  final Set<String> _selectedIds = {};
  bool _isSubmitting = false;

  // Theme
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);

  @override
  void initState() {
    super.initState();
    _items = List<Map<String, dynamic>>.from(widget.initialItems);
  }

  String? _extractId(Map<String, dynamic> item) {
    if (item['id'] != null) return item['id'].toString();
    if (item['item'] is Map && item['item']['id'] != null) return item['item']['id'].toString();
    return null;
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _items.length) {
        _selectedIds.clear();
      } else {
        for (var item in _items) {
          final id = _extractId(item);
          if (id != null) _selectedIds.add(id);
        }
      }
    });
  }

  Future<void> _createSelectedItems() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      // Build payloads for all selected items
      final List<Map<String, dynamic>> payloads = [];
      
      for (final idStr in _selectedIds) {
        _items.firstWhere((e) => _extractId(e) == idStr);
        int? itemId = int.tryParse(idStr);
        
        if (itemId != null) {
          payloads.add({
            'item_id': itemId,
            'shop_id': widget.shopId,
            'category_id': widget.categoryId,
            'inactive': 1,
          });
        }
      }

      final List<ItemOwnerModel>? created = await ItemOwnerService.createItemOwners(payloads);

      if (created != null && created.isNotEmpty) {
        if (mounted) {
          if (widget.onCreated != null) widget.onCreated!(created.cast<ItemOwner>());
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatPrice(dynamic rawPrice) {
    if (rawPrice == null) return '—';
    double val = 0.0;
    if (rawPrice is int) val = rawPrice / 100;
    else if (rawPrice is double) val = rawPrice >= 100 ? rawPrice / 100 : rawPrice;
    else if (rawPrice is String) {
      double? parsed = double.tryParse(rawPrice);
      if (parsed != null) val = parsed >= 100 ? parsed / 100 : parsed;
    }
    return val.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final bool isAllSelected = _selectedIds.length == _items.length && _items.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 15, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Add Products",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _espressoBrown,
                            ),
                          ),
                          Text(
                            _selectedIds.isEmpty 
                                ? "To ${widget.categoryName}" 
                                : "${_selectedIds.length} items selected",
                            style: TextStyle(
                              color: _selectedIds.isEmpty ? Colors.grey[500] : _freshMintGreen, 
                              fontSize: 13,
                              fontWeight: _selectedIds.isEmpty ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_items.isNotEmpty)
                      TextButton.icon(
                        onPressed: _isSubmitting ? null : _toggleSelectAll,
                        icon: Icon(isAllSelected ? Icons.deselect : Icons.select_all, size: 18, color: _freshMintGreen),
                        label: Text(
                          isAllSelected ? "None" : "All",
                          style: TextStyle(color: _freshMintGreen, fontWeight: FontWeight.bold),
                        ),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // List
              Expanded(
                child: _items.isEmpty
                    ? Center(child: Text("No available items found.", style: TextStyle(color: Colors.grey[500])))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 15, 20, 120), // Bottom padding for button
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final item = _items[i];
                          final idStr = _extractId(item) ?? i.toString();
                          final isSelected = _selectedIds.contains(idStr);

                          // Name resolution
                          String name = 'Unnamed';
                          if (item['name'] != null) name = item['name'].toString();
                          else if (item['item'] is Map && item['item']['name'] != null) name = item['item']['name'].toString();

                          // Price resolution
                          dynamic rawPrice = item['price_cents'];
                          if (rawPrice == null && item['item'] is Map) rawPrice = item['item']['price_cents'];
                          final priceStr = _formatPrice(rawPrice);

                          // Image resolution
                          String? imageUrl;
                          if (item['image_url'] != null) imageUrl = item['image_url'].toString();
                          else if (item['item'] is Map && item['item']['image_url'] != null) imageUrl = item['item']['image_url'].toString();

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? _freshMintGreen.withValues(alpha: 0.05) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? _freshMintGreen : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _isSubmitting ? null : () => _toggleSelection(idStr),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: (imageUrl != null && imageUrl.isNotEmpty)
                                            ? Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                              )
                                            : Icon(Icons.image, color: Colors.grey[400]),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '\$$priceStr',
                                            style: TextStyle(
                                              color: _freshMintGreen,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Custom Checkbox/Selection Indicator
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isSelected ? _freshMintGreen : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? _freshMintGreen : Colors.grey[300]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected 
                                          ? const Icon(Icons.check, size: 16, color: Colors.white) 
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // Sticky Bottom Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              

            
child: ElevatedButton(
  onPressed: (_isSubmitting || _selectedIds.isEmpty) ? null : _createSelectedItems,
  style: ElevatedButton.styleFrom(
    backgroundColor: _freshMintGreen, // <-- use your custom color here
    disabledBackgroundColor: Colors.grey[300],
    minimumSize: const Size(double.infinity, 56),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 0,
  ),
  child: _isSubmitting
      ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        )
      : Text(
          _selectedIds.isEmpty 
              ? "Select Products" 
              : "Add ${_selectedIds.length} Products",
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 16, 
            fontWeight: FontWeight.bold,
          ),
        ),
),

            ),
          ),
        ],
      ),
    );
  }
}