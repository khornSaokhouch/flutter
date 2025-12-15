// home_screen.dart
import 'package:flutter/material.dart';
import 'package:frontend/screen/user/widget/home_widgets.dart';
import '../../core/utils/shop_utils.dart';
import '../../core/utils/utils.dart';
import '../../models/shop.dart';
import '../../core/widgets/card/shop_card.dart';
import '../guest/shop_details_screen.dart';
import 'controller/home_controller.dart';
import 'layout.dart';
import 'navbar.dart';



class HomeScreen extends StatefulWidget {
  final int? userId;
  const HomeScreen({super.key, this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController controller;

  @override
  void initState() {
    super.initState();
    controller = HomeController();
    controller.init(userId: widget.userId, onChange: () {
      if (mounted) setState(() {});
    });

    // Important: pass BuildContext so AuthUtils can use navigator/scaffold if needed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initPage(context);
      controller.loadShops();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Navbar(userId: userId),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: BannerWidget()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: PickupDeliveryRow(
                userId: userId,
                onPickupTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Layout(userId: userId, selectedIndex: 2),
                    ),
                  );
                },
                onDeliveryTap: () => showComingSoonDialog(context),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
          SliverToBoxAdapter(child: NearbyHeader(onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Layout(userId: userId, selectedIndex: 2),
              ),
            );
          })),
          // shops list
          FutureBuilder<List<Shop>>(
            future: controller.shopsFuture,
            builder: (context, snapshot) {
              return buildShopsSliver(context, snapshot, (shop) {
                final shopStatus = evaluateShopOpenStatus(shop.openTime, shop.closeTime);
                final isOpen = shopStatus.isOpen;
                final opensText = shopStatus.opensAtFormatted ?? formatTimeString(shop.openTime) ?? (shop.openTime ?? '--:--');
                final closesText = shopStatus.closesAtFormatted ?? formatTimeString(shop.closeTime) ?? (shop.closeTime ?? '--:--');

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: Stack(
                    children: [
                      Opacity(
                        opacity: isOpen ? 1.0 : 0.35,
                        child: ShopCard(
                          shop: shop,
                          onTap: () {
                            if (isOpen) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShopDetailsScreen(shopId: shop.id, userId: userId),
                                ),
                              );
                            } else {
                              final msg = 'This shop is closed. Opens at $opensText';
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                            }
                          },
                        ),
                      ),
                      if (!isOpen)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(12),
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
                                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              });
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }


}
