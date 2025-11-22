import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/store/pickup_delivery_toggle.dart';
import '../../../models/shop.dart';
import '../../../server/shop_serviec.dart';
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
  bool _checkingLocation = true;
  bool _hasNearbyStore = false;

  Position? _currentPosition;
  List<Shop> _nearbyStores = [];
  List<Shop> _allStores = []; // keep all shops

  bool _bottomSheetClosed = false;
  bool _isPickupSelected = true; // 👈 needed for PickupDeliveryToggle

  static const double _nearbyRadiusMeters = 5000.0; // 5 km

  @override
  void initState() {
    super.initState();
    _checkNearbyStores();
  }

  Future<void> _checkNearbyStores() async {
    try {
      // 1. Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _checkingLocation = false);
        return;
      }

      // 2. Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Fetch shops from server
      final response = await ShopService.fetchShops();
      final allStores = response?.data ?? <Shop>[];

      // 4. Filter by distance (nearby shops)
      final nearby = allStores.where((shop) {
        if (shop.latitude == null || shop.longitude == null) return false;

        final distanceMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          shop.latitude!,
          shop.longitude!,
        );

        shop.distanceInKm = distanceMeters / 1000.0; // store for UI

        return distanceMeters <= _nearbyRadiusMeters;
      }).toList();

      // sort nearby shops by distance
      nearby.sort((a, b) {
        final da = a.distanceInKm ?? 999999;
        final db = b.distanceInKm ?? 999999;
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

      // 5. If there are nearby stores, open the select store bottom sheet
      if (hasNearby) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openSelectStoreSheet(context, _nearbyStores);
        });
      }
    } catch (e) {
      debugPrint("Error checking location: $e");
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
      // user closed the sheet (Cancel or swipe down)
      setState(() {
        _bottomSheetClosed = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLocation) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If we already pushed the bottom sheet, just keep an empty scaffold
    if (_hasNearbyStore && !_bottomSheetClosed) {
      // auto-open bottom sheet → keep blank because bottom sheet is on top
      return const Scaffold();
    }

    // No nearby store: show your "No Store Nearby" UI
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MENU',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Top row: "Select Store" + Pickup/Delivery toggle
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    _openSelectStoreSheet(
                      context,
                      _allStores.isNotEmpty ? _allStores : _nearbyStores,
                    );
                  },
                  child: const Row(
                    children: [
                      Text(
                        'Select Store',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down, color: Colors.orange),
                    ],
                  ),
                ),
                PickupDeliveryToggle(
                  isPickupSelected: _isPickupSelected,
                  onToggle: (val) => setState(() => _isPickupSelected = val),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.circle, size: 120, color: Colors.grey.shade300),
                      const Icon(
                        Icons.location_on_rounded,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Store Nearby',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      'There is no available store nearby. Please select one manually.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      // if no nearby, open ALL shops so user can still choose
                      _openSelectStoreSheet(
                        context,
                        _allStores.isNotEmpty ? _allStores : _nearbyStores,
                      );
                    },
                    child: const Text(
                      'Select Store',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
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
