import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

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

  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _bgGrey = const Color(0xFFF9FAFB);

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
        // Just load shops without distance if location disabled, or handle error
        // For now proceeding to allow logic to flow
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Try get position
      try {
        userPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
      } catch (e) {
        // Handle timeout or error gracefully
        userPosition = null;
      }

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
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // Custom Back Button text
        leadingWidth: 80,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.grey),
          label: const Text(
            'Back',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 10)),
        ),
        title: const Text(
          "Select Store",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: _freshMintGreen),
            onPressed: () => loadShops(),
          ),
        ],
      ),
      body: loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _freshMintGreen),
                  const SizedBox(height: 16),
                  const Text("Locating nearby stores...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : shops.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  itemCount: shops.length,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final shop = shops[index];
                    return _buildShopTile(shop);
                  },
                ),
    );
  }

  Widget _buildShopTile(Shop shop) {
    final imageUrl = shop.imageUrl;
    final bool isOpen = shop.status == 1; // Assuming 1 is Open

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GuestMenuScreen(shopId: shop.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                    color: Colors.grey[50],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (imageUrl != null && imageUrl.startsWith('http'))
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.store, color: Colors.grey),
                          )
                        : const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Icon(Icons.store_rounded, color: Colors.grey, size: 30),
                          ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 2. Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Distance Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              shop.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // Distance Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _freshMintGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              shop.distanceInKm != null
                                  ? '${shop.distanceInKm!.toStringAsFixed(1)} km'
                                  : '-- km',
                              style: TextStyle(
                                color: _freshMintGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Location Text
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shop.location ?? 'No address',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Time & Status
                      Row(
                        children: [
                          // Status Dot
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isOpen ? _freshMintGreen : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOpen ? "Open" : "Closed",
                            style: TextStyle(
                              color: isOpen ? _freshMintGreen : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "•", 
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${formatTime(shop.openTime)} - ${formatTime(shop.closeTime)}',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_mall_directory_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "No stores found nearby",
            style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => loadShops(),
            icon: Icon(Icons.refresh, color: _freshMintGreen),
            label: Text("Try Again", style: TextStyle(color: _freshMintGreen)),
          )
        ],
      ),
    );
  }
}