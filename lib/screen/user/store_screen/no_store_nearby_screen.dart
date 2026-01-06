import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/widgets/store/pickup_delivery_toggle.dart';
import '../../../models/shop.dart';
import '../../../server/shop_service.dart';
import 'select_store_page.dart';

class NoStoreNearbyScreen extends StatefulWidget {
  final int userId;

  const NoStoreNearbyScreen({
    super.key,
    required this.userId,
  });

  @override
  State<NoStoreNearbyScreen> createState() => _NoStoreNearbyScreenState();
}

class _NoStoreNearbyScreenState extends State<NoStoreNearbyScreen> {
  // Logic
  bool _checkingLocation = true;
  bool _hasNearbyStore = false;

  Position? _currentPosition;
  List<Shop> _nearbyStores = [];
  List<Shop> _allStores = [];

  bool _bottomSheetClosed = false;
  bool _isPickupSelected = true;

  static const double _nearbyRadiusMeters = 5000.0; // 5 km
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);

  @override
  void initState() {
    super.initState();
    _checkNearbyStores();
  }

  Future<void> _checkNearbyStores() async {
    setState(() => _checkingLocation = true);

    try {
      // 1) Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _checkingLocation = false);
        return;
      }

      // 2) Position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );


      // 3) Fetch shops
      final response = await ShopService.fetchShops();
      final allStores = response?.data ?? <Shop>[];

      // 4) Filter by distance (nearby)
      final nearby = allStores.where((shop) {
        if (shop.latitude == null || shop.longitude == null) return false;

        final distanceMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          shop.latitude!,
          shop.longitude!,
        );

        shop.distanceInKm = distanceMeters / 1000.0;
        return distanceMeters <= _nearbyRadiusMeters;
      }).toList();

      // sort by distance
      nearby.sort((a, b) {
        final da = a.distanceInKm ?? double.infinity;
        final db = b.distanceInKm ?? double.infinity;
        return da.compareTo(db);
      });

      final hasNearby = nearby.isNotEmpty;

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _allStores = allStores;
        _nearbyStores = nearby;
        _hasNearbyStore = hasNearby;
        _checkingLocation = false;
      });

      // 5) If nearby shops found — auto-open sheet
      if (hasNearby) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openSelectStoreSheet(context, _nearbyStores);
        });
      }
    } catch (e, st) {
      debugPrint("Error checking location: $e\n$st");
      if (!mounted) return;
      setState(() => _checkingLocation = false);
    }
  }

  void _openSelectStoreSheet(BuildContext context, List<Shop> stores) {
    if (stores.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.6,
        maxChildSize: 1.0,
        builder: (_, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.9,
              child: SelectStorePage(
                userId: widget.userId,
                stores: stores,
                userPosition: _currentPosition,
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _bottomSheetClosed = true;
      });
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: null, // 👈 removes the back button
      automaticallyImplyLeading: false, // 👈 prevents Flutter from auto-adding one
      title: const Text(
        'MENU',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black),
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading UI (matches Guest look)
    if (_checkingLocation) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _freshMintGreen),
              const SizedBox(height: 16),
              Text(
                "Locating nearby stores...",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // If the bottom sheet is auto-opened and not closed yet: keep scaffold blank (sheet is on top)
    if (_hasNearbyStore && !_bottomSheetClosed) {
      return const Scaffold();
    }

    // No nearby store UI (match Guest)
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Top Control Bar (Select Store + Toggle)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => _openSelectStoreSheet(
                    context,
                    _allStores.isNotEmpty ? _allStores : _nearbyStores,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06), // Soft shadow
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.storefront_rounded, color: _freshMintGreen, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Select Store',
                          style: TextStyle(
                            color: _espressoBrown,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, color: _espressoBrown),
                      ],
                    ),
                  ),
                ),
                PickupDeliveryToggle(
                  isPickupSelected: _isPickupSelected,
                  onToggle: (val) => setState(() => _isPickupSelected = val),
                ),
              ],
            ),
          ),

          // Center Empty State
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Illustration Circle (mint tint)
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: _freshMintGreen.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.location_off_rounded,
                        size: 60,
                        color: _freshMintGreen.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'No Store Nearby',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'There are no available stores detected nearby. Please select one manually.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Main CTA (mint)
                  InkWell(
                    onTap: () => _openSelectStoreSheet(
                      context,
                      _allStores.isNotEmpty ? _allStores : _nearbyStores,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        color: _freshMintGreen,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: _freshMintGreen.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Select Store Manually',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
