// file: category_products_page.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frontend/screen/shops/screens/shop_product_detai.dart';

import '../../../models/shops_models/shop_item_owner_models.dart';
import '../../../server/shops_server/item_owner_service.dart';
import '../widgets/add_product_sheet.dart';
import '../widgets/product_row.dart';

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

  Color get _accentColor => const Color(0xFFB2865B);



// coffee brown

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
          _products = itemOwners;
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

      // Normalize results into List<Map<String,dynamic>>
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
            try {
              final jsonMap = (r as dynamic).toJson();
              if (jsonMap is Map<String, dynamic>) normalized.add(jsonMap);
            } catch (_) {
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
        int? id;
        if (map['id'] is int) id = map['id'] as int;
        else if (map['id'] is String) id = int.tryParse(map['id'] as String);
        else if (map['item'] is Map) {
          final im = map['item'] as Map;
          if (im['id'] is int) id = im['id'] as int;
          else if (im['id'] is String) id = int.tryParse(im['id'] as String);
        }

        if (id != null && existingIds.contains(id)) {
          continue;
        }

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
      final itemName = (p.item?.name ?? '').toString().toLowerCase();
      final categoryName = (p.category?.name ?? '').toString().toLowerCase();
      final shopName = (p.shop?.name ?? '').toString().toLowerCase();
      return itemName.contains(q) || categoryName.contains(q) || shopName.contains(q);
    }).toList();
  }

  /// Show AddProductSheet bottom sheet
  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddProductSheet(
        initialItems: _itemsRaw,
        shopId: widget.shopId,
        categoryId: widget.categoryId,
        categoryName: widget.categoryName,
        onRefreshRequested: () async {
          // delegate reloading back to your service and normalize to List<Map<String,dynamic>>
          final results = await ItemOwnerService.fetchItemsByCategory(widget.categoryId);
          final normalized = <Map<String, dynamic>>[];
          for (final r in results) {
            if (r is Map<String, dynamic>) normalized.add(r as Map<String, dynamic>);
            else if (r is Map) normalized.add(Map<String, dynamic>.from(r as Map));
            else {
              try {
                final jsonMap = (r as dynamic).toJson();
                if (jsonMap is Map<String, dynamic>) normalized.add(jsonMap);
              } catch (_) {
                normalized.add({'value': r.toString()});
              }
            }
          }
          return normalized;
        },
        onCreated: (created) {
          // refresh your page lists after successful create
          _loadProductsFromApi();
          _loadProducts();
        },
      ),
    ).whenComplete(() {
      // ensure lists refresh after sheet closes
      _loadProductsFromApi();
      _loadProducts();
    });
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
                const Text(
                  'Home  /  Products  /  Product List',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
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
                          _showAddProductSheet(context); // show sheet
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
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: productsPage.length,
                  separatorBuilder: (_, __) => const Divider(height: 32),
                  itemBuilder: (context, index) {
                    final globalIndex = startIndex + index;
                    final itemOwner = productsPage[index];

                    return ProductRow(
                      index: globalIndex,
                      itemOwner: itemOwner,
                      accentColor: _accentColor,
                      shopId: widget.shopId,

                      // Optional: override tap to open detail page (original behavior)
                      onTap: (owner) {
                        if (owner.item != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ShopProductDetailPage(itemId: itemOwner.item!.id, shopId:widget.shopId )),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item details unavailable')));
                        }
                      },

                      // Toggle callback: performs API update + optimistic UI update in parent
                      onToggleStatus: (owner, newStatus) async {
                        final int? id = owner.id;
                        if (id == null) throw Exception('Invalid item owner id');

                        // local optimistic change (parent page also had _updatingIds set)
                        final oldValue = owner.inactive;
                        final newInactive = newStatus ? 1 : 0;

                        // mark updating in parent page state to keep any parent indicators in sync
                        setState(() {
                          owner.inactive = newInactive;
                          _updatingIds.add(id);
                        });

                        try {
                          await ItemOwnerService.updateStatus(id: id, inactive: owner.inactive);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated')));
                        } catch (e) {
                          // rollback
                          if (mounted) {
                            setState(() {
                              owner.inactive = oldValue;
                            });
                            rethrow; // ProductRow will show snackbar from caught exception
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _updatingIds.remove(id);
                            });
                          }
                        }
                      },
                    );
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
