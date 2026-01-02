import 'package:flutter/material.dart';
import 'package:frontend/screen/guest/widget/shop_status.dart';

import '../../../core/utils/shop_utils.dart';
import '../../../core/widgets/card/shop_card.dart';
import '../../../core/widgets/loading/logo_loading.dart';
import '../../../models/shop.dart';
import '../shop_details_screen.dart';

class GuestShopList extends StatelessWidget {
  final Future<List<Shop>> shopsFuture;

  const GuestShopList({super.key, required this.shopsFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Shop>>(
      future: shopsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(60),
              child: Center(child: LogoLoading(size: 40)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(child: Text('No stores found nearby')),
          );
        }

        final shops = snapshot.data!;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final shop = shops[index];
              final status =
                  evaluateShopOpenStatus(shop.openTime, shop.closeTime);

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ShopCard(
                      shop: shop,
                      onTap: () {
                        if (!status.isOpen) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ShopDetailsScreen(shopId: shop.id),
                          ),
                        );
                      },
                    ),

                    // ✅ BADGE WITHOUT SHADOW
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IgnorePointer(
                        child: StatusBadge(isOpen: status.isOpen),
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
    );
  }
}
