import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontend/screen/user/widget/home_widgets.dart';

import '../../core/utils/shop_utils.dart';
import '../../core/utils/utils.dart';
import '../../models/shop.dart';
import '../../core/widgets/card/shop_card.dart';
import '../../core/widgets/style_overlay_banner.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late final HomeController controller;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  @override
  void initState() {
    super.initState();

    controller = HomeController();
    controller.init(
      userId: widget.userId,
      onChange: () {
        if (mounted) setState(() {});
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initPage(context);
      controller.loadShops();
      _listenPushEvents();
    });
  }

  /// =======================
  /// 🔔 PUSH LISTENERS
  /// =======================
  void _listenPushEvents() {
    /// FOREGROUND PUSH
    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      if (!mounted) return;

      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? '';

      _showTopBanner(title, body);
    });

    /// BACKGROUND → TAP
    _onMessageOpenedSub =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          if (!mounted) return;

          // You can navigate or handle data here
          debugPrint('Notification tapped: ${message.data}');
        });
  }

  /// =======================
  /// 🔝 ANIMATED TOP BANNER
  /// =======================
  void _showTopBanner(String title, String body) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final animation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );

    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 16,
        right: 16,
        child: SlideTransition(
          position: animation,
          child: TopBanner(
            title: title,
            body: body,
            onClose: () {
              controller.reverse().then((_) {
                entry.remove();
                controller.dispose();
              });
            },
          ),
        ),
      ),
    );

    overlay.insert(entry);
    controller.forward();

    /// AUTO DISMISS
    Future.delayed(const Duration(seconds: 3), () {
      if (controller.isCompleted) {
        controller.reverse().then((_) {
          entry.remove();
          controller.dispose();
        });
      }
    });
  }

  @override
  void dispose() {
    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();
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
          SliverToBoxAdapter(child: bannerWidget()),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: PickupDeliveryRow(
                userId: userId,
                onPickupTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          Layout(userId: userId, selectedIndex: 2),
                    ),
                  );
                },
                onDeliveryTap: () =>
                    showComingSoonDialog(context),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),

          SliverToBoxAdapter(
            child: NearbyHeader(
              onSeeAll: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        Layout(userId: userId, selectedIndex: 2),
                  ),
                );
              },
            ),
          ),

          /// SHOPS
          FutureBuilder<List<Shop>>(
            future: controller.shopsFuture,
            builder: (context, snapshot) {
              return buildShopsSliver(context, snapshot, (shop) {
                final status = evaluateShopOpenStatus(
                  shop.openTime,
                  shop.closeTime,
                );

                final isOpen = status.isOpen;
                final opensText =
                    status.opensAtFormatted ??
                        formatTimeString(shop.openTime) ??
                        (shop.openTime ?? '--:--');

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: ShopCard(
                    shop: shop,
                    onTap: () {
                      if (isOpen) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShopDetailsScreen(
                              shopId: shop.id,
                              userId: userId,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Shop closed. Opens at $opensText',
                            ),
                          ),
                        );
                      }
                    },
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
