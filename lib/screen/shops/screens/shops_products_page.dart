// lib/screen/shops/screens/shops_products_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../server/item_service.dart';

class ShopsProductsPage extends StatefulWidget {
  final int shopId;
  const ShopsProductsPage({super.key, required this.shopId});

  @override
  State<ShopsProductsPage> createState() => _ShopsProductsPageState();
}

class _ShopsProductsPageState extends State<ShopsProductsPage> {
  // theme
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  bool _isLoading = true;
  String? _error;

  // Normalized list for UI
  List<Map<String, dynamic>> _items = [];

  // busy set uses ownerId (ItemOwner id)
  final Set<int> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final resp = await ItemService.fetchItemsByShop(widget.shopId);
      if (resp == null) {
        if (!mounted) return;
        setState(() {
          _items = [];
          _error = 'No items found';
        });
        return;
      }

      // resp.data is List<ShopItem>
      final normalized = <Map<String, dynamic>>[];
      for (final raw in resp.data) {
        // raw is ShopItem
        final shopItem = raw;
        final it = shopItem.item;
        final cat = shopItem.category;

        normalized.add({
          'id': it.id, // product id
          'ownerId': shopItem.id, // crucial: this is the ItemOwner id (use when updating status)
          'name': it.name,
          // priceCents in response is numeric string like "190.00" -> treat as cents and convert to dollars
          'price': (it.priceCents / 100.0),
          'category': cat.name,
          'image': it.imageUrl,
          // inactive on ShopItem: 0 == active. Map to boolean.
          'active': (shopItem.inactive == 0),
          'rawShopItem': shopItem,
        });
      }

      if (!mounted) return;
      setState(() => _items = normalized);
    } catch (e, st) {
      if (kDebugMode) debugPrint('loadItems error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _items = [];
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActiveOptimistic(int index, bool newValue) async {
    final itemMap = _items[index];

    // Robust ownerId parsing: allow int or numeric string; fallback to 0
    final dynamic ownerRaw = itemMap['ownerId'];
    final int ownerId = ownerRaw is int
        ? ownerRaw
        : (ownerRaw is String ? int.tryParse(ownerRaw) ?? 0 : 0);

    final productId = (itemMap['id'] is int)
        ? itemMap['id'] as int
        : int.tryParse(itemMap['id']?.toString() ?? '') ?? 0;

    if (ownerId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item-owner record missing for product $productId. Refresh and try again.')),
      );
      return;
    }

    // backend expects inactive: 0 == active, 1 == inactive
    final newInactive = newValue ? 1:0 ;

    if (!mounted) return;
    setState(() {
      _busyIds.add(ownerId);
      _items[index]['active'] = newValue; // optimistic
    });

    try {
      final svc = ItemService();
      // call the update method (await it)
      final result = await svc.updateItemStatus(id: ownerId, newStatus: newInactive);

      // If your API returns something other than true on success, adjust this check.
      if (!result) throw Exception('Server returned failure');
          // success: UI already updated optimistically
    } catch (e) {
      if (kDebugMode) debugPrint('updateItemStatus error: $e');
      // revert optimistic UI
      if (!mounted) return;
      setState(() {
        _items[index]['active'] = !newValue;
      });

      final msg = e.toString().toLowerCase();
      if (msg.contains('404') || msg.contains('itemowner not found') || msg.contains('item owner not found')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item-owner not found on server. Try refreshing.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update item: $e')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() => _busyIds.remove(ownerId));
    }
  }

  Widget _buildItemRow(Map<String, dynamic> item, int index) {
    final id = item['id'] as int?;
    final ownerId = item['ownerId'] as int?;
    final name = (item['name'] ?? 'Unnamed').toString();
    final category = (item['category'] ?? '').toString();
    final price = (item['price'] is num) ? (item['price'] as num).toDouble() : double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    final imageUrl = (item['image'] ?? '').toString();
    final isActive = (item['active'] is bool) ? item['active'] as bool : (item['active'] == 1);

    final busy = ownerId != null && _busyIds.contains(ownerId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Stack(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                    : Icon(Icons.image, color: _freshMintGreen),
              ),
            ),
            title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.black87 : Colors.grey)),
            subtitle: Text(
              "$category • \$${price.toStringAsFixed(2)}",
              style: TextStyle(color: isActive ? _freshMintGreen : Colors.grey[400], fontWeight: FontWeight.w600),
            ),
            trailing: Switch(
              value: isActive,
              activeColor: _freshMintGreen,
              onChanged: busy ? null : (v) => _toggleActiveOptimistic(index, v),
            ),
            onTap: () {},
          ),

          if (!isActive)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Icon(Icons.visibility_off, size: 28, color: Colors.black45)),
              ),
            ),

          if (busy)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
                child: const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2))),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text("PRODUCTS", style: TextStyle(color: _espressoBrown, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 1.0)),
        centerTitle: true,
        actions: [IconButton(onPressed: _loadItems, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: add product flow
        },
        backgroundColor: _espressoBrown,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
          ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
          : _items.isEmpty
          ? Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('No items')
          ]))
          : RefreshIndicator(
        onRefresh: _loadItems,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          itemCount: _items.length,
          itemBuilder: (context, i) => _buildItemRow(_items[i], i),
        ),
      ),
    );
  }
}
