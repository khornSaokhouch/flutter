import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/global_notification_banner.dart';
import 'package:frontend/core/widgets/style_overlay_banner.dart';
import 'package:frontend/screen/shops/screens/categories_by_shop.dart';
import '../../../response/shops_response/shop_response.dart';
import '../../../server/shops_server/shop_service.dart';
import '../../../server/notification_service.dart';

class ShopsHomePage extends StatefulWidget {
  final String userId;
  const ShopsHomePage({super.key, required this.userId});

  @override
  State<ShopsHomePage> createState() => _ShopsHomePageState();
}

class _ShopsHomePageState extends State<ShopsHomePage> {
  late Future<ShopResponse> _futureShops;

  // Modern Color Palette
  final Color primaryDark = const Color(0xFF2D3250);
  final Color accentColor = const Color(0xFF7077A1);
  final Color highlightColor = const Color(0xFFF6B17A);


  OverlayEntry? _bannerEntry;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _futureShops = ShopsService.getShopsByOwner();
    _initNotifications();
  }

  void _initNotifications() {
    NotificationService().init(
      onMessage: (title, body) {
        if (!mounted) return;
        _showTopBanner(title, body);
      },
    );
  }
  void _showTopBanner(String title, String body) {
    _removeTopBanner();

    _bannerEntry = OverlayEntry(
      builder: (context) {
        final topPadding = MediaQuery.of(context).padding.top;

        return Positioned(
          top: topPadding + 12,
          left: 16,
          right: 16,
          child: TopBanner(
            title: title,
            body: body,
            onClose: _removeTopBanner,
          ),
        );
      },
    );

    final overlay = Overlay.of(context, rootOverlay: true);

    overlay.insert(_bannerEntry!);

    _bannerTimer =
        Timer(const Duration(seconds: 4), _removeTopBanner);
  }

  void _removeTopBanner() {
    _bannerTimer?.cancel();
    _bannerTimer = null;

    _bannerEntry?.remove();
    _bannerEntry = null;
  }

  Future<void> _reloadShops() async {
    setState(() {
      _futureShops = ShopsService.getShopsByOwner();
    });

  }

  // // ✅ SAFE SHORT USER ID (FIXES RangeError)
  // String _shortUserId(String id) {
  //   return id.length > 8 ? id.substring(0, 8) : id;
  // }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      // ✅ APP BAR WITH HAMBURGER MENU
      appBar: AppBar(
        backgroundColor: primaryDark,
        elevation: 0,
        centerTitle: true,

        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, size: 28),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),

        title: const Text(
          "My Business Hub",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),

      // ✅ DRAWER WITH SHOP LIST
      drawer: Drawer(
        child: Column(
          children: [
            // ✅ DYNAMIC HEADER USING OWNER DATA
            FutureBuilder<ShopResponse>(
              future: _futureShops,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                  return UserAccountsDrawerHeader(
                    decoration: BoxDecoration(color: primaryDark),
                    currentAccountPicture: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 40, color: Color(0xFF2D3250)),
                    ),
                    accountName: const Text("Loading..."),
                    accountEmail: const Text(""),
                  );
                }

                final owner = snapshot.data!.data.first.owner;

                return UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: primaryDark),

                  // ✅ PROFILE IMAGE (optional)
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: owner.profileImage != null &&
                        owner.profileImage!.isNotEmpty
                        ? ClipOval(
                      child: Image.network(
                        owner.profileImage!,
                        fit: BoxFit.cover,
                        width: 60,
                        height: 60,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, size: 40),
                      ),
                    )
                        : const Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF2D3250),
                    ),
                  ),

                  // ✅ OWNER NAME
                  accountName: Text(
                    owner.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  // ✅ OWNER EMAIL (or change to userId if you want)
                  accountEmail: Text(owner.email),
                );
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "QUICK ACCESS",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),

            // ✅ SHOP LIST (UNCHANGED)
            Expanded(
              child: FutureBuilder<ShopResponse>(
                future: _futureShops,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                    return const Center(child: Text("No shops found"));
                  }

                  final shops = snapshot.data!.data;

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: shops.length,
                    itemBuilder: (context, index) {
                      final shop = shops[index];
                      return ListTile(
                        leading: const Icon(Icons.store_rounded),
                        title: Text(shop.name),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToShop(shop.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ✅ GRID BODY
      body: RefreshIndicator(
        onRefresh: _reloadShops,
        child: FutureBuilder<ShopResponse>(
          future: _futureShops,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
              return _buildEmptyState();
            }

            final shops = snapshot.data!.data;

            return GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: shops.length,
              itemBuilder: (context, index) {
                final shop = shops[index];
                return _buildShopCard(shop);
              },
            );
          },
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: primaryDark,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Shop", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // ✅ SHOP CARD
  Widget _buildShopCard( shop) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () => _navigateToShop(shop.id),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ SHOP IMAGE
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryDark.withOpacity(0.1),
                  ),
                  child: ClipOval(
                    child: shop.imageUrl != null && shop.imageUrl!.isNotEmpty
                        ? Image.network(
                      shop.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.store, size: 40),
                    )
                        : const Icon(Icons.store, size: 40),
                  ),
                ),

                const SizedBox(height: 12),

                // SHOP NAME
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    shop.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // STATUS
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Active",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // ✅ EMPTY STATE
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "No shops found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text("Click the '+' button to create one"),
        ],
      ),
    );
  }

  // ✅ NAVIGATION (INT SAFE)
  void _navigateToShop(int shopId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GlobalNotificationBanner(
          child: ShopsCategoriesPage(shopId: shopId),
        )

      ),
    );
  }
}
