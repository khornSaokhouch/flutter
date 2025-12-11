import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../../models/shop.dart';
import 'menu_items_list_screen.dart'; // adjust path if needed

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
  final Color _freshMintGreen = const Color(0xFF4E8D7C);

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
        builder: (_) => MenuScreen(userId: userId, shopId: shopId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
              // refresh distances with user permission
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
          return _buildStoreCard(shop);
        },
      ),
    );
  }

  Widget _buildStoreCard(Shop shop) {
    final imageUrl = shop.imageUrl ?? '';
    final distanceStr = shop.distanceInKm != null
        ? shop.distanceInKm!.toStringAsFixed(2)
        : '--';

    // Evaluate open/closed using openTime / closeTime (if provided)
    final shopStatus = _evaluateShopOpenStatus(shop.openTime, shop.closeTime);
    final bool isOpen = shopStatus.isOpen;

    final opensText = shopStatus.opensAtFormatted ?? formatTime(shop.openTime);
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
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    _openMenuScreen(widget.userId, shop.id);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('This shop is closed. Opens at $opensText'),
                      ),
                    );
                  }
                },
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
                            : Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey[200],
                          child: const Icon(Icons.store_rounded,
                              color: Colors.grey, size: 40),
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
                            // opening hours + status
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '$opensText - $closesText',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                    isOpen ? Colors.green[50] : Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isOpen ? 'Open' : 'Closed',
                                    style: TextStyle(
                                      color: isOpen ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
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
            ),
          ),
        ),

        // --------------------------------------------------
        // FULL OVERLAY WHEN CLOSED - centered
        // --------------------------------------------------
        if (!isOpen)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(12),
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
