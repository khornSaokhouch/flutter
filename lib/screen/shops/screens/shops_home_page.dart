import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/global_notification_banner.dart';
import 'package:frontend/screen/shops/screens/categories_by_shop.dart';
import '../../../response/shops_response/shop_response.dart';
import '../../../server/shops_server/shop_service.dart';
import '../widgets/shop_drawer.dart';
import '../../../core/widgets/loading/logo_loading.dart'; // Import your component

class ShopsHomePage extends StatefulWidget {
  final String userId;
  const ShopsHomePage({super.key, required this.userId});

  @override
  State<ShopsHomePage> createState() => _ShopsHomePageState();
}

class _ShopsHomePageState extends State<ShopsHomePage> {
  late Future<ShopResponse> _futureShops;
  List<dynamic> _allShops = [];
  List<dynamic> _filteredShops = [];
  final TextEditingController _searchController = TextEditingController();

  // Modern Forest Green Palette
  final Color primaryGreen = const Color(0xFF1B5E20); 
  final Color accentGreen = const Color(0xFF4CAF50);
  final Color bgGrey = const Color(0xFFF0F4F1);

  @override
  void initState() {
    super.initState();
    _futureShops = _loadShops();
  }

  Future<ShopResponse> _loadShops() async {
    final response = await ShopsService.getShopsByOwner();
    setState(() {
      _allShops = response.data;
      _filteredShops = response.data;
    });
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      drawer: ShopDrawer(
        userId: widget.userId,
        shops: _allShops,
        onShopTap: _navigateToShop,
      ),
      body: FutureBuilder<ShopResponse>(
        future: _futureShops,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeBanner(),
                      const SizedBox(height: 25),
                      _buildSearchField(),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Active Location", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2E3E33))),
                          Text("${_filteredShops.length} Shops", style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildModernShopCard(_filteredShops[index]),
                    childCount: _filteredShops.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      
    );
  }

  // --- NEW CUSTOM LOADING UI ---
  Widget _buildLoadingState() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LogoLoading(size: 100), // YOUR PULSING LOGO
          const SizedBox(height: 30),
          const _LoadingTextUpdater(), // Moving text updates
        ],
      ),
    );
  }

Widget _buildAppBar() {
  return SliverAppBar(
    pinned: true, // ✅ FIXED HEADER
    floating: false,
    backgroundColor: Colors.white,
    elevation: 1,
    centerTitle: true,
    title: const Text(
      "MANAGER HUB",
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w900,
        fontSize: 14,
        letterSpacing: 2,
      ),
    ),
    leading: Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.black),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    ),
    actions: [
      IconButton(
        onPressed: () {},
        icon: const Icon(
          Icons.notifications_none_rounded,
          color: Colors.black,
        ),
      ),
    ],
  );
}


  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryGreen, const Color(0xFF0A2F10)]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: primaryGreen.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Active Status", style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("Hello, Chief Manager", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
            child: const Text("All systems operational", style: TextStyle(color: Colors.white, fontSize: 11)),
          )
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15)],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() {
          _filteredShops = _allShops.where((s) => s.name.toLowerCase().contains(val.toLowerCase())).toList();
        }),
        decoration: InputDecoration(
          hintText: "Search branch...",
          prefixIcon: Icon(Icons.search, color: accentGreen),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildModernShopCard(dynamic shop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () => _navigateToShop(shop.id),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    child: shop.imageUrl != null && shop.imageUrl!.isNotEmpty
                        ? Image.network(shop.imageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover)
                        : Container(height: 200, color: Colors.grey[200], child: const Icon(Icons.storefront_rounded, size: 50)),
                  ),
                  Positioned(
                    top: 20, left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                      child: const Row(
                        children: [
                          CircleAvatar(radius: 3, backgroundColor: Colors.green),
                          SizedBox(width: 6),
                          Text("ONLINE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shop.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2E3E33))),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 5),
                              Text(shop.location ?? "Global Branch", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 50, width: 50,
                      decoration: BoxDecoration(color: bgGrey, shape: BoxShape.circle),
                      child: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: primaryGreen),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToShop(int shopId) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => 
      GlobalNotificationBanner(child: ShopsCategoriesPage(shopId: shopId))));
  }
}

// --- DYNAMIC LOADING TEXT COMPONENT ---
class _LoadingTextUpdater extends StatefulWidget {
  const _LoadingTextUpdater();
  @override
  State<_LoadingTextUpdater> createState() => _LoadingTextUpdaterState();
}

class _LoadingTextUpdaterState extends State<_LoadingTextUpdater> {
  int _idx = 0;
  late Timer _timer;
  final List<String> _msgs = ["Brewing data...", "Grinding fresh info...", "Steam-cleaning UI...", "Pouring shop lists...", "Almost served!"];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (t) => setState(() => _idx = (_idx + 1) % _msgs.length));
  }
  @override
  void dispose() { _timer.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(_msgs[_idx], key: ValueKey(_msgs[_idx]), style: TextStyle(color: Colors.grey[500], fontSize: 14, fontStyle: FontStyle.italic)),
    );
  }
}