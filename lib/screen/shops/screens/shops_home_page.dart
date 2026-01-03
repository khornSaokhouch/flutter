import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/global_notification_banner.dart';
import 'package:frontend/screen/shops/screens/categories_by_shop.dart';
import '../../../response/shops_response/shop_response.dart';
import '../../../server/shops_server/shop_service.dart';
import '../widgets/shop_drawer.dart';
 // ✅ Import the new drawer file


// --- LOGO LOADING WIDGET ---
class LogoLoading extends StatefulWidget {
  final double size;
  final String imagePath;
  const LogoLoading({super.key, this.size = 50.0, this.imagePath = 'assets/images/img_1.png'});
  @override
  State<LogoLoading> createState() => _LogoLoadingState();
}

class _LogoLoadingState extends State<LogoLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Center(child: ScaleTransition(scale: _animation, child: SizedBox(width: widget.size, height: widget.size, child: Image.asset(widget.imagePath, fit: BoxFit.contain))));
  }
}

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

  final Color bgGrey = const Color(0xFFF8F9FA);
  final Color textDark = const Color(0xFF1A1C1E);
  final Color coffeeAccent = const Color(0xFFD97706);
  final Color successGreen = const Color(0xFF10B981);

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

  void _onSearch(String query) {
    setState(() {
      _filteredShops = _allShops.where((shop) => shop.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  Future<void> _reloadShops() async {
    _searchController.clear();
    setState(() { _futureShops = _loadShops(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      
      // ✅ Using the extracted ShopDrawer widget
      drawer: ShopDrawer(
        userId: widget.userId,
        shops: _allShops,
        onShopTap: _navigateToShop,
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text("My Shops", style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: textDark),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.person, color: Colors.green),
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _reloadShops,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Overview", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
                  Text("Updated just now", style: TextStyle(fontSize: 12, color: coffeeAccent)),
                ],
              ),
              
              const SizedBox(height: 24),

              // --- SEARCH BAR ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  decoration: const InputDecoration(icon: Icon(Icons.search), hintText: "Search shop by name...", border: InputBorder.none),
                ),
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Your Locations", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
                  Text("View Map", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: coffeeAccent)),
                ],
              ),

              const SizedBox(height: 16),

              // --- SHOP LIST ---
              FutureBuilder<ShopResponse>(
                future: _futureShops,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(padding: EdgeInsets.only(top: 50), child: LogoLoading(size: 80));
                  }
                  if (_filteredShops.isEmpty) {
                    return const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text("No shops found")));
                  }
                  return Column(children: _filteredShops.map((shop) => _buildLocationCard(shop)).toList());
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: textDark,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- LOCATION CARD FETCHING FROM API ---
  Widget _buildLocationCard(dynamic shop) {
    bool isOpen = true; 

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: shop.imageUrl != null && shop.imageUrl!.isNotEmpty
                    ? Image.network(shop.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover)
                    : Container(height: 160, color: Colors.grey[300], child: const Icon(Icons.store, size: 50)),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, 
                      end: Alignment.bottomCenter, 
                      colors: [Colors.transparent, Colors.black.withOpacity(0.8)]
                    )
                  )
                )
              ),
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: (isOpen ? Colors.green : Colors.grey).withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                  child: Text(isOpen ? "Open" : "Closed", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              Positioned(
                bottom: 12, 
                left: 16, 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shop.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          shop.location ?? "No location provided", 
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => _navigateToShop(shop.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  Text("Manage Shop", style: TextStyle(color: coffeeAccent, fontWeight: FontWeight.bold)), 
                  const SizedBox(width: 4), 
                  Icon(Icons.arrow_forward_rounded, size: 16, color: coffeeAccent)
                ]
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToShop(int shopId) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GlobalNotificationBanner(child: ShopsCategoriesPage(shopId: shopId))));
  }
}