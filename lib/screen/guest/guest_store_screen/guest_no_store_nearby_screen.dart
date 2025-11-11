import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import 'select_store_page.dart';
import '../../../core/widgets/store/pickup_delivery_toggle.dart'; // Ensure this widget exists

class GuestNoStoreNearbyScreen extends StatefulWidget {
  // Make userId nullable to support guest mode
  final int? userId;
  const GuestNoStoreNearbyScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<GuestNoStoreNearbyScreen> createState() => _GuestNoStoreNearbyScreen();
}

class _GuestNoStoreNearbyScreen extends State<GuestNoStoreNearbyScreen> {
  bool _checkingLocation = true;
  bool _hasNearbyStore = false;
  bool _isPickupSelected = true; // State for the toggle

  @override
  void initState() {
    super.initState();
    _checkNearbyStores();
  }

  Future<void> _checkNearbyStores() async {
    setState(() {
      _checkingLocation = true; // Set to true at start of check
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        // If permission is denied, we can't check for nearby stores, so just show the "No Store Nearby" message
        setState(() => _checkingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // Replace this with your real API or store list
      List<Map<String, double>> dummyStores = [
        {'lat': 11.562108, 'lng': 104.888535}, // Example store
        {'lat': 11.565000, 'lng': 104.890000}, // Another example store nearby
      ];

      bool hasNearby = dummyStores.any((store) {
        double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          store['lat']!,
          store['lng']!,
        );
        return distance <= 5000; // 5 km radius
      });

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
              // Pass the nullable userId
              child: GuestSelectStorePage( stores: []),
            ),
          );
        },
      ),
    );
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

    // If a nearby store was found and the bottom sheet is open,
    // we don't need to show the "No Store Nearby" UI.
    // The sheet will be dismissed if the user picks a store or closes it.
    if (_hasNearbyStore) {
      return const Scaffold(
        backgroundColor: Colors.white, // Or a background matching your app for when the sheet is active
      );
    }

    // This is the main "No Store Nearby" UI
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Only show back button if userId is not null (i.e., user is logged in)
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                // Pickup/Delivery Toggle - from GuestNoStoreNearbyScreen
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
                      const Icon(Icons.location_on_rounded, size: 40, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Store Nearby',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      'There is no available store nearby. Please select one manually.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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