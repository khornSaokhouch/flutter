// file: shops_categories_page.dart
import 'package:flutter/material.dart';
import 'package:frontend/screen/shops/screens/category_products_page.dart';

import '../../../models/shops_models/shop_categories_models.dart';
import '../../../server/shops_server/shop_category_server.dart';
import '../widgets/add_category_button.dart';

class ShopsCategoriesPage extends StatefulWidget {
  final int shopId;

  const ShopsCategoriesPage({super.key, required this.shopId});

  @override
  State<ShopsCategoriesPage> createState() => _ShopsCategoriesPageState();
}

class _ShopsCategoriesPageState extends State<ShopsCategoriesPage> {
  final TextEditingController _searchController = TextEditingController();
  final CategoryShopController _categoryShopController =
  CategoryShopController();

  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;

  // for add-category panel
  bool _showAddCategoryPanel = false;
  int? _selectedCategoryToAdd;

  // categories that can be attached to shop
  List<CategoryModel> _availableCategoriesToAdd = [];

  int _rowsPerPage = 10;
  Color get _accentColor => const Color(0xFFB2865B);

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      await _loadCategories(); // fills _categories
      await _loadAvailableCategories(); // filters using _categories
      await _categoryShopController.attachCategoryToShop(
        shopId: widget.shopId,
        categoryId: _selectedCategoryToAdd!,
      );
    } catch (_) {
      // _loadCategories already sets _error / _isLoading
    }
  }

  Future<void> _loadAvailableCategories() async {
    try {
      // 1. get ALL categories from API
      final allCategories = await _categoryShopController.fetchCategories();

      // 2. build a set of category IDs already attached to this shop
      final existingIds = _categories.map((c) => c.id).toSet();

      // 3. keep only categories that are NOT in this shop
      final filtered =
      allCategories.where((c) => !existingIds.contains(c.id)).toList();

      if (!mounted) return;
      setState(() {
        _availableCategoriesToAdd = filtered;
      });
    } catch (e) {
      debugPrint('Error loading available categories: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final data =
      await _categoryShopController.fetchCategoriesByShop(widget.shopId);
      if (!mounted) return;
      setState(() {
        _categories = data;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F3EE),
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: const Text(
            'Product Categories',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: const Center(child: Text('No categories found')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EE),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Product Categories',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Home  /  Products  /  Categories',
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
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(color: Colors.black54, width: 1),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    // implement local filtering if needed
                  });
                },
              ),
              const SizedBox(height: 16),

              // Add new category button
              Column(
                children: [
                  const SizedBox(height: 12),
                  AddCategoryButton(
                    isOpen: _showAddCategoryPanel,
                    onToggle: () {
                      setState(() {
                        _showAddCategoryPanel = !_showAddCategoryPanel;
                      });
                    },
                    accentColor: _accentColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_showAddCategoryPanel) _buildAddCategoryPanel(),
              const SizedBox(height: 12),
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
                    SizedBox(
                      width: 48,
                      child: Text(
                        'Img',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Name',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    SizedBox(width: 80, child: Text('')),
                    SizedBox(width: 24),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),

              // List from local _categories
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const Divider(height: 32),
                itemBuilder: (context, index) {
                  final item = _categories[index];
                  return _buildCategoryRowFromModel(index, item);
                },
              ),

              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _buildPagination(_categories.length),
            ],
          ),
        ),
      ),
    );
  }

  /// Panel that appears below "Add New Category" button
  Widget _buildAddCategoryPanel() {
    final hasOptions = _availableCategoriesToAdd.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select category to add',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          if (!hasOptions)
            const Text(
              'No categories available to add.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            )
          else
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              value: _selectedCategoryToAdd,
              items: _availableCategoriesToAdd
                  .map(
                    (c) => DropdownMenuItem<int>(
                  value: c.id,
                  child: Text(c.name),
                ),
              )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryToAdd = value;
                });
              },
            ),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: !hasOptions
                  ? null
                  : () async {
                if (_selectedCategoryToAdd == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select a category')),
                  );
                  return;
                }

                try {
                  await _categoryShopController.attachCategoryToShop(
                    shopId: widget.shopId,
                    categoryId: _selectedCategoryToAdd!,
                  );

                  // Reload both attached + available categories
                  await _loadCategories();
                  await _loadAvailableCategories();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category added successfully'),
                    ),
                  );

                  setState(() {
                    _showAddCategoryPanel = false;
                    _selectedCategoryToAdd = null;
                  });
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                        Text('Error adding category: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text(
                'Add',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRowFromModel(int index, CategoryModel item) {
    final isOn = item.status == 1 && ((item.pivot?.status ?? 1) == 1);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryProductsPage(
              categoryId: item.id,
              categoryName: item.name,
              shopId: widget.shopId,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: item.imageCategoryUrl.isNotEmpty
                        ? Image.network(
                      item.imageCategoryUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    )
                        : Container(
                      color: Colors.grey.shade300,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Switch(
                    value: isOn,
                    activeColor: Colors.white,
                    activeTrackColor: _accentColor,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade400,
                    onChanged: (val) async {
                      final newStatus = val;

                      try {
                        await _categoryShopController
                            .updateCategoryStatusForShop(
                          shopId: widget.shopId,
                          categoryId: item.id,
                          status: newStatus,
                        );

                        if (!mounted) return;
                        setState(() {
                          final updatedPivot = (item.pivot ??
                              PivotModel(
                                shopId: widget.shopId,
                                categoryId: item.id,
                                status: newStatus ? 1 : 0,
                                createdAt: item.createdAt,
                                updatedAt: item.updatedAt,
                              ))
                              .copyWith(status: newStatus ? 1 : 0);

                          _categories[index] =
                              item.copyWith(pivot: updatedPivot);
                        });
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update status: $e'),
                          ),
                        );
                      }
                    },
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding:
            const EdgeInsets.only(left: 52 + 48 + 12, right: 16),
            child: Row(
              children: [
                const Text(
                  'Variant Price',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Additional Price',
                  style: TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
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
            style:
            const TextStyle(fontSize: 12, color: Colors.black),
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
          onPressed: () {},
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
          onPressed: () {},
          iconSize: 18,
          splashRadius: 18,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
