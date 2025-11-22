// file: category_products_page.dart
import 'package:flutter/material.dart';

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

  /// All products (ItemOwner records) loaded from the API
  List<ItemOwner> _products = [];

  Color get _accentColor => const Color(0xFFB2865B); // coffee brown

  @override
  void initState() {
    super.initState();
    _loadProductsFromApi();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProductsFromApi() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final itemOwners =
      await ItemOwnerService.fetchItemsByShopAndCategory(
        shopId: widget.shopId,
        categoryId: widget.categoryId,
      );

      setState(() {
        _products = itemOwners;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simple search filtering by item name or category name
    final query = _searchController.text.trim().toLowerCase();
    final products = query.isEmpty
        ? _products
        : _products.where((p) {
      final itemName = p.item.name.toString().toLowerCase();
      final categoryName = p.category.name.toString().toLowerCase();
      return itemName.contains(query) || categoryName.contains(query);
    }).toList();

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
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
          ),
        )
            : products.isEmpty
            ? const Center(
          child: Text('No products in this category yet'),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
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
                onChanged: (_) => setState(() {}),
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
                        // TODO: open "add product" dialog/screen
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
                physics:
                const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: products.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 32),
                itemBuilder: (context, index) {
                  final itemOwner = products[index];
                  return _buildProductRow(index, itemOwner);
                },
              ),

              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _buildPagination(products.length),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductRow(int index, ItemOwner itemOwner) {
    final item = itemOwner.item;
    final category = itemOwner.category;

    // Adjust these field names to match your Item model if needed:
    final String? imageUrl = item.imageUrl; // e.g. imageUrl / image / image_url
    final double priceCents =
        double.tryParse(item.priceCents.toString()) ?? 0.0;
    final double price = priceCents / 100;

    // If your Item model uses something else for stock, adjust here
    // final int stock = (item.stock as int?) ?? 0;

    final bool isActive = itemOwner.inactive == 1;
    // final bool hasStockWarning = stock <= 5;

    final double contentIndent =
        40 + 12 + 40 + 12; // No + gap + image + gap

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== TOP ROW: No + image + name + type + menu =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // No
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
                    child: imageUrl != null &&
                        imageUrl.startsWith('http')
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
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

                // Name + type (category)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.name.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // More menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    // TODO: edit/delete actions
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider between header and details
          Divider(height: 1, color: Colors.grey.shade300),

          const SizedBox(height: 8),

          // ===== PRICE =====
          Padding(
            padding: EdgeInsets.only(left: contentIndent, right: 16),
            child: Row(
              children: [
                const Text(
                  'Price',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ===== STOCK =====
          Padding(
            padding: EdgeInsets.only(left: contentIndent, right: 16),
            child: Row(
              children: const [
                Text(
                  'Stock',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Spacer(),
                Text(
                  '0', // TODO: replace with real stock when you have the field
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ===== STATUS =====
          Padding(
            padding: EdgeInsets.only(
              left: contentIndent,
              right: 16,
              bottom: 10,
            ),
            child: Row(
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: isActive,
                  activeColor: Colors.white,
                  activeTrackColor: _accentColor,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade400,
                  onChanged: (newStatus) async {
                    // newStatus: true = ON, false = OFF
                    final oldValue = itemOwner.inactive;

                    // Optimistic UI update
                    setState(() {
                      itemOwner.inactive = newStatus ? 1 : 0;
                    });

                    try {
                      await ItemOwnerService.updateStatus(
                        id: itemOwner.id,
                        inactive: newStatus ? 1 : 0,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Status updated')),
                      );
                    } catch (e) {
                      // Rollback on failure
                      setState(() {
                        itemOwner.inactive = oldValue;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update status: $e')),
                      );
                    }
                  },
                )

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int total) {
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
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '1–$total of $total',
          style: const TextStyle(fontSize: 12),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            // TODO: previous page
          },
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
          child: const Text(
            '1',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            // TODO: next page
          },
          iconSize: 18,
          splashRadius: 18,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
