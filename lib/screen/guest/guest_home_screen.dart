import 'package:flutter/material.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:intl/intl.dart'; // Used for time formatting

// --- Services & Models ---
import '../../server/shop_serviec.dart'; 
import '../../models/shop.dart';

// --- Components ---
import '../../core/widgets/card/shop_card.dart';
import '../../core/widgets/loading/logo_loading.dart'; // ✅ Imported your new component

// --- Screens ---
import './shop_details_screen.dart';
import 'guest_store_screen/guest_no_store_nearby_screen.dart';

class GuestScreen extends StatefulWidget {
  const GuestScreen({super.key});

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  late Future<List<Shop>> _shopsFuture;
  
  // Theme Colors
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  void _loadShops() {
    setState(() {
      _shopsFuture = ShopService.fetchShops().then((response) => response?.data ?? []);
    });
  }

  Future<void> _handleRefresh() async {
    // Simulate delay to show the pulsing animation
    await Future.delayed(const Duration(milliseconds: 1500));
    _loadShops();
    await _shopsFuture; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Navbar(),
      ),
      // 1. PULL TO REFRESH with Custom Logo
      body: CustomRefreshIndicator(
        onRefresh: _handleRefresh,
        builder: (BuildContext context, Widget child, IndicatorController controller) {
          return Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              // The Loading Logo slides down
              if (!controller.isIdle)
                Positioned(
                  top: 35.0 * controller.value, 
                  child: Opacity(
                    opacity: controller.value.clamp(0.0, 1.0),
                    // ✅ Using your reusable component here
                    child: const LogoLoading(size: 40), 
                  ),
                ),
              // The Scrollable Content
              Transform.translate(
                offset: Offset(0, 100.0 * controller.value),
                child: child,
              ),
            ],
          );
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // --- Banner Section ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 20.0),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    image: const DecorationImage(
                      image: AssetImage("assets/images/banner.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black12, Colors.black54],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Join the Rewards program to enjoy free beverages!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text('JOIN NOW', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text('GUEST', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // --- Pickup & Delivery Buttons ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Greeting!!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBigCard(
                            title: "Pickup",
                            imagePath: 'assets/images/pickup.jpg',
                            isActive: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const GuestNoStoreNearbyScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildBigCard(
                            title: "Delivery",
                            imagePath: 'assets/images/pickup.jpg',
                            isActive: false,
                            onTap: () => _showComingSoonDialog(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),

            // --- Nearby Stores Header ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nearby Stores',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E)),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text("See All", style: TextStyle(color: Color(0xFF4A6B5C))),
                    )
                  ],
                ),
              ),
            ),

            // --- SHOPS LIST ---
            FutureBuilder<List<Shop>>(
              future: _shopsFuture,
              builder: (context, snapshot) {
                // 2. INITIAL LOADING with Custom Component
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(60.0),
                      child: LogoLoading(size: 60), // ✅ Using your new component
                    ),
                  );
                } else if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(child: Text('Error: ${snapshot.error}')),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: Text('No stores found nearby.')),
                    ),
                  );
                }

                final shops = snapshot.data!;

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final shop = shops[index];
                      // Determine if shop is open based on time strings
                      final status = _evaluateShopOpenStatus(shop.openTime, shop.closeTime);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                        child: Stack(
                          children: [
                            // The Card
                            ShopCard(
                              shop: shop,
                              onTap: () {
                                if (status.isOpen) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ShopDetailsScreen(shopId: shop.id),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Shop is closed. Opens at ${status.opensAtFormatted}')),
                                  );
                                }
                              },
                            ),
                            
                            // Open/Closed Badge
                            Positioned(
                              top: 10,
                              right: 10,
                              child: _StatusBadge(isOpen: status.isOpen),
                            ),

                            // Closed Overlay (Optional: grey out if closed)
                            if(!status.isOpen)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(16)
                                  ),
                                ),
                              )
                          ],
                        ),
                      );
                    },
                    childCount: shops.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildBigCard({
    required String title,
    required String imagePath,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: isActive
                  ? Image.asset(imagePath, fit: BoxFit.cover)
                  : ColorFiltered(
                      colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                      child: Image.asset(imagePath, fit: BoxFit.cover),
                    ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.transparent, Colors.black.withOpacity(0.8)],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            if (!isActive)
              Positioned.fill(child: Container(color: Colors.black.withOpacity(0.3))),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : Colors.white70,
                          ),
                        ),
                        if (!isActive) ...[
                          const Spacer(),
                          const Icon(Icons.lock_outline, color: Colors.white70, size: 20),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                child: const Icon(Icons.rocket_launch_rounded, size: 32, color: Color(0xFF1B4D3E)),
              ),
              const SizedBox(height: 20),
              const Text("Coming Soon!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                "We are working hard to bring delivery to your location.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Got it"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Logic for Shop Hours ---
  _ShopOpenStatus _evaluateShopOpenStatus(String? openTimeStr, String? closeTimeStr) {
    if ((openTimeStr == null || openTimeStr.isEmpty) || (closeTimeStr == null || closeTimeStr.isEmpty)) {
      return _ShopOpenStatus(isOpen: true, opensAtFormatted: null);
    }
    int? _toSeconds(String? s) {
      if (s == null) return null;
      final parts = s.trim().split(':');
      if (parts.length < 2) return null;
      return (int.tryParse(parts[0]) ?? 0) * 3600 + (int.tryParse(parts[1]) ?? 0) * 60;
    }

    final openSec = _toSeconds(openTimeStr);
    final closeSec = _toSeconds(closeTimeStr);
    if(openSec == null || closeSec == null) return _ShopOpenStatus(isOpen: true);

    final now = DateTime.now();
    final nowSec = now.hour * 3600 + now.minute * 60 + now.second;
    bool isOpen = (openSec < closeSec) 
        ? (nowSec >= openSec && nowSec < closeSec) 
        : (nowSec >= openSec || nowSec < closeSec); // Overnight

    return _ShopOpenStatus(isOpen: isOpen, opensAtFormatted: openTimeStr);
  }
}

class _ShopOpenStatus {
  final bool isOpen;
  final String? opensAtFormatted;
  _ShopOpenStatus({required this.isOpen, this.opensAtFormatted});
}

class _StatusBadge extends StatelessWidget {
  final bool isOpen;
  const _StatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Text(
        isOpen ? "Open" : "Closed",
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class Navbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black),
        onPressed: () {},
      ),
      centerTitle: true,
      title: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/img_1.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.coffee, color: Color(0xFF1B4D3E)),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}