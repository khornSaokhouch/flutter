import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';

import '../../../server/shop_serviec.dart';
import 'select_store_page.dart';

class NoStoreNearbyScreen extends StatefulWidget {
  final int userId;
  const NoStoreNearbyScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<NoStoreNearbyScreen> createState() => _NoStoreNearbyScreenState();
}

class _NoStoreNearbyScreenState extends State<NoStoreNearbyScreen> {
  bool _checkingLocation = true;
  bool _hasNearbyStore = false;

  @override
  void initState() {
    super.initState();
    _checkNearbyStores();
  }

  Future<void> _checkNearbyStores() async {
    try {
      // Step 1: Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _checkingLocation = false);
        return;
      }

      // Step 2: Get current position
      Position position =
      await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // Step 3: Check for nearby stores (dummy example)
      List<Map<String, double>> dummyStores = [
        {'lat': 11.562108, 'lng': 104.888535}, // Example store
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
              child: SelectStorePage(userId: widget.userId, stores: []),
            ),
          );
        },
      ),
    );
  }

  /// ✅ Move this function INSIDE the State class

  @override
  Widget build(BuildContext context) {
    if (_checkingLocation) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasNearbyStore) {
      return const Scaffold();
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.circle, size: 120, color: Colors.grey.shade300),
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
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      'There is no available store nearby. Please select one manually.',
                      textAlign: TextAlign.center,
                      style:
                      TextStyle(fontSize: 16, color: Colors.grey.shade600),
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
