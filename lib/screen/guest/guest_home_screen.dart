import 'package:flutter/material.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:frontend/screen/guest/widget/guest_banner.dart';
import 'package:frontend/screen/guest/widget/guest_nearby_header.dart';
import 'package:frontend/screen/guest/widget/guest_pickup_delivery.dart';
import 'package:frontend/screen/guest/widget/guest_shop_list.dart';
import 'package:frontend/screen/guest/widget/navbar.dart';

import '../../models/shop.dart';

import '../../core/widgets/loading/logo_loading.dart';
import '../../server/shop_service.dart';


class GuestScreen extends StatefulWidget {
  const GuestScreen({super.key});

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  late Future<List<Shop>> _shopsFuture;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  void _loadShops() {
    _shopsFuture =
        ShopService.fetchShops().then((r) => r?.data ?? []);
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    _loadShops();
    await _shopsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: GuestNavbar(),
      ),
      body: CustomRefreshIndicator(
        onRefresh: _handleRefresh,
        builder: (BuildContext context, Widget child, IndicatorController controller) {
          final progress = controller.value.clamp(0.0, 1.0);

          return Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              if (!controller.isIdle)
                Positioned(
                  top: 35.0 * progress,
                  child: Opacity(
                    opacity: progress,
                    child: const LogoLoading(size: 40),
                  ),
                ),
              Transform.translate(
                offset: Offset(0, 100.0 * progress),
                child: child,
              ),
            ],
          );
        },

        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const GuestBanner(),
            const GuestPickupDelivery(),
            const GuestNearbyHeader(),
            GuestShopList(shopsFuture: _shopsFuture),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }
}
