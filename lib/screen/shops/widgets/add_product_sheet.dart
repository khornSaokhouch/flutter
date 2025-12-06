
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
  final Set<String> _loadingIds = {};

  // Theme
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);

  @override
  void initState() {
    super.initState();
    _items = List<Map<String, dynamic>>.from(widget.initialItems);
  }

  String? _extractId(Map<String, dynamic> item) {
    if (item.containsKey('id')) return item['id'].toString();
    if (item['item'] is Map && item['item']['id'] != null) return item['item']['id'].toString();
    return null;
  }

  Future<void> _createItemFromMap(Map<String, dynamic> item) async {
    int? itemId;
    if(item['id'] != null) itemId = int.tryParse(item['id'].toString());
    if(itemId == null && item['item'] is Map && item['item']['id'] != null) {
       itemId = int.tryParse(item['item']['id'].toString());
    }
    
    if (itemId == null) return;

    final idStr = itemId.toString();
    setState(() => _loadingIds.add(idStr));

    try {
      final payload = {
        'item_id': itemId,
        'shop_id': widget.shopId,
        'category_id': widget.categoryId,
        'inactive': 1,
      };

      final List<ItemOwnerModel>? created = await ItemOwnerService.createItemOwners([payload]);
      
      if (mounted) setState(() => _loadingIds.remove(idStr));

      if (created != null && created.isNotEmpty) {
        if (mounted) {
          setState(() {
            _items.removeWhere((e) => _extractId(e) == idStr);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Product added successfully'),
              backgroundColor: _freshMintGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (widget.onCreated != null) widget.onCreated!(created.cast<ItemOwner>());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingIds.remove(idStr));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  String _formatPrice(dynamic rawPrice) {
    if (rawPrice == null) return '—';
    double val = 0.0;
    if (rawPrice is int) val = rawPrice / 100;
    else if (rawPrice is double) val = rawPrice >= 100 ? rawPrice / 100 : rawPrice;
    else if (rawPrice is String) {
        double? parsed = double.tryParse(rawPrice);
        if(parsed != null) val = parsed >= 100 ? parsed / 100 : parsed;
    }
    return val.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            child: Row(
              children: [
                Column(
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
                      "To ${widget.categoryName}",
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
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
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 30), // Added bottom padding
                  itemCount: _items.length,
                  separatorBuilder: (_,__) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final item = _items[i];
                    
                    // Name resolution
                    String name = 'Unnamed';
                    if (item['name'] != null) name = item['name'].toString();
                    else if (item['item'] is Map && item['item']['name'] != null) name = item['item']['name'].toString();

                    // Price resolution
                    dynamic rawPrice = item['price_cents'];
                    if(rawPrice == null && item['item'] is Map) rawPrice = item['item']['price_cents'];
                    final priceStr = _formatPrice(rawPrice);

                    // Image resolution
                    String? imageUrl;
                    if (item['image_url'] != null) imageUrl = item['image_url'].toString();
                    else if (item['item'] is Map && item['item']['image_url'] != null) imageUrl = item['item']['image_url'].toString();

                    final idStr = _extractId(item) ?? i.toString();
                    final isLoading = _loadingIds.contains(idStr);

                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: (imageUrl != null && imageUrl.isNotEmpty) 
                                ? Image.network(
                                    imageUrl, 
                                    fit: BoxFit.cover,
                                    errorBuilder: (_,__,___) => const Icon(Icons.broken_image),
                                  ) 
                                : Icon(Icons.image, color: Colors.grey[400]),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                          isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : IconButton(
                                icon: Icon(Icons.add_circle, color: _espressoBrown),
                                onPressed: () => _createItemFromMap(item),
                              ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}