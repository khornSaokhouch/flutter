import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/utils/auth_utils.dart';
import '../../../core/widgets/store/category_list.dart';
import '../../../core/widgets/store/menu_item_card.dart';
import '../../../core/widgets/store/pickup_delivery_toggle.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/item_model.dart';
import '../../../models/menu_item.dart';
import '../../../models/shop.dart';
import '../../../routes/footer_nav_routes.dart';
import '../../../server/item_service.dart';
import '../../../server/shop_serviec.dart';
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
  final int _selectedIndex = 2;
  String? _selectedCategoryId;
  bool isPickupSelected = true;
  bool loading = true;
  Shop? shop;

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};

  List<Category> categories = [];
  List<ShopItem> shopItems = [];

  // 🔹 For store selector
  List<Shop> _stores = [];
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = await AuthUtils.checkAuthAndGetUser(
      context: context,
      userId: widget.userId,
    );
    if (user != null) {
      // User is authenticated, load shop items
      loadShop();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load shop info + items from API
  Future<void> loadShop() async {
    setState(() => loading = true);

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
  }

  /// 🔹 Helper: called when user taps store name / arrow
  Future<void> _handleSelectStoreTap(BuildContext context) async {
    try {
      // 1) Fetch all stores if not already loaded
      if (_stores.isEmpty) {
        final response = await ShopService.fetchShops();
        _stores = response?.data ?? <Shop>[];
      }

      if (_stores.isEmpty) return;

      // 2) Try to get current position (optional, ignore errors)
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
        // ignore location errors, we can still show store list
      }

      if (!mounted) return;
      // 3) Open bottom sheet with your desired signature
      _openSelectStoreSheet(context, _stores);
    } catch (e) {
      debugPrint('Error preparing stores for select sheet: $e');
    }
  }

  /// 🔹 EXACT signature & behavior you requested
  void _openSelectStoreSheet(BuildContext context, List<Shop> stores) {
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
      // user closed the sheet (Cancel or swipe down)
      setState(() {
      });
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          child: Column(
            children: [
              // Top row: title + search
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Spacer(),
                    Text(
                      'MENU',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.search, color: theme.colorScheme.onBackground),
                  ],
                ),
              ),
              // Second row: store name + pickup/delivery toggle
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _handleSelectStoreTap(context),
                      child: Text(
                        shop?.name ?? 'Unknown Store',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _handleSelectStoreTap(context),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: theme.colorScheme.secondary,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    PickupDeliveryToggle(
                      isPickupSelected: isPickupSelected,
                      onToggle: (val) =>
                          setState(() => isPickupSelected = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Row(
        children: [
          // Left: Category List
          SizedBox(
            width: 100,
            child: ListView(
              children: categories.map((cat) {
                return CategoryTile(
                  category: cat,
                  iconAsset: 'assets/images/coffee.png',
                  isSelected: _selectedCategoryId == cat.id.toString(),
                  onTap: () {
                    setState(
                            () => _selectedCategoryId = cat.id.toString());
                    _scrollToCategory(cat.id.toString());
                  },
                );
              }).toList(),
            ),
          ),
          // Right: Menu Items
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: groupedItems.entries.map((entry) {
                  final categoryForSection =
                  categories.firstWhere((c) => c.name == entry.key);
                  final String categoryId =
                  categoryForSection.id.toString();

                  return Container(
                    key: _categoryKeys[categoryId],
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 20,
                                width: 4,
                                color: theme.colorScheme.secondary,
                                margin: const EdgeInsets.only(right: 8),
                              ),
                              Text(
                                entry.key,
                                style:
                                theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onBackground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Items in section
                        ...entry.value.map(
                              (shopItem) => MenuItemCard(
                            item: MenuItem(
                              id: shopItem.item.id.toString(),
                              categoryId:
                              shopItem.category.id.toString(),
                              name: shopItem.item.name,
                              price:
                              '\$${(shopItem.item.priceCents / 100).toStringAsFixed(2)}',
                              imageUrl: shopItem.item.imageUrl,
                            ),
                            shopItem: shopItem,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
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
}
