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
  final CategoryShopController _categoryShopController = CategoryShopController();

  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;

  bool _didShowAddSheetWhenEmpty = false;


  // modal sheet state
  int? _selectedCategoryToAdd;
  List<CategoryModel> _availableCategoriesToAdd = [];
  List<CategoryModel> _filteredCategories = [];
  bool _isAddingCategory = false;

  int _rowsPerPage = 10;
  Color get _accentColor => const Color(0xFFB2865B);

  @override
  void initState() {
    super.initState();
    _initData();
  }

  /// Load lists only (do NOT attach anything here)
  Future<void> _initData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _loadCategories();
      await _loadAvailableCategories();
    } catch (e) {
      // _loadCategories/_loadAvailableCategories already set state on error;
      debugPrint('Init error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAvailableCategories() async {
    try {
      // 1. get ALL categories from API
      final allCategories = await _categoryShopController.fetchCategories();

      // 2. build a set of category IDs already attached to this shop
      final existingIds = _categories.map((c) => c.id).toSet();

      // 3. keep only categories that are NOT in this shop
      final filtered = allCategories.where((c) => !existingIds.contains(c.id)).toList();

      if (!mounted) return;
      setState(() {
        _availableCategoriesToAdd = filtered;
        _filteredCategories = filtered;
      });
    } catch (e) {
      debugPrint('Error loading available categories: $e');
      // don't override main error state here - show toast or ignore
    }
  }

  Future<void> _loadCategories() async {
    try {
      final data = await _categoryShopController.fetchCategoriesByShop(widget.shopId);
      if (!mounted) return;
      setState(() {
        _categories = data;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Convenience: show modal bottom sheet to add category
// Replace your existing _showAddCategorySheet with this version:
  Future<void> _showAddCategorySheet() async {
    // ensure we have latest available categories
    await _loadAvailableCategories();

    // reset selection/filter when opening
    setState(() {
      _selectedCategoryToAdd = null;
      _filteredCategories = List.from(_availableCategoriesToAdd);
    });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Wrap in Padding to allow keyboard to push sheet up
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              // <-- IMPORTANT: use StatefulBuilder so the sheet can update itself
              return StatefulBuilder(builder: (context, modalSetState) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Add category to shop', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Search input (use modalSetState to update the sheet UI)
                      TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search categories...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (q) {
                          modalSetState(() {
                            final query = q.trim().toLowerCase();
                            _filteredCategories = query.isEmpty
                                ? List.from(_availableCategoriesToAdd)
                                : _availableCategoriesToAdd.where((c) => c.name.toLowerCase().contains(query)).toList();

                            // clear selection if it's not in filtered
                            if (_selectedCategoryToAdd != null &&
                                !_filteredCategories.any((c) => c.id == _selectedCategoryToAdd)) {
                              _selectedCategoryToAdd = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Body: list or message
                      Expanded(
                        child: _filteredCategories.isEmpty
                            ? const Center(child: Text('No categories available to add.'))
                            : ListView.separated(
                          controller: scrollController,
                          itemCount: _filteredCategories.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (ctx, i) {
                            final cat = _filteredCategories[i];
                            final selected = _selectedCategoryToAdd == cat.id;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: selected ? _accentColor.withOpacity(0.12) : Colors.transparent,
                                border: Border.all(
                                  color: selected ? _accentColor : Colors.transparent,
                                  width: selected ? 1.5 : 0,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                selected: selected,
                                onTap: () {
                                  // Use modalSetState so the sheet updates immediately,
                                  // also update parent state so Add button works.
                                  modalSetState(() {
                                    _selectedCategoryToAdd = cat.id;
                                  });
                                  // also call parent setState if you need to update outer UI
                                  // setState(() {});
                                },
                                leading: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: cat.imageCategoryUrl.isNotEmpty
                                        ? Image.network(
                                      cat.imageCategoryUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    )
                                        : Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image_not_supported_outlined),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  cat.name,
                                  style: TextStyle(
                                    color: selected ? _accentColor : Colors.black87,
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                                trailing: selected
                                    ? Row(mainAxisSize: MainAxisSize.min, children: const [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                ])
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Footer: Add button
                      Row(
                        children: [
                          Text(
                            '${_filteredCategories.length} item${_filteredCategories.length == 1 ? '' : 's'}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: (_selectedCategoryToAdd == null || _isAddingCategory)
                                ? null
                                : () async {
                              // inside sheet we still want to show loading on sheet UI
                              modalSetState(() {
                                _isAddingCategory = true;
                              });

                              try {
                                await _categoryShopController.attachCategoryToShop(
                                  shopId: widget.shopId,
                                  categoryId: _selectedCategoryToAdd!,
                                );

                                // refresh parent lists after success
                                await _loadCategories();
                                await _loadAvailableCategories();

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Category added successfully')),
                                );

                                Navigator.of(context).pop(); // close sheet
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error adding category: $e')),
                                );
                              } finally {
                                if (mounted) {
                                  modalSetState(() {
                                    _isAddingCategory = false;
                                  });
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: _accentColor, elevation: 0),
                            child: _isAddingCategory
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Add'),
                          ),
                        ],
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

    // After sheet closes ensure available categories refreshed
    await _loadAvailableCategories();
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
                    activeThumbColor: Colors.white,
                    activeTrackColor: _accentColor,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade400,
                    onChanged: (val) async {
                      final newStatus = val;
                      try {
                        await _categoryShopController.updateCategoryStatusForShop(
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

                          _categories[index] = item.copyWith(pivot: updatedPivot);
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
            padding: const EdgeInsets.only(left: 52 + 48 + 12, right: 16),
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
            style: const TextStyle(fontSize: 12, color: Colors.black),
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
        Text('1–$total of $total', style: const TextStyle(fontSize: 12)),
        const Spacer(),
        IconButton(onPressed: () {}, iconSize: 18, splashRadius: 18, icon: const Icon(Icons.chevron_left)),
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
          child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        IconButton(onPressed: () {}, iconSize: 18, splashRadius: 18, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

    // If there are no categories show a friendly screen and auto-open the add sheet once.
    if (_categories.isEmpty) {
      if (!_didShowAddSheetWhenEmpty && !_isLoading && _error == null) {
        _didShowAddSheetWhenEmpty = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showAddCategorySheet();
        });
      }

      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F3EE),
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: const Text(
            'Product Categories',
            style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Center(
                    child: Text(
                      'No categories found',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  'Tap the button below to add categories to this shop.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAddCategorySheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    }

    // --- Non-empty categories: render the full page ---
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EE),
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Product Categories', style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Home  /  Products  /  Categories', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),

            // Search
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4)), borderSide: BorderSide(color: Colors.black54, width: 1)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  // implement local filtering if needed
                });
              },
            ),
            const SizedBox(height: 16),

            // Add new category button (opens sheet)
            Column(children: [
              const SizedBox(height: 12),
              AddCategoryButton(
                isOpen: false,
                onToggle: _showAddCategorySheet, // open modal bottom sheet
                accentColor: _accentColor,
              ),
            ]),
            const SizedBox(height: 12),
            const Divider(height: 32),

            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(children: [
                SizedBox(width: 40, child: Text('No', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                SizedBox(width: 12),
                SizedBox(width: 48, child: Text('Img', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                SizedBox(width: 12),
                Expanded(child: Text('Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                SizedBox(width: 80, child: Text('')),
                SizedBox(width: 24),
              ]),
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
          ]),
        ),
      ),
    );
  }
}
