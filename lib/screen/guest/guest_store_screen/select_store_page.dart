import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Note: Ensure these imports match your actual project structure
import '../../../core/utils/utils.dart';
import '../../../models/shop.dart';
import '../../../server/shop_serviec.dart';
import 'guest_menu_Items_list_screen.dart';
import '../../../core/widgets/loading/logo_loading.dart';
import './guest_store_map.dart';

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
        // Handle logic if location is disabled
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      try {
        userPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
      } catch (e) {
        userPosition = null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Could not fetch location. Showing all stores."),
            ),
          );
        }
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
          // 📍 GOOGLE MAP ICON (Added here)
          IconButton(
  icon: Icon(Icons.map_outlined, color: _freshMintGreen),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuestStoreMapPage(
          shops: shops, 
          initialPosition: userPosition,
        ),
      ),
    );
  },
),
          // 🔄 REFRESH BUTTON
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
                  LogoLoading(
                    size: 80,
                    imagePath: 'assets/images/img_1.png',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Locating nearby stores...",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : shops.isEmpty
              ? _buildEmptyState()
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final shop = shops[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: _buildStoreCard(shop),
                          );
                        },
                        childCount: shops.length,
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStoreCard(Shop shop) {
    final shopStatus = _evaluateShopOpenStatus(shop.openTime, shop.closeTime);
    final bool isOpen = shopStatus.isOpen;
    final opensText = shopStatus.opensAtFormatted ?? formatTime(shop.openTime);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isOpen) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => GuestMenuScreen(shopId: shop.id),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("This shop is closed. Opens at $opensText"),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // 1. SHOP IMAGE
                Hero(
                  tag: 'shop_${shop.id}',
                  child: Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[200],
                      image: (shop.imageUrl != null && shop.imageUrl!.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(shop.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (shop.imageUrl == null || shop.imageUrl!.isEmpty)
                        ? const Icon(Icons.store_rounded,
                            size: 30, color: Colors.grey)
                        : null,
                  ),
                ),

                const SizedBox(width: 16),

                // 2. SHOP INFO COLUMN
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              shop.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          _buildStatusBadge(isOpen),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shop.location ?? 'No location info',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            (shop.openTime != null && shop.closeTime != null)
                                ? '${formatTimeToAmPm(context, shop.openTime)} - ${formatTimeToAmPm(context, shop.closeTime)}'
                                : 'Hours unavailable',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
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
          Icon(Icons.store_mall_directory_outlined,
              size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "No stores found nearby",
            style: TextStyle(
                fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
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

  Widget _buildStatusBadge(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          color: isOpen ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  _ShopOpenStatus _evaluateShopOpenStatus(
      String? openTimeStr, String? closeTimeStr) {
    if ((openTimeStr == null || openTimeStr.trim().isEmpty) ||
        (closeTimeStr == null || closeTimeStr.trim().isEmpty)) {
      return _ShopOpenStatus(
          isOpen: true, opensAtFormatted: null, closesAtFormatted: null);
    }

    final openSeconds = _parseTimeToSeconds(openTimeStr);
    final closeSeconds = _parseTimeToSeconds(closeTimeStr);
    if (openSeconds == null || closeSeconds == null) {
      return _ShopOpenStatus(
          isOpen: true, opensAtFormatted: null, closesAtFormatted: null);
    }

    final now = DateTime.now();
    final nowSeconds = now.hour * 3600 + now.minute * 60 + now.second;

    bool isOpen;
    if (openSeconds < closeSeconds) {
      isOpen = (nowSeconds >= openSeconds && nowSeconds < closeSeconds);
    } else if (openSeconds > closeSeconds) {
      isOpen = (nowSeconds >= openSeconds) || (nowSeconds < closeSeconds);
    } else {
      isOpen = true;
    }

    final opensAtFormatted = _formatTimeString(openTimeStr);
    final closesAtFormatted = _formatTimeString(closeTimeStr);

    return _ShopOpenStatus(
        isOpen: isOpen,
        opensAtFormatted: opensAtFormatted,
        closesAtFormatted: closesAtFormatted);
  }

  int? _parseTimeToSeconds(String? s) {
    if (s == null) return null;
    final trimmed = s.trim();
    if (trimmed.isEmpty) return null;
    try {
      final parts = trimmed.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final sec = (parts.length >= 3)
            ? int.tryParse(parts[2].split('.').first) ?? 0
            : 0;
        if (h < 0 || h > 23 || m < 0 || m > 59 || sec < 0 || sec > 59) return null;
        return h * 3600 + m * 60 + sec;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String? _formatTimeString(String? s) {
    final seconds = _parseTimeToSeconds(s);
    if (seconds == null) return null;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final dt = DateTime(2000, 1, 1, h, m);
    final formatter = DateFormat.jm();
    return formatter.format(dt);
  }

  String formatTime(String? s) {
    return _formatTimeString(s) ?? (s ?? '--:--');
  }
}

class _ShopOpenStatus {
  final bool isOpen;
  final String? opensAtFormatted;
  final String? closesAtFormatted;
  _ShopOpenStatus(
      {required this.isOpen, this.opensAtFormatted, this.closesAtFormatted});
}