import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/widgets/store/pickup_delivery_toggle.dart'; 
import '../../../models/shop.dart';
import '../../../server/shop_serviec.dart';
import 'select_store_page.dart'; 

class GuestNoStoreNearbyScreen extends StatefulWidget {
  final int? userId;
  const GuestNoStoreNearbyScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<GuestNoStoreNearbyScreen> createState() =>
      _GuestNoStoreNearbyScreenState();
}

class _GuestNoStoreNearbyScreenState extends State<GuestNoStoreNearbyScreen> {
  // --- Logic Variables ---
  bool _checkingLocation = true;
  bool _hasNearbyStore = false;
  bool _isPickupSelected = true;
  Position? _currentPosition;
  bool _bottomSheetClosed = false;

  // --- Constants & Theme ---
  static const double _nearbyRadiusMeters = 5000.0; // 5 km
  final Color _freshMintGreen = const Color(0xFF4E8D7C); // Unit Green
  final Color _espressoBrown = const Color(0xFF4B2C20);

  @override
  void initState() {
    super.initState();
    // ✅ RESTORED: This will trigger the location popup logic on start
    _checkNearbyStores(); 
  }

  Future<void> _checkNearbyStores() async {
    setState(() => _checkingLocation = true);

    try {
      // 1. Check & Request Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _checkingLocation = false);
        return;
      }

      // 2. Get Position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = position;

      // 3. Fetch Shops
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

      // 4. Auto-Open Sheet if nearby store found
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
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: const ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: GuestSelectStorePage(),
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
    // ✅ RESTORED: Loading State UI
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
              )
            ],
          ),
        ),
      );
    }

    // ✅ Main UI (Premium White & Green)
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ===========================================
          // 1. Top Control Bar (Select Store + Toggle)
          // ===========================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Select Store Dropdown Look
                InkWell(
                  onTap: () => _openSelectStoreSheet(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
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
                
                // Toggle Switch
                PickupDeliveryToggle(
                  isPickupSelected: _isPickupSelected,
                  onToggle: (val) => setState(() => _isPickupSelected = val),
                ),
              ],
            ),
          ),

          // ===========================================
          // 2. Center Empty State Content
          // ===========================================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Illustration Circle
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: _freshMintGreen.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.location_off_rounded,
                        size: 60,
                        color: _freshMintGreen.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Text
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

                  // Main CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => _openSelectStoreSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _freshMintGreen, // Unit Color
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Select Store Manually',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
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

  // Helper for AppBar to keep code clean
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: widget.userId != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: const Text(
        'MENU',
        style: TextStyle(
          color: Colors.black, 
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0
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
}