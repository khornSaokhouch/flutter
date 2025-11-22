import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/utils/utils.dart';
import '../../../models/shop.dart';
import '../../../server/shop_serviec.dart';
import 'guest_menu_Items_list_screen.dart';

class GuestSelectStorePage extends StatefulWidget {
  const GuestSelectStorePage({super.key});

  @override
  State<GuestSelectStorePage> createState() => _GuestSelectStorePageState();
}

class _GuestSelectStorePageState extends State<GuestSelectStorePage> {
  bool loading = true;
  List<Shop> shops = [];
  Position? userPosition;

  @override
  void initState() {
    super.initState();
    loadShops();
  }

  Future<void> loadShops() async {
    setState(() => loading = true);

    try {
      // 1️⃣ Get user location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
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

      // 2️⃣ Fetch shops from API
      final response = await ShopService.fetchShops();
      if (response != null) {
        final List<Shop> fetchedShops = response.data;

        // 3️⃣ Calculate distance for each shop
        for (var shop in fetchedShops) {
          if (shop.latitude != null &&
              shop.longitude != null &&
              userPosition != null) {
            shop.distanceInKm = Geolocator.distanceBetween(
                userPosition!.latitude,
                userPosition!.longitude,
                shop.latitude!,
                shop.longitude!) /
                1000;
          } else {
            shop.distanceInKm = 0.0;
          }
        }

        // Sort by nearest
        fetchedShops.sort(
              (a, b) => (a.distanceInKm ?? 0).compareTo(b.distanceInKm ?? 0),
        );

        setState(() {
          shops = fetchedShops;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      print('Error loading shops or location: $e');
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => loadShops(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: shops.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final shop = shops[index];
          final imageUrl = shop.imageUrl;

          return Card(
            margin:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            shadowColor: Colors.grey.withOpacity(0.2),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GuestMenuScreen(shopId: shop.id),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl != null && imageUrl.startsWith('http')
                          ? Image.network(
                        imageUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return Container(
                            width: 90,
                            height: 90,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image,
                                color: Colors.grey),
                          );
                        },
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
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  shop.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                shop.distanceInKm != null
                                    ? '${shop.distanceInKm!.toStringAsFixed(1)} km'
                                    : '0.0 km',
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13),
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
                                  shop.location ?? '',
                                  style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13),
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
                                'Open: ${formatTime(shop.openTime)} - ${formatTime(shop.closeTime)}',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
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
