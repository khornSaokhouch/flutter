import 'package:flutter/material.dart';
import 'package:frontend/screen/shops/screens/categories_by_shop.dart';
import '../../../response/shops_response/shop_response.dart';
import '../../../server/shops_server/shop_service.dart';
import '../widgets/shop_card_widgets.dart'; // OwnerShopsCard

class ShopsHomePage extends StatefulWidget {
  final String userId;

  const ShopsHomePage({super.key, required this.userId});

  @override
  State<ShopsHomePage> createState() => _ShopsHomePageState();
}

class _ShopsHomePageState extends State<ShopsHomePage> {
  late Future<ShopResponse> _futureShops;

  // Theme Colors
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() {
      _futureShops = ShopsService.getShopsByOwner();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      body: RefreshIndicator(
        onRefresh: _loadShops,
        color: _freshMintGreen,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Header
            SliverAppBar(
              backgroundColor: _bgGrey,
              expandedHeight: 120.0,
              floating: true,
              pinned: false,
              elevation: 0,
              automaticallyImplyLeading: false,   // Removes back button
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome Owner,",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "My Shops",
                        style: TextStyle(
                          color: _espressoBrown,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Shops List
            FutureBuilder<ShopResponse>(
              future: _futureShops,
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // Error
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                // No shops
                if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.store_mall_directory_outlined, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text("You haven't added any shops yet."),
                        ],
                      ),
                    ),
                  );
                }

                final shops = snapshot.data!.data;

                // Success → Show Shops Card
                return SliverFillRemaining(
                  hasScrollBody: true,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: OwnerShopsCard(
                      shops: shops,

                      // ⭐⭐ UPDATED: Tap on shop opens ShopsCategoriesPage ⭐⭐
                      onTap: (shopId) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShopsCategoriesPage(shopId: shopId),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // Add Shop button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add Shop Logic Here
        },
        backgroundColor: _espressoBrown,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
