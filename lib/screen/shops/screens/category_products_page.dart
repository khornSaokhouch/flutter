// file: category_products_page.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frontend/screen/shops/screens/shop_product_detai.dart';
import 'package:frontend/screen/shops/screens/shops_orders_page.dart';
import 'package:frontend/screen/shops/screens/shops_products_page.dart';
import 'package:frontend/screen/shops/screens/shops_profile_page.dart';

import '../../../models/shops_models/shop_item_owner_models.dart';
import '../../../server/shops_server/item_owner_service.dart';
import '../widgets/add_product_sheet.dart';
import '../widgets/product_row.dart';
import '../widgets/shops_bottom_navigation.dart';

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

  List<ItemOwner> _products = [];
  List<Map<String, dynamic>> _itemsRaw = [];

  Timer? _searchDebounce;
  final Set<int> _updatingIds = {};

  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _currentPage = 1;
      });
    });
  }

  Future<void> _loadProductsFromApi() async {
    try {
      if (mounted) setState(() { _isLoading = true; _error = null; });
      final itemOwners = await ItemOwnerService.fetchItemsByShopAndCategory(
        shopId: widget.shopId,
        categoryId: widget.categoryId,
      );
      if (mounted) setState(() { _products = itemOwners; _isLoading = false; _currentPage = 1; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Set<int> _existingItemIds() {
    final Set<int> ids = {};
    for (final owner in _products) {
      if (owner.item?.id != null) ids.add(owner.item!.id);
    }
    return ids;
  }

  Future<void> _loadProducts() async {
    setState(() => _error = null);
    try {
      final results = await ItemOwnerService.fetchItemsByCategory(widget.categoryId);
      final List<Map<String, dynamic>> normalized = [];

      if (results is List<Map<String, dynamic>>) {
        normalized.addAll(results as Iterable<Map<String, dynamic>>);
      } else if (results is List) {
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
      }

      final existingIds = _existingItemIds();
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

        if (id != null && existingIds.contains(id)) continue;
        filtered.add(map);
      }

      if (mounted) setState(() => _itemsRaw = filtered);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

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
      return itemName.contains(q) || categoryName.contains(q);
    }).toList();
  }

  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddProductSheet(
        initialItems: _itemsRaw,
        shopId: widget.shopId,
        categoryId: widget.categoryId,
        categoryName: widget.categoryName,
        onRefreshRequested: () async {
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
          _loadProductsFromApi();
          _loadProducts();
        },
      ),
    ).whenComplete(() {
      _loadProductsFromApi();
      _loadProducts();
    });
  }

  Widget _buildMainView() {
    final query = _searchController.text.trim();
    final filtered = _applySearchFilter(query);

    final total = filtered.length;
    final totalPages = max(1, (total / _rowsPerPage).ceil());
    if (_currentPage > totalPages) _currentPage = totalPages;

    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = min(startIndex + _rowsPerPage, total);
    final productsPage = (startIndex < endIndex) ? filtered.sublist(startIndex, endIndex) : [];

    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName.toUpperCase(),
          style: TextStyle(
            color: _espressoBrown,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _freshMintGreen))
            : _error != null
            ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
            : RefreshIndicator(
          onRefresh: _refresh,
          color: _freshMintGreen,
          child: CustomScrollView(
            slivers: [
              // 1. Search & Actions Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: _bgGrey,
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showAddProductSheet(context),
                              icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                              label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _freshMintGreen,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Product List
              if (productsPage.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text("No Products Found", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final itemOwner = productsPage[index];
                        final globalIndex = startIndex + index;

                        // Using the Redesigned ProductRow
                        return ProductRow(
                          index: globalIndex,
                          itemOwner: itemOwner,
                          accentColor: _freshMintGreen,
                          shopId: widget.shopId,
                          onTap: (owner) {
                            if (owner.item != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ShopProductDetailPage(
                                    itemId: itemOwner.item!.id,
                                    shopId: widget.shopId,
                                  ),
                                ),
                              );
                            }
                          },
                          onToggleStatus: (owner, newStatus) async {
                            final int? id = owner.id;
                            if (id == null) return;

                            final oldValue = owner.inactive;
                            final newInactive = newStatus ? 1 : 0;

                            setState(() {
                              owner.inactive = newInactive;
                              _updatingIds.add(id);
                            });

                            try {
                              await ItemOwnerService.updateStatus(id: id, inactive: owner.inactive);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(newStatus ? 'Product Activated' : 'Product Deactivated'), backgroundColor: _freshMintGreen),
                                );
                              }
                            } catch (e) {
                              if (mounted) setState(() => owner.inactive = oldValue);
                            } finally {
                              if (mounted) setState(() => _updatingIds.remove(id));
                            }
                          },
                        );
                      },
                      childCount: productsPage.length,
                    ),
                  ),
                ),

              // 3. Footer Spacer & Pagination
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildPagination(total, totalPages),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Return ShopsBottomNavigation with the main category products view as the first tab
    return ShopsBottomNavigation(
      initialIndex: 0,
      pages: [
        _buildMainView(),


        // Orders page (uses your existing ShopsOrdersPage widget)
        ShopsOrdersPage(),

        // Products page (uses your existing ShopsProductsPage widget)
        ShopsProductsPage(),

        // Profile page (uses your existing ShopsProfilePage widget)
        ShopsProfilePage(),
      ],
      accentColor: _freshMintGreen,
    );
  }

  Widget _buildPagination(int totalItems, int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Page $_currentPage of $totalPages", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
              ),
            ],
          )
        ],
      ),
    );
  }
}
