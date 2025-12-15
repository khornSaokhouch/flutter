// lib/screen/order/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/format_utils.dart';
import '../widget/item_row.dart';
import '../widget/status_header.dart';
import '../widget/timeline_sheet.dart';


class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailScreen({super.key, required this.orderData});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // currency formatter
  final NumberFormat _moneyFmt =
  NumberFormat.currency(locale: 'en_US', symbol: '\$');

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _parseAmount(dynamic v, {bool centsIfInt = true}) =>
      parseAmountToDollars(v, inputIsCentsIfInt: centsIfInt);

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = widget.orderData;

    // --- extraction using utils
    final int id = parseIntSafe(data['id']);
    final int shopId = parseIntSafe(data['shop_id'] ?? data['shopid']);
    final String shopName = (data['shop_name'] ??
        data['shopName'] ??
        data['name'] ??
        (data['shop'] is Map ? data['shop']['name'] : null) ??
        '')
        .toString();
    final String displayShopName = shopName.isNotEmpty ? shopName : 'Store #$shopId';

    (data['notes'] ?? data['note'] ?? '').toString();

    final double subtotal = data.containsKey('subtotal')
        ? _parseAmount(data['subtotal'], centsIfInt: false)
        : _parseAmount(data['subtotalcents'] ?? data['subtotal_cents']);
    final double total = data.containsKey('total')
        ? _parseAmount(data['total'], centsIfInt: false)
        : _parseAmount(data['totalcents'] ?? data['total_cents']);

    final List<dynamic> items =
    (data['items'] ?? data['order_items'] ?? data['orderItems'] ?? []) as List<dynamic>;
    final String rawStatus = (data['status'] ?? 'placed').toString().toLowerCase();
    final String placedAtRaw =
    (data['placedat'] ?? data['placed_at'] ?? data['placedAt'] ?? '').toString();
    print(data);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _freshMintGreen, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              "ORDER DETAILS",
              style: TextStyle(color: _espressoBrown, fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              "Pick up at $displayShopName",
              style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Status header (from separate widget)
                StatusHeader(
                  status: rawStatus,
                  freshMintGreen: _freshMintGreen,
                  espressoBrown: _espressoBrown,
                  onTap: () => _showTrackingSheet(context, rawStatus),
                ),

                const SizedBox(height: 30),
                Container(height: 8, color: _bgGrey),

                // Details List
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Details", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: _bgGrey, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                            child: Text("#$id", style: TextStyle(fontWeight: FontWeight.bold, color: _espressoBrown)),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),

                      _infoRow("Order #", "P-${id.toString().padLeft(5, '0')}"),
                      const SizedBox(height: 8),
                      _infoRow("Store", displayShopName),
                      if (placedAtRaw.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _infoRow("Placed at", formatPlacedAt(placedAtRaw)),
                      ],

                      const SizedBox(height: 24),

                      // Items
                      ...items.map((item) => ItemRow(item: item, moneyFmt: _moneyFmt)).toList(),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(thickness: 1, height: 1),
                      ),

                      // Totals
                      _priceRow("Subtotal", subtotal),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total", style: TextStyle(color: _espressoBrown, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text(_moneyFmt.format(total), style: TextStyle(color: _freshMintGreen, fontSize: 22, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () => _showTrackingSheet(context, rawStatus),
            style: ElevatedButton.styleFrom(
              backgroundColor: _freshMintGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 4,
              shadowColor: _freshMintGreen.withOpacity(0.4),
            ),
            child: const Text("Track Order Status", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
        Flexible(
          child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, color: _espressoBrown, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _priceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500, fontSize: 15)),
        Text(_moneyFmt.format(amount), style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500, fontSize: 15)),
      ],
    );
  }

  void _showTrackingSheet(BuildContext context, String currentStatus) {
    showTrackingSheet(context, currentStatus, freshMintGreen: _freshMintGreen, espressoBrown: _espressoBrown);
  }
}
