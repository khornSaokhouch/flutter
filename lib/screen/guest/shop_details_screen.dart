import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screen/guest/guest_store_screen/guest_menu_Items_list_screen.dart';
import 'package:geolocator/geolocator.dart';

// --- Imports (Adjust paths as needed) ---
// Ensure formatTimeToAmPm is here
import '../../models/shop.dart';
import '../../server/shop_service.dart';
import '../user/store_screen/menu_Items_list_screen.dart';
import '../../core/widgets/loading/logo_loading.dart'; 

import './widget/shop_details/shop_bottom_bar.dart';
import './widget/shop_details/shop_header_image.dart';
import './widget/shop_details/shop_info_details.dart';
import './widget/shop_details/shop_title_section.dart';
class ShopDetailsScreen extends StatefulWidget {
  final int shopId;
  final int? userId;

  const ShopDetailsScreen({super.key, required this.shopId, this.userId});

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  late Future<Shop?> _shopFuture;

  // User location
  Position? _userPosition;
  double? _distanceKm;

  // Theme Colors
  final Color _bgWhite = const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _shopFuture = ShopService.fetchShopById(widget.shopId);

    _determinePosition().then((pos) {
      setState(() => _userPosition = pos);
    }).catchError((e) {
    });
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Location services are disabled.';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw 'Location permissions are denied';
    }
    if (permission == LocationPermission.deniedForever) throw 'Location permissions are permanently denied.';

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    );

  }

  void _computeDistanceIfPossible(Shop shop) {
    if (_userPosition == null || shop.latitude == null || shop.longitude == null) return;

    final meters = Geolocator.distanceBetween(
      _userPosition!.latitude, _userPosition!.longitude,
      shop.latitude!, shop.longitude!,
    );

    final km = meters / 1000.0;
    if (_distanceKm == null || (_distanceKm! - km).abs() > 0.001) {
      setState(() => _distanceKm = double.parse(km.toStringAsFixed(2)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWhite,
      body: FutureBuilder<Shop?>(
        future: _shopFuture,
        builder: (context, snapshot) {
          // Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LogoLoading(size: 60),
                  SizedBox(height: 16),
                  Text('Loading shop details...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(child: Text(snapshot.hasError ? 'Error: ${snapshot.error}' : 'Shop not found.'));
          }

          final shop = snapshot.data!;
          final bool isOpen = shop.status == 1;

          WidgetsBinding.instance.addPostFrameCallback((_) => _computeDistanceIfPossible(shop));

          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Immersive Header
                  ShopHeaderImage(imageUrl: shop.imageUrl),

                  // 2. Content Body
                  SliverToBoxAdapter(
                    child: Container(
                      transform: Matrix4.translationValues(0.0, -30.0, 0.0), // The curve overlap
                      decoration: BoxDecoration(
                        color: _bgWhite,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Drag Handle
                            Center(
                              child: Container(
                                width: 40, height: 4,
                                margin: const EdgeInsets.only(bottom: 20, top: 10),
                                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                              ),
                            ),

                            // Component: Title, Status, Buttons
                            ShopTitleSection(shop: shop, isOpen: isOpen),
                            
                            const SizedBox(height: 24),
                            const Divider(height: 1, color: Color(0xFFEEEEEE)),
                            const SizedBox(height: 24),

                            const Text(
                              "Details",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 16),

                            // Component: Address, Time, Owner
                            ShopInfoDetails(shop: shop),

                            const SizedBox(height: 100), // Space for bottom bar
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 3. Sticky Bottom Bar
              ShopBottomBar(
                distanceKm: _distanceKm,
                shopDistance: shop.distanceInKm,
                isOpen: isOpen,
                onOrderPressed: () {
                  if (widget.userId == null) {
                    // 👤 Guest user
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GuestMenuScreen(shopId: shop.id),
                      ),
                    );
                  } else {
                    // 🔐 Logged-in user
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MenuScreen(
                          userId: widget.userId!,
                          shopId: shop.id,
                        ),
                      ),
                    );
                  }
                },
              ),

            ],
          );
        },
      ),
    );
  }
}