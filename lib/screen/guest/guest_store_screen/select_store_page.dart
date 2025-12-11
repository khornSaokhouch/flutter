import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/utils.dart';
import '../../../models/shop.dart';
import '../../../server/shop_serviec.dart';
import 'guest_menu_Items_list_screen.dart';
import 'package:intl/intl.dart';

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

    // Evaluate open/closed using shop hours
    final shopStatus = _evaluateShopOpenStatus(shop.openTime, shop.closeTime);
    final bool isOpen = shopStatus.isOpen;

    final opensText =
        shopStatus.opensAtFormatted ?? formatTime(shop.openTime);
    final closesText =
        shopStatus.closesAtFormatted ?? formatTime(shop.closeTime);

    return Stack(
      children: [
        // --------------------------------------------------
        // BASE CARD (dimmed when closed)
        // --------------------------------------------------
        Opacity(
          opacity: isOpen ? 1.0 : 0.35, // dim card when closed
          child: Container(
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
                  if (isOpen) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            GuestMenuScreen(shopId: shop.id),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                        Text("This shop is closed. Opens at $opensText"),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -------- Shop Image --------
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
                          child: (imageUrl != null &&
                              imageUrl.startsWith('http'))
                              ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                            const Icon(Icons.store,
                                color: Colors.grey),
                          )
                              : const Icon(Icons.store,
                              color: Colors.grey, size: 40),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // -------- Info Column --------
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Shop Name & Distance
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    shop.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _freshMintGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    shop.distanceInKm != null
                                        ? "${shop.distanceInKm!.toStringAsFixed(1)} km"
                                        : "-- km",
                                    style: TextStyle(
                                      color: _freshMintGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              ],
                            ),

                            const SizedBox(height: 6),

                            // Location Row
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 14,
                                    color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    shop.location ?? "No address",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Status + Hours
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color:
                                    isOpen ? _freshMintGreen : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOpen ? "Open" : "Closed",
                                  style: TextStyle(
                                    color: isOpen
                                        ? _freshMintGreen
                                        : Colors.red,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text("•",
                                    style: TextStyle(
                                        color: Colors.grey[400])),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isOpen
                                        ? "Closes at $closesText"
                                        : "Opens at $opensText",
                                    style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // --------------------------------------------------
        // FULL OVERLAY WHEN CLOSED
        // --------------------------------------------------
        if (!isOpen)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "CLOSED",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Opens at $opensText",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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

  /// ---------------------------
  /// OPEN/CLOSED TIME LOGIC
  /// ---------------------------
  /// Returns structured result about open/closed and formatted times.
  _ShopOpenStatus _evaluateShopOpenStatus(String? openTimeStr, String? closeTimeStr) {
    // If either is missing — fallback to shop.status (if you want), but here we treat as open.
    if ((openTimeStr == null || openTimeStr.trim().isEmpty) ||
        (closeTimeStr == null || closeTimeStr.trim().isEmpty)) {
      // If you prefer to fallback to shop.status, adapt caller to pass that.
      return _ShopOpenStatus(isOpen: true, opensAtFormatted: null, closesAtFormatted: null);
    }

    final openSeconds = _parseTimeToSeconds(openTimeStr);
    final closeSeconds = _parseTimeToSeconds(closeTimeStr);
    if (openSeconds == null || closeSeconds == null) {
      return _ShopOpenStatus(isOpen: true, opensAtFormatted: null, closesAtFormatted: null);
    }

    final now = DateTime.now();
    final nowSeconds = now.hour * 3600 + now.minute * 60 + now.second;

    bool isOpen;
    if (openSeconds < closeSeconds) {
      // same-day window
      isOpen = (nowSeconds >= openSeconds && nowSeconds < closeSeconds);
    } else if (openSeconds > closeSeconds) {
      // overnight window (e.g., open 22:00, close 04:00)
      isOpen = (nowSeconds >= openSeconds) || (nowSeconds < closeSeconds);
    } else {
      // equal -> treat as open 24h
      isOpen = true;
    }

    final opensAtFormatted = _formatTimeString(openTimeStr);
    final closesAtFormatted = _formatTimeString(closeTimeStr);

    return _ShopOpenStatus(isOpen: isOpen, opensAtFormatted: opensAtFormatted, closesAtFormatted: closesAtFormatted);
  }

  /// Parse "HH:mm:ss" or "HH:mm" into seconds since midnight.
  /// Returns null if parse fails.
  int? _parseTimeToSeconds(String? s) {
    if (s == null) return null;
    final trimmed = s.trim();
    if (trimmed.isEmpty) return null;
    try {
      final parts = trimmed.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final sec = (parts.length >= 3) ? int.tryParse(parts[2].split('.').first) ?? 0 : 0;
        if (h < 0 || h > 23 || m < 0 || m > 59 || sec < 0 || sec > 59) return null;
        return h * 3600 + m * 60 + sec;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Convert "HH:mm:ss" or "HH:mm" to a human friendly format, e.g. "1:29 AM"
  String? _formatTimeString(String? s) {
    final seconds = _parseTimeToSeconds(s);
    if (seconds == null) return null;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final dt = DateTime(2000, 1, 1, h, m);
    final formatter = DateFormat.jm(); // e.g. "1:29 AM"
    return formatter.format(dt);
  }
}

/// Small value class for status
class _ShopOpenStatus {
  final bool isOpen;
  final String? opensAtFormatted;
  final String? closesAtFormatted;
  _ShopOpenStatus({required this.isOpen, this.opensAtFormatted, this.closesAtFormatted});
}
