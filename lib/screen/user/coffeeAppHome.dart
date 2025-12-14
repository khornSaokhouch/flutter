import 'package:flutter/material.dart' show Align, Alignment, AppBar, AssetImage, BlendMode, BorderRadius, BorderSide, BouncingScrollPhysics, BoxDecoration, BoxFit, BoxShadow, BoxShape, BuildContext, Center, CircularProgressIndicator, ClipRRect, Color, ColorFilter, ColorFiltered, Colors, Column, ConnectionState, Container, CrossAxisAlignment, CustomScrollView, DecorationImage, Dialog, EdgeInsets, ElevatedButton, Expanded, FontWeight, FutureBuilder, Icon, IconButton, Icons, Image, InkWell, Key, LinearGradient, MainAxisSize, MainAxisAlignment, Material, MaterialPageRoute, Navigator, Offset, OutlinedButton, Padding, Positioned, PreferredSize, RoundedRectangleBorder, Row, Scaffold, Shadow, Size, SizedBox, SliverChildBuilderDelegate, SliverList, SliverToBoxAdapter, Spacer, Stack, State, StatefulWidget, StatelessWidget, Text, TextAlign, TextButton, TextStyle, VoidCallback, Widget, debugPrint, showDialog, ScaffoldMessenger, SnackBar, Opacity;
import 'package:intl/intl.dart';

import 'package:frontend/screen/user/store_screen/no_store_nearby_screen.dart';
import '../../core/utils/utils.dart';
import '../../server/shop_serviec.dart';
import '../../models/shop.dart';
import '../../core/widgets/card/shop_card.dart';
import '../guest/shop_details_screen.dart';

import '../../core/utils/auth_utils.dart';
import '../../models/user.dart';
import '../order/order_screen.dart';
import 'layout.dart';

class HomeScreen extends StatefulWidget {
  final int? userId;
  const HomeScreen({super.key,  this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user;
  bool isLoading = true;
  late Future<List<Shop>> _shopsFuture;



  @override
  void initState() {
    super.initState();
    _initPage();
    _shopsFuture = ShopService.fetchShops().then((response) => response?.data ?? []);
  }

  Future<void> _initPage() async {
    try {
      user = await AuthUtils.checkAuthAndGetUser(context: context, userId: widget.userId ?? 0);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Navbar(userId: widget.userId ?? 0),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ====================================================
          // 1. BANNER SECTION
          // ====================================================
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
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ====================================================
          // 2. PICKUP & DELIVERY SECTION
          // ====================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Greeting!!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
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
                              MaterialPageRoute(
                                builder: (_) => Layout(
                                  userId: widget.userId ?? 0,
                                  selectedIndex: 2, // 2 = NoStoreNearbyScreen in your Layout._screens
                                ),
                              ),
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

          // ====================================================
          // 3. NEARBY STORES HEADER
          // ====================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nearby Stores',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Layout(
                            userId: widget.userId ?? 0,
                            selectedIndex: 2, // 2 = NoStoreNearbyScreen in your Layout._screens
                          ),
                        ),
                      );

                    },
                    child: const Text(
                      "See All",
                      style: TextStyle(color: Color(0xFF4A6B5C)),
                    ),
                  )
                ],
              ),
            ),
          ),

          // ====================================================
          // 4. SHOPS LIST (Using SliverList for performance)
          // ====================================================
          FutureBuilder<List<Shop>>(
            future: _shopsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF1B4D3E)),
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Text('Error: ${snapshot.error}'),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: Text('No stores found nearby.'),
                    ),
                  ),
                );
              }

              final shops = snapshot.data!;

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final shop = shops[index];

                    // compute open/closed status for this shop
                    final shopStatus = _evaluateShopOpenStatus(shop.openTime, shop.closeTime);
                    final bool isOpen = shopStatus.isOpen;
                    final opensText = shopStatus.opensAtFormatted ?? _formatTimeOrFallback(shop.openTime);
                    final closesText = shopStatus.closesAtFormatted ?? _formatTimeOrFallback(shop.closeTime);

                    // Display ShopCard but dim + overlay when closed
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: Stack(
                        children: [
                          // Dimmed ShopCard when closed
                          Opacity(
                            opacity: isOpen ? 1.0 : 0.35,
                            child: ShopCard(
                              shop: shop,
                              onTap: () {
                                if (isOpen) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ShopDetailsScreen(
                                        shopId: shop.id,
                                        userId: widget.userId,
                                      ),
                                    ),
                                  );
                                } else {
                                  final msg = 'This shop is closed. Opens at $opensText';
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                }
                              },
                            ),
                          ),

                          // Centered full overlay when closed
                          if (!isOpen)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(12), // match ShopCard internal radius roughly
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "CLOSED",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Opens at $opensText",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

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
    );
  }

  // --- Helper Widget for the Premium Cards ---
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
            // Image
            Positioned.fill(
              child: isActive
                  ? Image.asset(imagePath, fit: BoxFit.cover)
                  : ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.saturation,
                ),
                child: Image.asset(imagePath, fit: BoxFit.cover),
              ),
            ),
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Disabled Dark Overlay
            if (!isActive)
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),

            // Text & Ripple
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
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch_rounded, size: 32, color: Color(0xFF1B4D3E)),
              ),
              const SizedBox(height: 20),
              const Text(
                "Coming Soon!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
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

  // ---------------------------
  // OPEN/CLOSED TIME LOGIC (copied from SelectStorePage style)
  // ---------------------------
  _ShopOpenStatus _evaluateShopOpenStatus(String? openTimeStr, String? closeTimeStr) {
    // If either is missing — treat as open
    if ((openTimeStr == null || openTimeStr.trim().isEmpty) ||
        (closeTimeStr == null || closeTimeStr.trim().isEmpty)) {
      return _ShopOpenStatus(isOpen: true, opensAtFormatted: null, closesAtFormatted: null);
    }

    final openSeconds = parseTimeToSeconds(openTimeStr);
    final closeSeconds = parseTimeToSeconds(closeTimeStr);
    if (openSeconds == null || closeSeconds == null) {
      // parse failed -> assume open
      return _ShopOpenStatus(isOpen: true, opensAtFormatted: null, closesAtFormatted: null);
    }

    final now = DateTime.now();
    final nowSeconds = now.hour * 3600 + now.minute * 60 + now.second;

    bool isOpen;
    if (openSeconds < closeSeconds) {
      isOpen = (nowSeconds >= openSeconds && nowSeconds < closeSeconds);
    } else if (openSeconds > closeSeconds) {
      // overnight window
      isOpen = (nowSeconds >= openSeconds) || (nowSeconds < closeSeconds);
    } else {
      // equal -> treat as 24h open
      isOpen = true;
    }

    final opensAtFormatted = formatTimeString(openTimeStr);
    final closesAtFormatted = formatTimeString(closeTimeStr);

    return _ShopOpenStatus(
      isOpen: isOpen,
      opensAtFormatted: opensAtFormatted,
      closesAtFormatted: closesAtFormatted,
    );
  }



  String _formatTimeOrFallback(String? s) {
    return formatTimeString(s) ?? (s ?? '--:--');
  }
}

class _ShopOpenStatus {
  final bool isOpen;
  final String? opensAtFormatted;
  final String? closesAtFormatted;
  _ShopOpenStatus({required this.isOpen, this.opensAtFormatted, this.closesAtFormatted});
}

// ===== Navbar =====
class Navbar extends StatelessWidget {
  final int userId;
  const Navbar({required this.userId, super.key});

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
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.coffee, color: Color(0xFF1B4D3E)),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllOrdersScreen(userId: userId),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
