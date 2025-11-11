import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/shop.dart';
import '../../../server/shop_serviec.dart';
import 'menu_items_list_screen.dart';

class SelectStorePage extends StatefulWidget {
  final int userId;
  final List<Map<String, dynamic>> stores;

  const SelectStorePage({
    Key? key,
    required this.userId,
    required this.stores,
  }) : super(key: key);

  @override
  State<SelectStorePage> createState() => _SelectStorePageState();
}

class _SelectStorePageState extends State<SelectStorePage> {
  bool loading = true;
  Position? userPosition;
  Shop?shop;
  List<Map<String, dynamic>> displayStores = [];

  @override
  void initState() {
    super.initState();
    displayStores = widget.stores;
    _checkLocationAndAutoSelect();
    loadShops();
  }

  Future<void> loadShops() async {
    setState(() => loading = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      userPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final response = await ShopService.fetchShops();
      if (response != null) {
        displayStores = response.data.map((shop) {
          double distance = 0;
          if (shop.latitude != null &&
              shop.longitude != null &&
              userPosition != null) {
            distance = Geolocator.distanceBetween(
                userPosition!.latitude,
                userPosition!.longitude,
                shop.latitude!,
                shop.longitude!) /
                1000;
          }
          return {
            'id': shop.id,
            'name': shop.name,
            'lat': shop.latitude ?? 0,
            'lng': shop.longitude ?? 0,
            'address': shop.location ?? '',
            'image_asset': shop.imageUrl ?? '',
            'distance': distance.toStringAsFixed(2),
           // 'opening_hours': shop.openingHours ?? '08:00 AM - 08:00 PM',
          };
        }).toList();

        displayStores.sort((a, b) =>
            double.parse(a['distance']!).compareTo(double.parse(b['distance']!)));
      }
    } catch (e) {
      print('Error loading shops or location: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _checkLocationAndAutoSelect() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final nearbyStore = displayStores.firstWhere(
              (store) {
            final storeLat = store['lat'] ?? 0;
            final storeLng = store['lng'] ?? 0;
            final distance = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              storeLat,
              storeLng,
            );
            return distance <= 5000; // within 5 km
          },
          orElse: () => {}
      );

      if (nearbyStore.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openMenuScreen(widget.userId, nearbyStore['id']);
        });
      }
    } catch (e) {
      print('Error checking location: $e');
    }
  }

  void _openMenuScreen(int userId, int shopId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MenuScreen(userId: userId, shopId: shopId),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ),
        title: const Text(
          "SELECT STORE",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.location_on_outlined, color: Colors.grey),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.builder(
        itemCount: displayStores.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final store = displayStores[index];
          final imageUrl = store['image_asset'] ?? '';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            shadowColor: Colors.grey.withOpacity(0.2),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openMenuScreen(widget.userId, store['id']),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              width: 90,
                              height: 90,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image,
                                  color: Colors.grey),
                            ),
                      )
                          : Image.asset(
                        'assets/images/img_1.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  store['name'] ?? 'Unknown Store',
                                  maxLines: 2,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${store['distance']} km',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  store['address'] ?? 'Unknown address',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                store['opening_hours'] ?? '08:00 AM - 08:00 PM',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
