import 'package:flutter/material.dart';
import '../../../core/widgets/store/menu_item_card.dart'; 
import '../../../core/widgets/store/pickup_delivery_toggle.dart'; 
import '../../../models/menu_item.dart'; // Ensure this maps to your UI needs
import '../../../models/shop.dart';
import '../../../models/item_model.dart'; // The file containing your new models
import '../../../routes/footer_nav_routes.dart';
import '../../../server/shop_serviec.dart';
import '../../../server/item_service.dart';
import '../../home_screen.dart';
import '../../user/store_screen/search_page_screen.dart';
import '../guest_screen.dart';
import '../guest_store_screen/select_store_page.dart';
import '../guest_home_screen.dart';
import '../../../core/widgets/loading/logo_loading.dart';

class GuestMenuScreen extends StatefulWidget {
  final int shopId;

  const GuestMenuScreen({super.key, required this.shopId});

  @override
  State<GuestMenuScreen> createState() => _GuestMenuScreen();
}

class _GuestMenuScreen extends State<GuestMenuScreen> {
  // --- Logic Variables ---
  int _selectedIndex = 2;
  String? _selectedCategoryId;
  bool isPickupSelected = true;
  bool loading = true;

  Shop? shop;
  List<Category> categories = [];
  List<ShopItem> shopItems = [];

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};

  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _sidebarBg = const Color(0xFFF7F7F7);

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

    try {
      final fetchedShop = await ShopService.fetchShopById(widget.shopId);
      final fetchedItems = await ItemService.fetchItemsByShop(widget.shopId);

      setState(() {
        shop = fetchedShop;
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
        loading = false;
      });
    } catch (e) {
      print("Error loading shop: $e");
      setState(() => loading = false);
    }
  }

  void _openSelectStoreSheet(BuildContext context) {
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
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: const GuestSelectStorePage(),
            ),
          );
        },
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 0 || index == 2) {
      setState(() => _selectedIndex = index);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GuestLayout()),
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

  Map<String, List<ShopItem>> _groupMenuItems() {
    final Map<String, List<ShopItem>> grouped = {};
    for (var cat in categories) {
      final items = shopItems.where((i) => i.category.id == cat.id).toList();
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
            letterSpacing: 1.2
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchPage(shopId:widget.shopId), // 👉 your next page
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  LogoLoading(),
                  SizedBox(height: 16),
                  Text(
                    'Loading Menu...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // ===========================================
                // 1. Store Selection & Toggle Bar
                // ===========================================
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
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
                        onTap: () => _openSelectStoreSheet(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06), // Soft shadow
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.storefront_rounded,
                                   color: _freshMintGreen, size: 20),
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
                              Icon(Icons.keyboard_arrow_down,
                                   color: _espressoBrown, size: 18),
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
                // 2. Menu Content (Split View)
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

                      // --- Right Content (Items) ---
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
                                final categoryForSection = categories
                                    .firstWhere((c) => c.name == entry.key);
                                final String categoryId =
                                    categoryForSection.id.toString();

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
                                            // Mapping ShopItem to MenuItem UI model
                                            item: MenuItem(
                                              id: shopItem.item.id.toString(),
                                              categoryId: shopItem.category.id.toString(),
                                              name: shopItem.item.name,
                                              // Using priceCents from your new Item model
                                              price: '\$${(shopItem.item.priceCents / 100).toStringAsFixed(2)}',
                                              imageUrl: shopItem.item.imageUrl,
                                              // description: shopItem.item.description ?? '',
                                            ),
                                            shopItem: shopItem,
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
          border: isSelected 
              ? Border(left: BorderSide(color: _freshMintGreen, width: 4))
              : null,
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
                color: isSelected ? _freshMintGreen.withOpacity(0.1) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: (cat.imageUrl != null && cat.imageUrl!.isNotEmpty) 
                  ? Image.network(
                      cat.imageUrl!, // Using the corrected field name
                      fit: BoxFit.cover,
                      errorBuilder: (_,__,___) => Icon(Icons.coffee, color: isSelected ? _freshMintGreen : Colors.grey),
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