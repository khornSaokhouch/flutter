import 'package:flutter/material.dart';
import 'package:frontend/screen/user/store_screen/search_page_screen.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/utils/auth_utils.dart';
import '../../../core/widgets/store/menu_item_card.dart';
import '../../../core/widgets/store/pickup_delivery_toggle.dart';
import '../../../models/item_model.dart';
import '../../../models/menu_item.dart';
import '../../../models/shop.dart';
import '../../../routes/footer_nav_routes.dart';
import '../../../server/item_service.dart';
import '../../../server/shop_service.dart';
import '../layout.dart';
import 'select_store_page.dart';

class MenuScreen extends StatefulWidget {
  final int userId;
  final int shopId;

  const MenuScreen({super.key, required this.userId, required this.shopId});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // --- nav / selection
  final int _selectedIndex = 2;
  String? _selectedCategoryId;

  // --- toggle / loading / data
  bool isPickupSelected = true;
  bool loading = true;
  Shop? shop;

  // --- scroll / category keys
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};

  List<Category> categories = [];
  List<ShopItem> shopItems = [];

  // --- store selector
  List<Shop> _stores = [];
  Position? _currentPosition;

  // --- Guest UI palette (to match GuestMenuScreen)
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _sidebarBg = const Color(0xFFF7F7F7);

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await AuthUtils.checkAuthAndGetUser(
      context: context,
      userId: widget.userId,
    );
    // If auth passes (or even if null) we still load shop data so UI shows
    await loadShop();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load shop info + items from API
  Future<void> loadShop() async {
    setState(() => loading = true);

    try {
      final fetchedShop = await ShopService.fetchShopById(widget.shopId);
      final fetchedItems =
      await ItemService.fetchItemsByShopCheckToken(widget.shopId);

      if (fetchedItems != null) {
        shopItems = fetchedItems.data;

        // Extract unique categories
        final catMap = <int, Category>{};
        for (var sItem in shopItems) {
          catMap[sItem.category.id] = sItem.category;
        }
        categories = catMap.values.toList();

        // Initialize keys
        _categoryKeys.clear();
        for (var cat in categories) {
          _categoryKeys[cat.id.toString()] = GlobalKey();
        }

        _selectedCategoryId =
        categories.isNotEmpty ? categories.first.id.toString() : null;
      }

      setState(() {
        shop = fetchedShop;
        loading = false;
      });
    } catch (e, st) {
      debugPrint('Error loading shop: $e\n$st');
      setState(() => loading = false);
    }
  }

  /// Called when user taps the store name/arrow in the header
  Future<void> _handleSelectStoreTap(BuildContext context) async {
    try {
      // 1) Fetch all stores if not already loaded
      if (_stores.isEmpty) {
        final response = await ShopService.fetchShops();
        _stores = response?.data ?? <Shop>[];
      }

      if (_stores.isEmpty) return;

      // 2) Try to get current position (optional)
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          _currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
        }
      } catch (_) {
        // ignore location errors
      }

      if (!mounted) return;

      // 3) Open bottom sheet with stores
      _openSelectStoreSheet(context, _stores);
    } catch (e) {
      debugPrint('Error preparing stores for select sheet: $e');
    }
  }

  /// Bottom sheet — same behavior as Guest
  void _openSelectStoreSheet(BuildContext context, List<Shop> stores) {
    if (stores.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.6,
        maxChildSize: 1.0,
        builder: (_, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.9,
              child: SelectStorePage(
                userId: widget.userId,
                stores: stores,
                userPosition: _currentPosition,
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      // refresh state if desired when sheet closes
      if (!mounted) return;
      setState(() {});
    });
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Layout(userId: widget.userId, selectedIndex: index),
      ),
    );
  }

  /// Group shop items by category name
  Map<String, List<ShopItem>> _groupMenuItems() {
    final Map<String, List<ShopItem>> grouped = {};
    for (var cat in categories) {
      final items = shopItems
          .where((i) => i.category.id.toString() == cat.id.toString())
          .toList();
      if (items.isNotEmpty) grouped[cat.name] = items;
    }
    return grouped;
  }

  void _scrollToCategory(String categoryId) {
    final key = _categoryKeys[categoryId];
    if (key != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupMenuItems();
    Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MENU',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
         actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchPage(shopId:widget.shopId, userId: widget.userId), // 👉 your next page
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[100], height: 1),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: _freshMintGreen))
          : Column(
        children: [
          // ===========================================
          // 1. Store Selection & Toggle Bar (Guest style)
          // ===========================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Store Selector
                InkWell(
                  onTap: () => _handleSelectStoreTap(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06), // Soft shadow
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.storefront_rounded, color: _freshMintGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          shop?.name ?? 'Select Store',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _espressoBrown,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, color: _espressoBrown, size: 18),
                      ],
                    ),
                  ),
                ),

                // Toggle
                PickupDeliveryToggle(
                  isPickupSelected: isPickupSelected,
                  onToggle: (val) => setState(() => isPickupSelected = val),
                ),
              ],
            ),
          ),

          // ===========================================
          // 2. Menu Content (Split View like Guest)
          // ===========================================
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Left Sidebar (Categories) ---
                Container(
                  width: 90,
                  color: _sidebarBg,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = _selectedCategoryId == cat.id.toString();

                      return _buildSideCategoryItem(cat, isSelected);
                    },
                  ),
                ),

                // --- Right: Items content ---
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: loadShop,
                    color: _freshMintGreen,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 80),
                      child: Column(
                        children: groupedItems.entries.map((entry) {
                          final categoryForSection =
                          categories.firstWhere((c) => c.name == entry.key);
                          final String categoryId = categoryForSection.id.toString();

                          return Container(
                            key: _categoryKeys[categoryId],
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section Header
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                                  color: Colors.white,
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: _espressoBrown,
                                    ),
                                  ),
                                ),

                                // Items List
                                ...entry.value.map(
                                      (shopItem) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                    child: MenuItemCard(
                                      item: MenuItem(
                                        id: shopItem.item.id.toString(),
                                        categoryId: shopItem.category.id.toString(),
                                        name: shopItem.item.name,
                                        price:
                                        '\$${(shopItem.item.priceCents / 100).toStringAsFixed(2)}',
                                        imageUrl: shopItem.item.imageUrl,
                                      ),
                                      shopItem: shopItem,
                                      userId: widget.userId,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: FooterNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  // --- Helper Widget for Sidebar Item ---
  Widget _buildSideCategoryItem(Category cat, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() => _selectedCategoryId = cat.id.toString());
        _scrollToCategory(cat.id.toString());
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : _sidebarBg,
          border: isSelected ? Border(left: BorderSide(color: _freshMintGreen, width: 4)) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image / Icon Container
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? _freshMintGreen.withValues(alpha: 0.1) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: (cat.imageUrl != null && cat.imageUrl!.isNotEmpty)
                    ? Image.network(
                  cat.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.coffee, color: isSelected ? _freshMintGreen : Colors.grey),
                )
                    : Icon(Icons.coffee, color: isSelected ? _freshMintGreen : Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            // Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                cat.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? _espressoBrown : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
