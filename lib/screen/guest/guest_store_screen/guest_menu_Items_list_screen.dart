import 'package:flutter/material.dart';
import '../../../core/widgets/store/category_list.dart';
import '../../../core/widgets/store/menu_item_card.dart';
import '../../../core/widgets/store/pickup_delivery_toggle.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/category_item.dart';
import '../../../models/menu_item.dart';
import '../../../models/shop.dart';
import '../../../models/item_model.dart';
import '../../../routes/footer_nav_routes.dart';
import '../../../server/shop_serviec.dart';
import '../../../server/item_service.dart';
import '../../home_screen.dart';
import '../guest_screen.dart';
import '../guest_store_screen/select_store_page.dart';

class GuestMenuScreen extends StatefulWidget {
  final int shopId;

  const GuestMenuScreen({Key? key, required this.shopId}) : super(key: key);

  @override
  State<GuestMenuScreen> createState() => _GuestMenuScreen();
}

class _GuestMenuScreen extends State<GuestMenuScreen> {
  int _selectedIndex = 2;
  String? _selectedCategoryId;
  bool isPickupSelected = true;
  bool loading = true;

  Shop? shop;
  List<Category> categories = [];
  List<ShopItem> shopItems = [];

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void initState() {
    super.initState();
    loadShop();
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
    final fetchedItems = await ItemService.fetchItemsByShop(widget.shopId);

    setState(() {
      shop = fetchedShop;
      if (fetchedItems != null) {
        shopItems = fetchedItems.data;

        // Extract unique categories from shopItems
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
      loading = false;
    });
  }

  void _openSelectStoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              child: GuestSelectStorePage(stores: const []),
            ),
          );
        },
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 0 || index == 2) {
      setState(() => _selectedIndex = index);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GuestLayout()),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Material(
            type: MaterialType.transparency,
            child: LoginBottomSheet(),
          );
        },
      );
    }
  }


  /// Group items by category, include empty categories
  Map<String, List<ShopItem>> _groupMenuItems() {
    final Map<String, List<ShopItem>> grouped = {};

    for (var cat in categories) {
      // Get items for this category
      final items = shopItems.where((i) => i.category.id == cat.id).toList();

      // Add category even if items list is empty
      grouped[cat.name] = items;
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
                bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
          ),
          child: Column(
            children: [
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
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _openSelectStoreSheet(context),
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
                      onTap: () => _openSelectStoreSheet(context),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: theme.colorScheme.secondary,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    PickupDeliveryToggle(
                      isPickupSelected: isPickupSelected,
                      onToggle: (val) => setState(() => isPickupSelected = val),
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
                  iconAsset: 'assets/images/coffee.png', // fallback if API image fails
                  isSelected: _selectedCategoryId == cat.id.toString(),
                  onTap: () {
                    setState(() => _selectedCategoryId = cat.id.toString());
                    _scrollToCategory(cat.id.toString());
                  },
                );
              }).toList(),
            ),
          ),

          // Right: Menu Items with Pull-to-Refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadShop,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: groupedItems.entries.map((entry) {
                    final categoryForSection = categories
                        .firstWhere((c) => c.name == entry.key);
                    final String categoryId = categoryForSection.id.toString();

                    return Container(
                      key: _categoryKeys[categoryId],
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 12.0),
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
                          ...entry.value.map(
                                (shopItem) => MenuItemCard(
                              item: MenuItem(
                                id: shopItem.item.id.toString(),
                                categoryId: shopItem.category.id.toString(),
                                name: shopItem.item.name,
                                price:
                                '\$${(shopItem.item.priceCents / 100).toStringAsFixed(2)}',
                                imageUrl: shopItem.item.imageUrl,
                              ),
                            ),
                          ).toList(),
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
      bottomNavigationBar: FooterNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
