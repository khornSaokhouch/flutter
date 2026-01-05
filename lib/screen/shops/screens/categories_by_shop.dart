import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/global_notification_banner.dart';
import 'package:frontend/screen/shops/screens/products_by_category.dart';
import 'package:frontend/screen/shops/screens/shops_orders_page.dart';
import 'package:frontend/screen/shops/screens/shops_products_page.dart';
import 'package:frontend/screen/shops/screens/shops_profile_page.dart';
import 'package:frontend/screen/shops/screens/shops_promotions_screen.dart';
import 'package:frontend/screen/shops/widgets/shops_bottom_navigation.dart';
import '../../../models/shops_models/shop_categories_models.dart';
import '../../../server/shops_server/shop_category_server.dart';
import '../../../core/widgets/loading/logo_loading.dart';

import '../widgets/add_category_button.dart';
import '../widgets/category_row.dart';

class ShopsCategoriesPage extends StatefulWidget {
  final int shopId;

  const ShopsCategoriesPage({super.key, required this.shopId});

  @override
  State<ShopsCategoriesPage> createState() => _ShopsCategoriesPageState();
}

class _ShopsCategoriesPageState extends State<ShopsCategoriesPage> {
  final TextEditingController _searchController = TextEditingController();
  final CategoryShopController _categoryShopController = CategoryShopController();

  List<CategoryModel> _categories = [];
  List<CategoryModel> _displayedCategories = [];

  bool _isLoading = true;
  String? _error;
  bool _didShowAddSheetWhenEmpty = false;

  // Track multiple selections
  final Set<int> _selectedCategoryIds = {}; 
  List<CategoryModel> _availableCategoriesToAdd = [];
  List<CategoryModel> _filteredCategories = [];
  bool _isAddingCategory = false;

  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _loadCategories();
      await _loadAvailableCategories();
    } catch (e) {
      debugPrint('Init error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAvailableCategories() async {
    try {
      final allCategories = await _categoryShopController.fetchCategories();
      final existingIds = _categories.map((c) => c.id).toSet();
      final filtered = allCategories.where((c) => !existingIds.contains(c.id)).toList();

      if (!mounted) return;
      setState(() {
        _availableCategoriesToAdd = filtered;
        _filteredCategories = filtered;
      });
    } catch (e) {
      debugPrint('Error loading available categories: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final data = await _categoryShopController.fetchCategoriesByShop(widget.shopId);
      if (!mounted) return;
      setState(() {
        _categories = data;
        _displayedCategories = data;
        _error = null;
        if (_searchController.text.isNotEmpty) {
          _runFilter(_searchController.text);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  void _runFilter(String enteredKeyword) {
    List<CategoryModel> results = [];
    if (enteredKeyword.isEmpty) {
      results = _categories;
    } else {
      results = _categories
          .where((c) => c.name.toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() => _displayedCategories = results);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddCategorySheet() async {
    await _loadAvailableCategories();

    setState(() {
      _selectedCategoryIds.clear();
      _filteredCategories = List.from(_availableCategoriesToAdd);
    });

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return StatefulBuilder(builder: (context, modalSetState) {
                final isAllSelected = _selectedCategoryIds.length == _filteredCategories.length && _filteredCategories.isNotEmpty;

                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                      
                      // HEADER WITH SELECT ALL
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 12, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Add Categories", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _espressoBrown)),
                                  Text(
                                    _selectedCategoryIds.isEmpty 
                                      ? "Select to link to your shop" 
                                      : "${_selectedCategoryIds.length} categories selected",
                                    style: TextStyle(
                                      color: _selectedCategoryIds.isEmpty ? Colors.grey[500] : _freshMintGreen, 
                                      fontSize: 13,
                                      fontWeight: _selectedCategoryIds.isEmpty ? FontWeight.normal : FontWeight.bold
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_filteredCategories.isNotEmpty)
                              TextButton.icon(
                                onPressed: () {
                                  modalSetState(() {
                                    if (isAllSelected) {
                                      _selectedCategoryIds.clear();
                                    } else {
                                      for (var c in _filteredCategories) {
                                        _selectedCategoryIds.add(c.id);
                                      }
                                    }
                                  });
                                },
                                icon: Icon(isAllSelected ? Icons.deselect : Icons.select_all, size: 18, color: _freshMintGreen),
                                label: Text(isAllSelected ? "None" : "All", style: TextStyle(color: _freshMintGreen, fontWeight: FontWeight.bold)),
                              ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, color: Colors.black54),
                            )
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      
                      // SEARCH
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                            hintText: 'Search available categories...',
                            filled: true,
                            fillColor: _bgGrey,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                          onChanged: (q) {
                            modalSetState(() {
                              final query = q.trim().toLowerCase();
                              _filteredCategories = query.isEmpty
                                  ? List.from(_availableCategoriesToAdd)
                                  : _availableCategoriesToAdd.where((c) => c.name.toLowerCase().contains(query)).toList();
                            });
                          },
                        ),
                      ),

                      // LIST
                      Expanded(
                        child: _filteredCategories.isEmpty
                            ? Center(child: Text('No categories found.', style: TextStyle(color: Colors.grey[500])))
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                                itemCount: _filteredCategories.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (ctx, i) {
                                  final cat = _filteredCategories[i];
                                  final selected = _selectedCategoryIds.contains(cat.id);
                                  return InkWell(
                                    onTap: () {
                                      modalSetState(() {
                                        if (selected) _selectedCategoryIds.remove(cat.id);
                                        else _selectedCategoryIds.add(cat.id);
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: selected ? _freshMintGreen.withOpacity(0.05) : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: selected ? _freshMintGreen : Colors.grey.shade200, width: selected ? 1.5 : 1),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48, height: 48,
                                            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: cat.imageCategoryUrl.isNotEmpty
                                                  ? Image.network(cat.imageCategoryUrl, fit: BoxFit.cover)
                                                  : Icon(Icons.category, color: Colors.grey[400]),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(cat.name, style: TextStyle(fontSize: 15, fontWeight: selected ? FontWeight.bold : FontWeight.w500)),
                                          const Spacer(),
                                          Container(
                                            width: 24, height: 24,
                                            decoration: BoxDecoration(
                                              color: selected ? _freshMintGreen : Colors.white,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: selected ? _freshMintGreen : Colors.grey[300]!, width: 2),
                                            ),
                                            child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      // STICKY FOOTER
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(top: BorderSide(color: Colors.grey.shade100)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: (_selectedCategoryIds.isEmpty || _isAddingCategory)
                                ? null
                                : () async {
                                    modalSetState(() => _isAddingCategory = true);
                                    try {
                                      // Bulk Attach (Looping since attach API usually takes one ID)
                                      for (int catId in _selectedCategoryIds) {
                                        await _categoryShopController.attachCategoryToShop(
                                          shopId: widget.shopId,
                                          categoryId: catId,
                                        );
                                      }
                                      await _loadCategories();
                                      await _loadAvailableCategories();
                                      if (!mounted) return;
                                      Navigator.pop(context);
                                     
                                    } finally {
                                      if (mounted) modalSetState(() => _isAddingCategory = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:_freshMintGreen,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _isAddingCategory
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(
                                    _selectedCategoryIds.isEmpty ? "Select Categories" : "Confirm ${_selectedCategoryIds.length} Selections",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoriesView() {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bgGrey,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LogoLoading(),
              const SizedBox(height: 16),
              Text('Loading categories...', style: TextStyle(color: _freshMintGreen, fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: _bgGrey,
        appBar: _buildAppBar(),
        body: Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red))),
      );
    }

    if (_categories.isEmpty) {
      if (!_didShowAddSheetWhenEmpty) {
        _didShowAddSheetWhenEmpty = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showAddCategorySheet();
        });
      }
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              color: _bgGrey,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search attached categories...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (val) => _runFilter(val),
                  ),
                  const SizedBox(height: 12),
                  AddCategoryButton(isOpen: false, onToggle: _showAddCategorySheet, accentColor: _freshMintGreen),
                ],
              ),
            ),
            Expanded(
              child: _displayedCategories.isEmpty
                  ? Center(child: Text("No matches found", style: TextStyle(color: Colors.grey[600])))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _displayedCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 0),
                      itemBuilder: (context, index) {
                        final item = _displayedCategories[index];
                        return CategoryRow(
                          index: index,
                          item: item,
                          accentColor: _freshMintGreen,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GlobalNotificationBanner(
                                  child: CategoryProductsPage(categoryId: item.id, categoryName: item.name, shopId: widget.shopId),
                                ),
                              ),
                            );
                          },
                          onStatusChanged: (categoryId, newStatus) async {
                            await _categoryShopController.updateCategoryStatusForShop(shopId: widget.shopId, categoryId: categoryId, status: newStatus);
                            if (!mounted) return;
                            setState(() {
                              final updatedPivot = (item.pivot ?? PivotModel(shopId: widget.shopId, categoryId: item.id, status: newStatus ? 1 : 0, createdAt: item.createdAt, updatedAt: item.updatedAt)).copyWith(status: newStatus ? 1 : 0);
                              final updatedItem = item.copyWith(pivot: updatedPivot);
                              _displayedCategories[index] = updatedItem;
                              final masterIndex = _categories.indexWhere((c) => c.id == categoryId);
                              if (masterIndex != -1) _categories[masterIndex] = updatedItem;
                            });
                          },
                          onMenuSelected: (action) {},
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShopsBottomNavigation(
      initialIndex: 0,
      pages: [
        _buildCategoriesView(),
        ShopsOrdersPage(shopId: widget.shopId),
        PromotionsScreen(shopId: widget.shopId),
        ShopsProductsPage(shopId: widget.shopId),
        ShopsProfilePage(shopId: widget.shopId),
      ],
      accentColor: _freshMintGreen,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black), onPressed: () => Navigator.pop(context)),
      title: Text('SHOP CATEGORIES', style: TextStyle(color: _espressoBrown, fontWeight: FontWeight.w800, letterSpacing: 1.0, fontSize: 16)),
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey[200], height: 1)),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: _buildAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)]),
              child: Icon(Icons.category_outlined, size: 60, color: Colors.grey[300]),
            ),
            const SizedBox(height: 24),
            Text("No Categories Found", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _espressoBrown)),
            const SizedBox(height: 8),
            Text("Start by adding a category to this shop.", style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            SizedBox(width: 200, child: AddCategoryButton(isOpen: false, onToggle: _showAddCategorySheet, accentColor: _freshMintGreen)),
          ],
        ),
      ),
    );
  }
}