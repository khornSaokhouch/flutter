import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/store/pickup_delivery_toggle.dart';
import '../../../models/shop.dart';
import '../../../server/shop_serviec.dart';
import 'select_store_page.dart';

class GuestNoStoreNearbyScreen extends StatefulWidget {
  // userId is nullable for guest mode
  final int? userId;
  const GuestNoStoreNearbyScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<GuestNoStoreNearbyScreen> createState() =>
      _GuestNoStoreNearbyScreenState();
}

class _GuestNoStoreNearbyScreenState extends State<GuestNoStoreNearbyScreen> {
  bool _checkingLocation = true;
  bool _hasNearbyStore = false;
  bool _isPickupSelected = true;

  Position? _currentPosition;
  bool _bottomSheetClosed = false;

  static const double _nearbyRadiusMeters = 5000.0; // 5 km

  @override
  void initState() {
    super.initState();
    _checkNearbyStores();
  }

  Future<void> _checkNearbyStores() async {
    setState(() {
      _checkingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _checkingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = position;

      // Fetch shops from API
      final response = await ShopService.fetchShops();
      final allShops = response?.data ?? <Shop>[];

      bool hasNearby = false;

      for (final shop in allShops) {
        if (shop.latitude == null || shop.longitude == null) continue;

        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          shop.latitude!,
          shop.longitude!,
        );

        shop.distanceInKm = distance / 1000.0;

        if (distance <= _nearbyRadiusMeters) {
          hasNearby = true;
        }
      }

      if (hasNearby) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openSelectStoreSheet(context);
        });
      }

      setState(() {
        _hasNearbyStore = hasNearby;
        _checkingLocation = false;
      });
    } catch (e) {
      print("Error checking location: $e");
      setState(() => _checkingLocation = false);
    }
  }

  void _openSelectStoreSheet(BuildContext context) {
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
              child: const GuestSelectStorePage(),
            ),
          );
        },
      ),
    ).whenComplete(() {
      setState(() {
        _bottomSheetClosed = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLocation) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // While the auto-open bottom sheet is active, keep this blank
    if (_hasNearbyStore && !_bottomSheetClosed) {
      return const Scaffold();
    }

    // "No Store Nearby" UI (or user closed the sheet)
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.userId != null
            ? IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        )
            : null, // No back button for guests
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
          // Top row: Select Store + toggle
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _openSelectStoreSheet(context),
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
          // Center: no store nearby message
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.circle,
                          size: 120, color: Colors.grey.shade300),
                      const Icon(Icons.location_on_rounded,
                          size: 40, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Store Nearby',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      'There is no available store nearby. Please select one manually.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => _openSelectStoreSheet(context),
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
