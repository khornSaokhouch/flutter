// all_orders_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../server/order_service.dart';
import '../history/history_screen.dart';

class AllOrdersScreen extends StatefulWidget {
  final int userId;

  const AllOrdersScreen({required this.userId, super.key});

  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  // UI state
  bool _isLoading = true;
  String? _error;
  List<OrderModel> _orders = [];

  // search field (local filtering)
  String _searchQuery = '';

  final _currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);


  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await OrderService.fetchAllOrders(userid: widget.userId);
      setState(() {
        _orders = orders;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Local search filter (search by order id, shop id, or item name)
  List<OrderModel> get _filteredOrders {
    if (_searchQuery.trim().isEmpty) return _orders;
    final q = _searchQuery.toLowerCase();
    return _orders.where((o) {
      final idMatch = o.id != null && o.id.toString().toLowerCase().contains(q);
      final shopIdMatch = o.shopid != null && o.shopid.toString().toLowerCase().contains(q);
      final itemNameMatch = o.orderItems.any((it) =>
      it.namesnapshot.toLowerCase().contains(q) ||
          (it.optionGroups.any((g) => g.selectedOption.toLowerCase().contains(q))));
      return idMatch || shopIdMatch || itemNameMatch;
    }).toList();
  }

  // Formats cents -> dollars (or your currency)
  String _formatMoney(int cents) {
    final dollars = cents / 100.0;
    // prefer NumberFormat for localization
    return _currencyFormatter.format(dollars);
  }

  // Try to parse a date string robustly and format it
  String _formatPlacedAt(String? placedAtRaw) {
    if (placedAtRaw == null || placedAtRaw.trim().isEmpty) return '—';
    try {
      // Try standard ISO first
      DateTime? dt;
      dt = DateTime.tryParse(placedAtRaw);
      if (dt == null) {
        // Try common fallbacks (trim timezone spaces)
        final cleaned = placedAtRaw.replaceAll(' ', 'T');
        dt = DateTime.tryParse(cleaned);
      }
      if (dt == null) {
        // As a last resort don't throw — return original short substring
        return placedAtRaw.length > 16 ? placedAtRaw.substring(0, 16) : placedAtRaw;
      }
      // Use localized readable format
      return DateFormat.yMMMd().add_jm().format(dt.toLocal());
    } catch (_) {
      return placedAtRaw;
    }
  }

  // List<OrderModel> get _filteredOrders {
  //   final q = _searchQuery.toLowerCase();
  //
  //   return _orders.where((o) {
  //     final matchesSearch = q.isEmpty ||
  //         (o.id?.toString().contains(q) ?? false) ||
  //         (o.shopid?.toString().contains(q) ?? false) ||
  //         o.orderItems.any((i) =>
  //             i.namesnapshot.toLowerCase().contains(q));
  //
  //     final matchesStatus =
  //         _selectedStatuses.isEmpty ||
  //             _selectedStatuses.contains(o.status.toLowerCase());
  //
  //     return matchesSearch && matchesStatus;
  //   }).toList();
  // }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 1. App Bar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "ORDER HISTORY",
          style: TextStyle(
            color: _espressoBrown,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            fontSize: 16,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[100], height: 1),
        ),
      ),

      body: Column(
        children: [
          // 2. Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: _bgGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: "Search by Order ID, Shop ID, or item...",
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  child: Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      color: _freshMintGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _freshMintGreen.withOpacity(0.3)),
                    ),
                    child: Icon(Icons.tune_rounded, color: _freshMintGreen),
                  ),
                ),

              ],
            ),
          ),

          // 3. Content: loading / error / list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Builder(builder: (context) {
                if (_isLoading) {
                  return Center(child: CircularProgressIndicator(color: _freshMintGreen));
                }

                if (_error != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Failed to load orders', style: TextStyle(fontSize: 16, color: Colors.red)),
                        const SizedBox(height: 8),
                        Text(_error!, style: TextStyle(color: Colors.grey[700])),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadOrders,
                          style: ElevatedButton.styleFrom(backgroundColor: _freshMintGreen),
                          child: const Text('Retry'),
                        )
                      ],
                    ),
                  );
                }

                final list = _filteredOrders;
                if (list.isEmpty) {
                  return Center(child: Text('No orders found', style: TextStyle(color: Colors.grey[600])));
                }

                // Add pull-to-refresh + better list keys
                return RefreshIndicator(
                  color: _freshMintGreen,
                  onRefresh: _loadOrders,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    padding: const EdgeInsets.only(top: 8, bottom: 32),
                    itemBuilder: (context, idx) {
                      final order = list[idx];
                      return KeyedSubtree(
                        key: ValueKey(order.id ?? idx),
                        child: _buildOrderTileFromModel(order),
                      );
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTileFromModel(OrderModel order) {
    final bool isCompleted = order.status.toLowerCase() == "completed";
    final shopLabel = order.shopid != null ? 'Shop #${order.shopid}' : 'Shop -';
    final orderLabel = order.id != null ? 'Order #${order.id}' : null;
    final titleText = orderLabel != null ? '$orderLabel • $shopLabel' : shopLabel;

    final itemsText = order.orderItems.isNotEmpty
        ? '${order.orderItems.length} item(s): ${order.orderItems.map((i) => i.namesnapshot).take(2).join(", ")}'
        : 'No items';
    final displayDate = _formatPlacedAt(order.placedat);
    final price = _formatMoney(order.totalcents);

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(order: order),
            ),
          );
        },
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _bgGrey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: isCompleted ? _freshMintGreen : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // title + price
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              titleText,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            price,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: _espressoBrown,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        itemsText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Text(
                            displayDate,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? _freshMintGreen.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isCompleted ? _freshMintGreen : Colors.red,
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Reorder section (only for completed)
            if (isCompleted) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Colors.grey[100]),
              ),
              InkWell(
                onTap: () {
                  // Handle reorder tap (e.g. Navigator.push to reorder screen)
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, size: 16, color: _freshMintGreen),
                    const SizedBox(width: 6),
                    Text(
                      "Reorder Again",
                      style: TextStyle(
                        color: _freshMintGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}
