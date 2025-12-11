import 'package:flutter/material.dart';

import '../../../models/order_model.dart';
import '../../../server/order_service.dart';

class ShopsOrdersPage extends StatefulWidget {
  final int shopId;
  const ShopsOrdersPage({super.key, required this.shopId});

  @override
  State<ShopsOrdersPage> createState() => _ShopsOrdersPageState();
}

class _ShopsOrdersPageState extends State<ShopsOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  bool _isLoading = true;
  String? _error;
  List<OrderModel> _orders = [];

  // search field (local filtering)

  // tabs
  final List<String> _tabs = ['Pending', 'Preparing', 'Ready', 'History'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders =
      await OrderService.fetchAllOrdersForShop(shopid: widget.shopId);
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

  // helper to format cents -> currency string
  String _formatMoney(int cents) {
    final dollars = cents / 100.0;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  // simple formatter for placedat (you can replace with your own)
  String _formatPlacedAt(String? placedAt) {
    if (placedAt == null || placedAt.isEmpty) return '-';
    try {
      final dt = DateTime.parse(placedAt);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return placedAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button for dashboard tabs
        title: Text(
          "INCOMING ORDERS",
          style: TextStyle(
              color: _espressoBrown,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 1.0),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _freshMintGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _freshMintGreen,
          isScrollable: true,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadOrders,
                child: const Text('Retry'),
              ),
            ],
          ))
          : TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) => _buildOrderList(tab)).toList(),
      ),
    );
  }

  Widget _buildOrderList(String statusFilter) {
    // Filter by model fields (not Map)
    final filtered = _orders.where((o) {
      if (statusFilter == "History") return true; // all for demo
      return o.status.toLowerCase() == statusFilter.toLowerCase();
    }).toList();

    if (filtered.isEmpty) return _buildEmptyState();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final order = filtered[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final String status = order.status;
    Color statusColor;
    if (status.toLowerCase() == 'pending') statusColor = Colors.orange;
    else if (status.toLowerCase() == 'preparing') statusColor = Colors.blue;
    else statusColor = _freshMintGreen;

    final idText = order.id != null ? '#${order.id}' : '—';
    final timeText = _formatPlacedAt(order.placedat);
    final itemsText = order.orderItems.isNotEmpty
        ? '${order.orderItems.length} item(s): ${order.orderItems.map((i) => i.namesnapshot).take(2).join(", ")}'
        : 'No items';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // navigate to detail screen; replace with your screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreenPlaceholder(order: order),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(status,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Text(idText,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _espressoBrown,
                              fontSize: 16)),
                    ],
                  ),
                  Text(timeText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.receipt_long, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // fallback to user id if no customer name
                          'Customer ${order.userid}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(itemsText,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 8),
                        Text(
                          _formatMoney(order.totalcents),
                          style: TextStyle(
                              color: _freshMintGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions (only for Pending / Preparing)
            if (status.toLowerCase() == 'pending')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // implement decline
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Decline"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // implement accept
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _freshMintGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text("Accept"),
                      ),
                    ),
                  ],
                ),
              ),

            if (status.toLowerCase() == 'preparing')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // implement mark as ready
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _espressoBrown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text("Mark as Ready"),
                  ),
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
          Icon(Icons.inbox_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No orders found", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

/// Placeholder detail screen — replace with your real screen.
class OrderDetailScreenPlaceholder extends StatelessWidget {
  final OrderModel order;
  const OrderDetailScreenPlaceholder({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${order.id ?? ''}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${order.status}'),
            const SizedBox(height: 8),
            Text('Total: \$${(order.totalcents / 100.0).toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Items: ${order.orderItems.length}'),
          ],
        ),
      ),
    );
  }
}
