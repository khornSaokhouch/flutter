// lib/screen/shops/widgets/add_product_sheet.dart
import 'dart:math';
import 'dart:convert';

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
  bool _isRefreshing = false;

  /// Tracks which item IDs are currently being created (loading)
  final Set<String> _loadingIds = {};

  Color get _accentColor => const Color(0xFFB2865B);

  @override
  void initState() {
    super.initState();
    _items = List<Map<String, dynamic>>.from(widget.initialItems);
  }

  /// Helper to extract a stable id string from various item shapes
  String? _extractId(Map<String, dynamic> item) {
    final possibleIdKeys = ['id', 'item_id', 'product_id'];

    for (final k in possibleIdKeys) {
      if (item.containsKey(k) && item[k] != null) {
        return item[k].toString();
      }
    }

    final nested = item['item'];
    if (nested is Map) {
      final nestedId = nested['id'];
      if (nestedId != null) return nestedId.toString();
    }

    return null;
  }

  /// Determine if the provided item is already added (based on widget.initialItems).
  bool _isAlreadyAdded(Map<String, dynamic> item) {
    final id = _extractId(item);
    if (id == null) return false;

    return widget.initialItems.any((existing) {
      final existingId = _extractId(Map<String, dynamic>.from(existing));
      return existingId != null && existingId == id;
    });
  }

  /// Refresh items from the provided callback, but FILTER OUT items that are already added.
  Future<void> _refreshItems() async {
    if (widget.onRefreshRequested == null) return;

    setState(() => _isRefreshing = true);

    try {
      final res = await widget.onRefreshRequested!();

      final normalized = <Map<String, dynamic>>[];

      for (final r in res) {
        Map<String, dynamic> item;
        if (r is Map<String, dynamic>) item = r;
        else if (r is Map) item = Map<String, dynamic>.from(r);
        else item = {'value': r.toString()};

        // Only keep items NOT already added
        if (!_isAlreadyAdded(item)) {
          normalized.add(item);
        }
      }

      if (mounted) setState(() => _items = normalized);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to refresh: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  String _sheetTitle() {
    if (_items.isNotEmpty) {
      final first = _items[0];
      if (first['name'] != null) return first['name'].toString();
      if (first['title'] != null) return first['title'].toString();
      if (first['value'] != null) return first['value'].toString();
      return first.toString();
    }
    return 'No Name';
  }

  Map<String, dynamic> _buildItemOwnerPayload(Map<String, dynamic> item) {
    final possibleIdKeys = ['id', 'item_id', 'product_id'];
    int? itemId;

    for (final k in possibleIdKeys) {
      if (item.containsKey(k) && item[k] != null) {
        final v = item[k];
        if (v is int) itemId = v;
        else itemId = int.tryParse(v.toString());
        if (itemId != null) break;
      }
    }

    if (itemId == null && item['item'] is Map) {
      final nested = item['item'] as Map;
      if (nested['id'] is int) itemId = nested['id'] as int;
      else if (nested['id'] is String) itemId = int.tryParse(nested['id'] as String);
    }

    if (itemId == null) {
      throw Exception('Unable to determine item id for: ${item.toString()}');
    }

    return {
      'item_id': itemId,
      'shop_id': widget.shopId,
      'category_id': widget.categoryId,
      'inactive': 1,
    };
  }

  /// Creates an item and manages per-item loading state by ID.
  /// On success: calls widget.onCreated (if present) and removes the created item
  /// from the local `_items` list so it disappears from the sheet immediately.
  Future<void> _createItemFromMap(Map<String, dynamic> item) async {
    Map<String, dynamic> payload;

    try {
      payload = _buildItemOwnerPayload(item);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot create item: $e')));
      }
      return;
    }

    final idStr = (payload['item_id']?.toString() ?? _extractId(item) ?? UniqueKey().toString());

    // mark this id as loading so UI shows a spinner on that row
    if (mounted) setState(() => _loadingIds.add(idStr));

    try {
      // Call server; returns List<ItemOwnerModel>?
      final List<ItemOwnerModel>? created = await ItemOwnerService.createItemOwners([payload]);

      // clear loading indicator
      if (mounted) setState(() => _loadingIds.remove(idStr));

      if (created == null || created.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('No valid items returned by server.')));
        }
        return;
      }

      if (mounted) {
        final displayName = (item['name'] ?? item['title'] ?? payload['item_id'].toString()).toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added "$displayName" successfully.')));
      }

      // Notify callback (best-effort cast)
      if (widget.onCreated != null) {
        try {
          widget.onCreated!(created.cast<ItemOwner>());
        } catch (_) {
          // swallow casting/conversion errors to avoid crashing UI
        }
      }

      // Remove the created item from the local visible list immediately so it no longer shows.
      if (mounted) {
        setState(() {
          _items.removeWhere((e) {
            final eId = _extractId(e);
            return eId != null && eId == idStr;
          });
        });
      }
    } catch (err) {
      // clear loading indicator
      if (mounted) setState(() => _loadingIds.remove(idStr));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $err')));
      }
    }
  }

  String _formatPrice(dynamic rawPrice) {
    String priceStr = '—';
    try {
      if (rawPrice == null) return priceStr;
      if (rawPrice is int) return (rawPrice / 100).toStringAsFixed(2);
      if (rawPrice is double) {
        if (rawPrice >= 100) return (rawPrice / 100).toStringAsFixed(2);
        return rawPrice.toStringAsFixed(2);
      }
      if (rawPrice is String) {
        final s = rawPrice;
        if (s.contains('.')) {
          final d = double.tryParse(s) ?? 0.0;
          return d.toStringAsFixed(2);
        } else {
          final iVal = int.tryParse(s);
          if (iVal != null) return (iVal / 100).toStringAsFixed(2);
        }
      }
    } catch (_) {}
    return priceStr;
  }

  @override
  Widget build(BuildContext context) {
    final title = _sheetTitle();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: min(MediaQuery.of(context).size.height * 0.75, 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Items in ${widget.categoryName.isNotEmpty ? widget.categoryName : title}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_items.length} item${_items.length == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('No items available.'))
                  : ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (ctx, i) {
                  final item = _items[i];
                  String name = 'Unnamed';
                  String? imageUrl;
                  final rawPrice = item['price_cents'] ?? item['price'] ?? item['price_cents'];

                  if (item['name'] != null) name = item['name'].toString();
                  else if (item['title'] != null) name = item['title'].toString();
                  else if (item['value'] != null) name = item['value'].toString();

                  if (item['image_url'] != null) imageUrl = item['image_url'].toString();
                  else if (item['image'] != null) imageUrl = item['image'].toString();

                  final priceStr = _formatPrice(rawPrice);

                  final idStr = _extractId(item) ?? i.toString();
                  final isLoading = _loadingIds.contains(idStr);

                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: (imageUrl != null && imageUrl.startsWith('http'))
                            ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image),
                          ),
                        )
                            : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.local_cafe),
                        ),
                      ),
                    ),
                    title: Text(name),
                    subtitle: Text('\$${priceStr}'),
                    trailing: isLoading
                        ? SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                        : IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () async {
                        // Prevent double taps while this item is being created
                        if (_loadingIds.contains(idStr)) return;

                        final mapItem = (item is Map<String, dynamic>)
                            ? Map<String, dynamic>.from(item)
                            : {'value': item.toString()};

                        await _createItemFromMap(mapItem);
                      },
                    ),
                    onTap: () {},
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // NOTE: intentionally not refreshing the list here.
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
                  child: const Text('Add New'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
