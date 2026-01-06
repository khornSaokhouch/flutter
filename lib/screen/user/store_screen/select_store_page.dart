import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/utils.dart';
import '../../../models/shop.dart';
import 'menu_items_list_screen.dart'; // adjust path if needed
import '../../../core/widgets/global_notification_banner.dart';

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

  // theme color used in cards

  @override
  void initState() {
    super.initState();
    userPosition = widget.userPosition;
    displayStores = List<Shop>.from(widget.stores);

    // compute distances & sort if we have a user location
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
    builder: (_) => GlobalNotificationBanner(
      child: MenuScreen(
        userId: userId,
        shopId: shopId,
      ),
    ),
  ),
);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
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
              // refresh distances with user permission
              try {
                final permission = await Geolocator.requestPermission();
                if (permission == LocationPermission.denied ||
                    permission == LocationPermission.deniedForever) {
                  return;
                }
                final position = await Geolocator.getCurrentPosition(
                  locationSettings: const LocationSettings(
                    accuracy: LocationAccuracy.high,
                  ),
                );

                setState(() {
                  userPosition = position;
                });
                _computeDistancesAndSort();
              } catch (_) {}
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final shop = displayStores[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildStoreCard(shop),
                );
              },
              childCount: displayStores.length,
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
            color: Colors.black.withValues(alpha: 0.06), // Soft shadow
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
              _openMenuScreen(widget.userId, shop.id);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('This shop is closed. Opens at $opensText'),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // 1. SHOP IMAGE (Large & Rounded)
                Hero(
                  tag: 'shop_${shop.name}', // Optional animation tag
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
                        ? const Icon(Icons.store_rounded, size: 30, color: Colors.grey)
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
                      // Status Badge (Open/Closed)
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

                      // Location Row
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

                      // Time Row
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

  // Helper Widget for the "Open/Closed" Pill
  Widget _buildStatusBadge(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen
            ? const Color(0xFFE8F5E9)  // Light Green bg
            : const Color(0xFFFFEBEE), // Light Red bg
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          color: isOpen
              ? const Color(0xFF2E7D32) // Dark Green text
              : const Color(0xFFC62828), // Dark Red text
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  /// ---------------------------
  /// OPEN/CLOSED TIME LOGIC
  /// ---------------------------
  /// Returns structured result about open/closed and formatted times.
  _ShopOpenStatus _evaluateShopOpenStatus(String? openTimeStr, String? closeTimeStr) {
    // If either is missing — treat as open
    if ((openTimeStr == null || openTimeStr.trim().isEmpty) ||
        (closeTimeStr == null || closeTimeStr.trim().isEmpty)) {
      return _ShopOpenStatus(isOpen: true, opensAtFormatted: null, closesAtFormatted: null);
    }

    // parse both times into seconds-since-midnight
    final openSeconds = _parseTimeToSeconds(openTimeStr);
    final closeSeconds = _parseTimeToSeconds(closeTimeStr);
    if (openSeconds == null || closeSeconds == null) {
      // parse failed -> assume open
      return _ShopOpenStatus(isOpen: true, opensAtFormatted: null, closesAtFormatted: null);
    }

    final now = DateTime.now();
    final nowSeconds = now.hour * 3600 + now.minute * 60 + now.second;

    bool isOpen;
    // normal same-day window (open < close)
    if (openSeconds < closeSeconds) {
      isOpen = (nowSeconds >= openSeconds && nowSeconds < closeSeconds);
    } else if (openSeconds > closeSeconds) {
      // overnight window, e.g., open 20:00 -> close 04:00
      isOpen = (nowSeconds >= openSeconds) || (nowSeconds < closeSeconds);
    } else {
      // openSeconds == closeSeconds -> treat as open 24h
      isOpen = true;
    }

    final opensAtFormatted = _formatTimeString(openTimeStr);
    final closesAtFormatted = _formatTimeString(closeTimeStr);

    return _ShopOpenStatus(
      isOpen: isOpen,
      opensAtFormatted: opensAtFormatted,
      closesAtFormatted: closesAtFormatted,
    );
  }

  /// Parse "HH:mm:ss" or "HH:mm" into seconds since midnight.
  /// Returns null if parse fails.
  int? _parseTimeToSeconds(String? s) {
    if (s == null) return null;
    final trimmed = s.trim();
    if (trimmed.isEmpty) return null;

    final parts = trimmed.split(':');
    try {
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

  /// small public helper in case other parts call it
  String formatTime(String? s) {
    return _formatTimeString(s) ?? (s ?? '--:--');
  }
}

class _ShopOpenStatus {
  final bool isOpen;
  final String? opensAtFormatted;
  final String? closesAtFormatted;
  _ShopOpenStatus({required this.isOpen, this.opensAtFormatted, this.closesAtFormatted});
}
