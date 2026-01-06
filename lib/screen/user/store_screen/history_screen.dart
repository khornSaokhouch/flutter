import 'dart:async';

import 'package:flutter/material.dart';
import '../../../models/order_model.dart';
import '../../../server/order_service.dart';

import 'order_detail_screen.dart';
import '../../../server/notification_service.dart';
import '../../../core/widgets/style_overlay_banner.dart';

// --- Helper: Resolve Image URL ---
String? _resolveImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) return url;
  const base = 'http://127.0.0.1:8000/'; // Change to your API base
  if (url.startsWith('/')) return base + url.substring(1);
  return base + url;
}

class HistoryScreen extends StatefulWidget {
  final int userId;
  const HistoryScreen({required this.userId, super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);
  final Color _textGrey = const Color(0xFF8A8A8E);

  bool _isLoading = false;
  String? _error;
  List<OrderModel> _orders = [];
  bool _isRefreshing = false;

  OverlayEntry? _bannerEntry;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _initNotifications(); // ✅ start listening
  }


  Future<void> _loadOrders({bool fromRefresh = false}) async {
    if (fromRefresh) {
      setState(() => _isRefreshing = true);
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final allOrders =
          await OrderService.fetchAllOrders(userid: widget.userId);

      if (!mounted) return;

      setState(() {
        _orders = allOrders;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  // --- Filter Logic: ONLY Completed ---
  List<OrderModel> get _completedOrders {
    return _orders.where((o) {
      final status = (o.status).toLowerCase();
      // Strictly checking for completed statuses
      return status.contains('ready') ||
          status.contains('completed') ||
          status.contains('complete');
    }).toList();
  }

  String _formattedItemsText(OrderModel order) {
    if (order.orderItems.isEmpty) return 'No items';
    return order.orderItems
        .map((it) => '${it.quantity}x ${it.namesnapshot}')
        .join(', ');
  }

  int _itemsCount(OrderModel order) {
    if (order.orderItems.isEmpty) return 0;
    return order.orderItems.fold<int>(0, (prev, it) => prev + it.quantity);
  }

    // ====================================================
  // NOTIFICATIONS
  // ====================================================
void _initNotifications() {
  NotificationService().init(
    onMessage: (title, body) {
      if (!mounted) return;
      _showTopBanner(title, body);
    },
  );
}

  void _showTopBanner(String title, String body) {
  _removeTopBanner();

  _bannerEntry = OverlayEntry(
    builder: (context) {
      final topPadding = MediaQuery.of(context).padding.top;

      return Positioned(
        top: topPadding + 12,
        left: 16,
        right: 16,
        child: TopBanner(
          title: title,
          body: body,
          onClose: _removeTopBanner,
        ),
      );
    },
  );

  final overlay = Overlay.of(context, rootOverlay: true);

  overlay.insert(_bannerEntry!);

  _bannerTimer = Timer(
    const Duration(seconds: 4),
    _removeTopBanner,
  );
}


  void _removeTopBanner() {
    _bannerTimer?.cancel();
    _bannerTimer = null;

    _bannerEntry?.remove();
    _bannerEntry = null;
  }
@override
void dispose() {
  _bannerTimer?.cancel();
  _bannerEntry?.remove();
  NotificationService().dispose(); // ✅ stop listening
  super.dispose();
}


  @override
  Widget build(BuildContext context) {
    final displayOrders = _completedOrders;

    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            "Completed Orders",
            style: TextStyle(
              color: _espressoBrown,
              fontWeight: FontWeight.w800,
              fontSize: 24,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: _freshMintGreen,
        backgroundColor: Colors.white,
        onRefresh: () => _loadOrders(fromRefresh: true),
        child: _buildBody(displayOrders),
      ),
    );
  }

  Widget _buildBody(List<OrderModel> orders) {
    if (_isLoading && !_isRefreshing) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        itemBuilder: (_, __) => _buildShimmerLoadingCard(),
      );
    }

    if (_error != null && orders.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(
            child: Text(
              'Could not load history.\n$_error',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textGrey),
            ),
          )
        ],
      );
    }

    if (orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          _buildEmptyState(),
        ],
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) => _buildOrderCard(orders[index]),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final itemsText = _formattedItemsText(order);
    final itemsCount = _itemsCount(order);
    final priceText = (order.totalcents / 100.0).toStringAsFixed(2);

    final String? rawImage = order.orderItems.isNotEmpty
        ? order.orderItems.first.item?.imageUrl
        : null;
    final String? imageUrl = _resolveImageUrl(rawImage);

    final String shopName = order.orderItems.isNotEmpty
        ? order.orderItems.first.namesnapshot
        : "Order";

    /// ✅ Convert OrderModel → Map<String, dynamic>
    final Map<String, dynamic> orderData = order.toJson();

    return InkWell(
      borderRadius: BorderRadius.circular(24),

      // ✅ SINGLE InkWell with correct navigation
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderData: orderData),
          ),
        );
      },

      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // --- Top Section ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Image
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _bgGrey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                                Icons.check_circle,
                                color: _freshMintGreen),
                          )
                        : Icon(Icons.check_circle, color: _freshMintGreen),
                  ),

                  const SizedBox(width: 16),

                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _espressoBrown,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.placedat ?? 'Unknown Date',
                          style: TextStyle(
                            fontSize: 13,
                            color: _textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "\$$priceText",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _freshMintGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$itemsCount Items",
                        style: TextStyle(
                          fontSize: 12,
                          color: _textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: Colors.grey[100]),
            ),

            // Items summary
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.receipt_long, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      itemsText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: _freshMintGreen),
                        const SizedBox(width: 6),
                        Text(
                          "Completed",
                          style: TextStyle(
                            color: _freshMintGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "Details",
                        style: TextStyle(
                          color: _textGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Colors.grey[400]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Icon(Icons.history_edu, size: 48, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          Text(
            "No Completed Orders",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _espressoBrown),
          ),
          const SizedBox(height: 8),
          Text(
            "Once you complete an order,\nit will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoadingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: _bgGrey, borderRadius: BorderRadius.circular(16))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 120, height: 16, color: _bgGrey),
                const SizedBox(height: 8),
                Container(width: 80, height: 12, color: _bgGrey),
                const SizedBox(height: 30),
                Container(width: double.infinity, height: 12, color: _bgGrey),
              ],
            ),
          )
        ],
      ),
    );
  }
}
