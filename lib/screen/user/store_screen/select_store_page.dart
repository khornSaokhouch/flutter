import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/utils.dart';
import '../../../models/shop.dart';
import '../../../core/widgets/loading/logo_loading.dart';
import '../../../core/widgets/global_notification_banner.dart';
import 'menu_items_list_screen.dart';
import '../../guest/guest_store_screen/guest_store_map.dart';


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

  bool _loadingDistances = false;

  @override
  void initState() {
    super.initState();
    userPosition = widget.userPosition;
    displayStores = List<Shop>.from(widget.stores);

    if (userPosition != null) {
      _computeDistancesAndSort();
    }
  }

void _computeDistancesAndSort() {
  if (userPosition == null) return;

  for (final shop in displayStores) {
    if (shop.latitude != null && shop.longitude != null) {
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
    final da = a.distanceInKm ?? double.infinity;
    final db = b.distanceInKm ?? double.infinity;
    return da.compareTo(db);
  });

  /// 🔑 FORCE UI REFRESH
  setState(() {});
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
          onPressed: () {},
        ),
        IconButton(
          icon: _loadingDistances
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.location_on_outlined, color: Colors.grey),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GuestStoreMapPage(
                  shops: widget.stores,
                  initialPosition: userPosition,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    ),

    /// 🔑 UI IS UNCHANGED BELOW
    body: Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final shop = displayStores[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: _buildStoreCard(shop),
                  );
                },
                childCount: displayStores.length,
              ),
            ),
          ],
        ),

        /// ✅ Loader overlay (does NOT affect layout)
        if (_loadingDistances)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.white70,
              child: Center(
                child: LogoLoading(size: 60),
              ),
            ),
          ),
      ],
    ),
  );
}

  Widget _buildStoreCard(Shop shop) {
    final shopStatus =
        _evaluateShopOpenStatus(shop.openTime, shop.closeTime);
    final bool isOpen = shopStatus.isOpen;
    final opensText =
        shopStatus.opensAtFormatted ?? formatTime(shop.openTime);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
              children: [
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[200],
                    image: (shop.imageUrl != null &&
                            shop.imageUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(shop.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (shop.imageUrl == null ||
                          shop.imageUrl!.isEmpty)
                      ? const Icon(Icons.store_rounded,
                          size: 30, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shop.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusBadge(isOpen),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        shop.location ?? 'No location info',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (shop.openTime != null &&
                                shop.closeTime != null)
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          color: isOpen
              ? const Color(0xFF2E7D32)
              : const Color(0xFFC62828),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  _ShopOpenStatus _evaluateShopOpenStatus(
      String? openTimeStr, String? closeTimeStr) {
    if (openTimeStr == null || closeTimeStr == null) {
      return _ShopOpenStatus(isOpen: true);
    }

    final openSeconds = _parseTimeToSeconds(openTimeStr);
    final closeSeconds = _parseTimeToSeconds(closeTimeStr);

    if (openSeconds == null || closeSeconds == null) {
      return _ShopOpenStatus(isOpen: true);
    }

    final now = DateTime.now();
    final nowSeconds =
        now.hour * 3600 + now.minute * 60 + now.second;

    final isOpen = openSeconds < closeSeconds
        ? nowSeconds >= openSeconds && nowSeconds < closeSeconds
        : nowSeconds >= openSeconds || nowSeconds < closeSeconds;

    return _ShopOpenStatus(
      isOpen: isOpen,
      opensAtFormatted: _formatTimeString(openTimeStr),
      closesAtFormatted: _formatTimeString(closeTimeStr),
    );
  }

  int? _parseTimeToSeconds(String? s) {
    if (s == null) return null;
    final parts = s.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 3600 + m * 60;
  }

  String? _formatTimeString(String? s) {
    final seconds = _parseTimeToSeconds(s);
    if (seconds == null) return null;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return DateFormat.jm().format(DateTime(2000, 1, 1, h, m));
  }

  String formatTime(String? s) =>
      _formatTimeString(s) ?? (s ?? '--:--');
}

class _ShopOpenStatus {
  final bool isOpen;
  final String? opensAtFormatted;
  final String? closesAtFormatted;

  _ShopOpenStatus({
    required this.isOpen,
    this.opensAtFormatted,
    this.closesAtFormatted,
  });
}
