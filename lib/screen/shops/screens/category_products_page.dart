// file: category_products_page.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../models/item_model.dart';
import '../../../models/shops_models/shop_item_owner_models.dart';
import '../../../server/shops_server/item_owner_service.dart';

class CategoryProductsPage extends StatefulWidget {
  final int shopId;
  final int categoryId;
  final String categoryName;

  const CategoryProductsPage({
    super.key,
    required this.shopId,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;

  int _rowsPerPage = 10;
  int _currentPage = 1;

  /// All products (ItemOwner records) loaded from the API
  List<ItemOwner> _products = [];

  /// Raw items response data used by the bottom sheet (keeps original maps)
  List<Map<String, dynamic>> _itemsRaw = [];

  Timer? _searchDebounce;

  /// Track IDs that are currently being updated (status toggle)
  final Set<int> _updatingIds = {};

  Color get _accentColor => const Color(0xFFB2865B); // coffee brown

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // load typed products first, then raw items (so we can filter by existing ids)
    _loadProductsFromApi().whenComplete(() => _loadProducts());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce search input (300ms)
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _currentPage = 1; // reset to first page when query changes
      });
    });
  }

  /// Load typed ItemOwner list from the API (the shop's current items)
  Future<void> _loadProductsFromApi() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final itemOwners = await ItemOwnerService.fetchItemsByShopAndCategory(
        shopId: widget.shopId,
        categoryId: widget.categoryId,
      );

      if (mounted) {
        setState(() {
          _products = itemOwners ?? <ItemOwner>[];
          _isLoading = false;
          _currentPage = 1;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  /// Return a set of item IDs already present in _products
  Set<int> _existingItemIds() {
    final Set<int> ids = {};
    for (final owner in _products) {
      try {
        final int? id = owner.item?.id;
        if (id != null) ids.add(id);
      } catch (_) {
        // ignore
      }
    }
    return ids;
  }

  /// Loads raw items (used by the bottom sheet). Handles several return shapes,
  /// then filters out any item already present in _products by ID (or name optionally).
  Future<void> _loadProducts() async {
    setState(() {
      _error = null;
    });

    try {
      final results = await ItemOwnerService.fetchItemsByCategory(widget.categoryId);

      // results may be List<Map<String,dynamic>> or List<Item> or List<dynamic>
      final List<Map<String, dynamic>> normalized = [];

      if (results is List<Map<String, dynamic>>) {
        normalized.addAll(results as Iterable<Map<String, dynamic>>);
      } else if (results is List) {
        for (final r in results) {
          if (r is Map<String, dynamic>) {
            normalized.add(r as Map<String, dynamic>);
          } else if (r is Map) {
            normalized.add(Map<String, dynamic>.from(r as Map));
          } else {
            // If it's an object (e.g. Item), try to call toJson() if available
            try {
              final jsonMap = (r as dynamic).toJson();
              if (jsonMap is Map<String, dynamic>) normalized.add(jsonMap);
            } catch (_) {
              // fallback: store a single-field representation
              normalized.add({'value': r.toString()});
            }
          }
        }
      }

      // Build set of existing item IDs from typed _products
      final existingIds = _existingItemIds();

      // Filter out items that already exist in _products
      final List<Map<String, dynamic>> filtered = [];
      for (final map in normalized) {
        // Try to get id from map['id'] or nested map['item']['id']
        int? id;
        if (map['id'] is int) id = map['id'] as int;
        else if (map['id'] is String) id = int.tryParse(map['id']);
        else if (map['item'] is Map) {
          final im = map['item'] as Map;
          if (im['id'] is int) id = im['id'] as int;
          else if (im['id'] is String) id = int.tryParse(im['id']);
        }

        // If id exists and is present in existingIds -> skip
        if (id != null && existingIds.contains(id)) {
          continue;
        }

        // Optional: skip by name if id missing to avoid duplicates by name
        // final name = (map['name'] ?? map['title'] ?? '').toString().trim().toLowerCase();
        // if (name.isNotEmpty && _products.any((p) => (p.item?.name ?? '').toLowerCase() == name)) continue;

        filtered.add(map);
      }

      if (mounted) {
        setState(() {
          _itemsRaw = filtered;
        });
      }
    } catch (e) {
      String msg = 'Failed to load items';
      if (e is Exception) msg = e.toString();
      if (mounted) {
        setState(() {
          _error = msg;
        });
      }
    }
    // no loading flag to toggle here (we use _isLoading for main list)
  }

  /// refresh handler for pull-to-refresh
  Future<void> _refresh() async {
    await _loadProductsFromApi();
    await _loadProducts();
  }

  List<ItemOwner> _applySearchFilter(String query) {
    if (query.isEmpty) return List<ItemOwner>.from(_products);

    final q = query.toLowerCase();
    return _products.where((p) {
      // Defensive: item or category or shop might be null depending on your model
      final itemName = (p.item?.name ?? '').toString().toLowerCase();
      final categoryName = (p.category?.name ?? '').toString().toLowerCase();
      final shopName = (p.shop?.name ?? '').toString().toLowerCase();
      return itemName.contains(q) ||
          categoryName.contains(q) ||
          shopName.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final filtered = _applySearchFilter(query);

    // Pagination: compute visible slice
    final total = filtered.length;
    final totalPages = max(1, (total / _rowsPerPage).ceil()); // at least 1 page
    if (_currentPage > totalPages) _currentPage = totalPages;

    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = min(startIndex + _rowsPerPage, total);
    final productsPage = (startIndex < endIndex) ? filtered.sublist(startIndex, endIndex) : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EE),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Error: $_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadProductsFromApi,
                  style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        )
            : RefreshIndicator(
          onRefresh: _refresh,
          child: productsPage.isEmpty
              ? ListView(
            // Use ListView so RefreshIndicator works on empty content
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'No products in this category yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // show sheet and then refresh raw data in background
                            _showAddProductSheet(context);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Add New Product',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
              : SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb
                const Text(
                  'Home  /  Products  /  Product List',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // Search
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                        color: Colors.black54,
                        width: 1,
                      ),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter + Add New Product buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: open filter dialog
                        },
                        icon: const Icon(Icons.filter_list),
                        label: const Text('Filter'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          side: const BorderSide(
                            color: Colors.black54,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showAddProductSheet(context); // refresh raw items in background
                        },
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Add New Product',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 32),

                // Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          'No',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Products',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      SizedBox(width: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),

                // Product list
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: productsPage.length,
                  separatorBuilder: (_, __) => const Divider(height: 32),
                  itemBuilder: (context, index) {
                    final globalIndex = startIndex + index;
                    final itemOwner = productsPage[index];
                    return _buildProductRow(globalIndex, itemOwner);
                  },
                ),

                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildPagination(total, totalPages),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows an Add Product sheet. Sheet reads `_itemsRaw` which was set by `_loadProducts()`.
  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        // compute a sheet title (first item's name or fallback)
        String title = 'No Name';
        if (_itemsRaw.isNotEmpty) {
          final first = _itemsRaw[0];
          if (first is Map && first['name'] != null) {
            title = first['name'].toString();
          } else if (first is Map && first['title'] != null) {
            title = first['title'].toString();
          } else {
            title = first.toString();
          }
        }

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            // If you want the sheet to expand to full height, use MediaQuery
            height: min(MediaQuery.of(context).size.height * 0.75, 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Items in ${widget.categoryName.isNotEmpty ? widget.categoryName : title}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () async {
                        // refresh raw items while sheet is open
                        await _loadProducts();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Show a short description count
                Text(
                  '${_itemsRaw.length} item${_itemsRaw.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // Items list (scrollable)
                Expanded(
                  child: _itemsRaw.isEmpty
                      ? const Center(child: Text('No items available.'))
                      : ListView.separated(
                    itemCount: _itemsRaw.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (ctx, i) {
                      final item = _itemsRaw[i];
                      // defensively extract fields
                      String name = 'Unnamed';
                      String? imageUrl;
                      String priceStr = '—';

                      if (item is Map<String, dynamic>) {
                        if (item['name'] != null) name = item['name'].toString();
                        else if (item['title'] != null) name = item['title'].toString();

                        if (item['image_url'] != null) imageUrl = item['image_url'].toString();

                        final rawPrice = item['price_cents'];
                        if (rawPrice != null) {
                          if (rawPrice is int) {
                            priceStr = (rawPrice / 100).toStringAsFixed(2);
                          } else if (rawPrice is double) {
                            // handle "2.43" coming as double meaning dollars
                            if (rawPrice >= 100) priceStr = (rawPrice / 100).toStringAsFixed(2);
                            else priceStr = rawPrice.toStringAsFixed(2);
                          } else if (rawPrice is String) {
                            final s = rawPrice;
                            if (s.contains('.')) {
                              final d = double.tryParse(s) ?? 0.0;
                              // if API returned dollars string "2.43" -> show 2.43
                              priceStr = d.toStringAsFixed(2);
                            } else {
                              final iVal = int.tryParse(s);
                              if (iVal != null) priceStr = (iVal / 100).toStringAsFixed(2);
                            }
                          }
                        }
                      } else {
                        // fallback when item isn't a map
                        name = item.toString();
                      }

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
                        trailing: IconButton(
                          icon: const Icon(Icons.add_shopping_cart),
                          onPressed: () {
                            // Example action — you can call add-to-cart logic here
                            Navigator.of(context).pop(); // close sheet after action
                            // optionally refresh lists
                            _loadProductsFromApi();
                            _loadProducts();
                          },
                        ),
                        onTap: () {
                          // Optionally show details or pre-fill add-product form
                        },
                      );
                    },
                  ),
                ),

                // bottom actions
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // open add product flow...
                        Navigator.of(context).pop();
                        // refresh after closing
                        _loadProductsFromApi();
                        _loadProducts();
                      },
                      child: const Text('Add New'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      // refresh main list after sheet closes
      _loadProductsFromApi();
      _loadProducts();
    });
  }

  Widget _buildProductRow(int index, ItemOwner itemOwner) {
    final item = itemOwner.item;
    final category = itemOwner.category;

    // defensive fetching of image field (try multiple possible names)
    String? imageUrl;
    try {
      final dynamic possible = item?.imageUrl;
      if (possible is String && possible.isNotEmpty) imageUrl = possible;
    } catch (_) {
      imageUrl = null;
    }

    // Price: try multiple fields and handle string/int
    double price = 0.0;
    try {
      final dynamic priceField = item?.priceCents;
      if (priceField != null) {
        if (priceField is num) {
          // if backend returns cents (e.g. 243) or dollars (2.43)
          price = (priceField >= 100) ? (priceField / 100.0) : priceField.toDouble();
        } else if (priceField is String) {
          final parsed = double.tryParse(priceField) ?? 0.0;
          price = (parsed >= 100) ? (parsed / 100.0) : parsed;
        }
      }
    } catch (_) {
      price = 0.0;
    }

    // NOTE: your backend mapping: inactive == 1 => ACTIVE, inactive == 0 => INACTIVE
    final int inactiveVal = itemOwner.inactive ?? 0;
    final bool isActive = (inactiveVal == 1); // switch ON when 1

    // content indent (to align with the leading number + image + gaps)
    final double contentIndent = 24 + 12 + 48 + 12;

    // SAFE: treat id as nullable
    final int? id = itemOwner.id;
    final bool isUpdating = id != null && _updatingIds.contains(id);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row...
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Image
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
                        child: const Icon(
                          Icons.broken_image,
                          size: 22,
                          color: Colors.grey,
                        ),
                      ),
                    )
                        : Container(
                      color: Colors.grey.shade300,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        size: 22,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item?.name?.toString() ?? 'Unnamed Item',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category?.name?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    // TODO: edit/delete actions
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
                Text('0', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Status row: show per-row loader if updating, else switch (disabled if id is null)
          Padding(
            padding: EdgeInsets.only(left: contentIndent, right: 16, bottom: 10),
            child: Row(
              children: [
                const Text('Status', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const Spacer(),
                if (isUpdating)
                  const SizedBox(
                    width: 36,
                    height: 24,
                    child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                else
                  Switch(
                    value: isActive,
                    activeThumbColor: Colors.white,
                    activeTrackColor: _accentColor,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade400,
                    onChanged: (id == null)
                        ? null // disable if no id available
                        : (newStatus) => _toggleStatus(itemOwner, newStatus),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Toggle status with optimistic update and per-row loader
  Future<void> _toggleStatus(ItemOwner itemOwner, bool newStatus) async {
    final int? id = itemOwner.id;
    if (id == null) {
      // Defensive: item has no id, cannot update backend
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot update: invalid item ID')));
      }
      return;
    }

    final oldValue = itemOwner.inactive ?? 0;

    // optimistic update and mark updating
    // newStatus == true -> ACTIVE -> inactive = 1
    // newStatus == false -> INACTIVE -> inactive = 0
    final newInactive = newStatus ? 1 : 0;

    setState(() {
      itemOwner.inactive = newInactive;
      _updatingIds.add(id);
    });

    try {
      await ItemOwnerService.updateStatus(
        id: id,
        inactive: itemOwner.inactive,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated')));
      }
    } catch (e) {
      // rollback
      if (mounted) {
        setState(() {
          itemOwner.inactive = oldValue;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingIds.remove(id);
        });
      }
    }
  }

  Widget _buildPagination(int totalItems, int totalPages) {
    final start = ((_currentPage - 1) * _rowsPerPage) + 1;
    final end = min(_currentPage * _rowsPerPage, totalItems);

    return Row(
      children: [
        const Text(
          'Rows per page',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87),
            borderRadius: BorderRadius.circular(2),
          ),
          child: DropdownButton<int>(
            value: _rowsPerPage,
            underline: const SizedBox(),
            iconSize: 18,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
            items: const [
              DropdownMenuItem(value: 5, child: Text('5')),
              DropdownMenuItem(value: 10, child: Text('10')),
              DropdownMenuItem(value: 20, child: Text('20')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _rowsPerPage = value;
                _currentPage = 1; // reset to first page on page size change
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Text(
          totalItems == 0 ? '0 of 0' : '$start–$end of $totalItems',
          style: const TextStyle(fontSize: 12),
        ),
        const Spacer(),
        IconButton(
          onPressed: _currentPage > 1
              ? () {
            setState(() {
              _currentPage = max(1, _currentPage - 1);
            });
          }
              : null,
          iconSize: 18,
          splashRadius: 18,
          icon: const Icon(Icons.chevron_left),
        ),
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            '$_currentPage',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: _currentPage < totalPages
              ? () {
            setState(() {
              _currentPage = min(totalPages, _currentPage + 1);
            });
          }
              : null,
          iconSize: 18,
          splashRadius: 18,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
