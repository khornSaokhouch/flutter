import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../models/shop.dart';
import 'menu_items_list_screen.dart';

class SelectStorePage extends StatefulWidget {
  final int userId;
  final List<Shop> stores;
  final Position? userPosition;

  const SelectStorePage({
    super.key,
    required this.userId,
    required this.stores,
    this.userPosition,
  });

  @override
  State<SelectStorePage> createState() => _SelectStorePageState();
}

class _SelectStorePageState extends State<SelectStorePage> {
  late List<Shop> displayStores;
  Position? userPosition;

  @override
  void initState() {
    super.initState();
    userPosition = widget.userPosition;
    displayStores = List<Shop>.from(widget.stores);

    // If distanceInKm not filled yet but we have user position, compute & sort
    if (userPosition != null) {
      _computeDistancesAndSort();
    }
  }

  void _computeDistancesAndSort() {
    for (final shop in displayStores) {
      if (shop.latitude != null &&
          shop.longitude != null &&
          userPosition != null) {
        final distanceMeters = Geolocator.distanceBetween(
          userPosition!.latitude,
          userPosition!.longitude,
          shop.latitude!,
          shop.longitude!,
        );
        shop.distanceInKm = distanceMeters / 1000.0;
      }
    }

    displayStores.sort((a, b) {
      final da = a.distanceInKm ?? 999999;
      final db = b.distanceInKm ?? 999999;
      return da.compareTo(db);
    });
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
    return Scaffold(
      appBar: AppBar(
        // backgroundColor: Colors.white,
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
            onPressed: () {
              // TODO: implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.location_on_outlined, color: Colors.grey),
            onPressed: () async {
              // optional: refresh distances with new location
              try {
                final permission = await Geolocator.requestPermission();
                if (permission == LocationPermission.denied ||
                    permission == LocationPermission.deniedForever) {
                  return;
                }
                final pos = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                );
                setState(() {
                  userPosition = pos;
                });
                _computeDistancesAndSort();
              } catch (_) {}
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.builder(
        itemCount: displayStores.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final shop = displayStores[index];
          final imageUrl = shop.imageUrl ?? '';
          final distanceStr = shop.distanceInKm != null
              ? shop.distanceInKm!.toStringAsFixed(2)
              : '--';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            shadowColor: Colors.grey.withOpacity(0.2),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openMenuScreen(widget.userId, shop.id),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // image
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
                    // info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // name + distance
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  shop.name,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '$distanceStr km',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // address
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  shop.location ?? 'Unknown address',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // opening hours
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${shop.openTime ?? '08:00'} - ${shop.closeTime ?? '20:00'}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
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
