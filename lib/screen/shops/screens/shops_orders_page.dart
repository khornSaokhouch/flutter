import 'package:flutter/material.dart';
import '../../../models/order_model.dart';
import '../../../server/order_service.dart';
import '../../user/store_screen/order_detail_screen.dart';
import '../../../core/widgets/loading/logo_loading.dart';

class ShopsOrdersPage extends StatefulWidget {
  final int shopId;
  const ShopsOrdersPage({super.key, required this.shopId});

  @override
  State<ShopsOrdersPage> createState() => _ShopsOrdersPageState();
}

class _ShopsOrdersPageState extends State<ShopsOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Brand Colors ---
  final Color _deepGreen = const Color(0xFF1B4332);
  final Color _emerald = const Color(0xFF2D6A4F);
  final Color _mint = const Color(0xFF52B788);
  final Color _softBg = const Color(0xFFF7F9F8);

  bool _isLoading = true;
  List<OrderModel> _orders = [];
  final Map<int, bool> _orderBusy = {};
  final OrderService _orderService = OrderService();

  // Tabs organized by shop workflow
  final List<String> _tabs = ['New', 'Preparing', 'Ready', 'History'];

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
    });
    try {
      final orders =
          await OrderService.fetchAllOrdersForShop(shopid: widget.shopId);
      setState(() => _orders = orders);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(OrderModel order, String newStatus) async {
    if (order.id == null) return;
    setState(() => _orderBusy[order.id!] = true);
    try {
      final updated =
          await _orderService.updateOrder(order.id!, {'status': newStatus});
      setState(() {
        final idx = _orders.indexWhere((o) => o.id == order.id);
        if (idx != -1) _orders[idx] = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Order #${order.id} is now $newStatus"),
            backgroundColor: _emerald),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _orderBusy.remove(order.id));
    }
  }

  void _goToOrderDetails(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderData: {
            // ---- order ----
            'id': order.id,
            'status': order.status,
            'placedat': order.placedat,

            // ---- money (cents) ----
            'subtotalcents': order.subtotalcents,
            'discountcents': order.discountcents,
            'totalcents': order.totalcents,

            // ---- shop ----
            'shop_id': order.shopid,
            'shop_name': order.shop?.name,

            // ---- items ----
            'items': order.orderItems.map((e) {
              final imageUrl = e.item?.imageUrl ?? '';

              return {
                'name': e.namesnapshot,
                'pricecents': e.unitpriceCents,
                'quantity': e.quantity,
                'notes': e.notes,
                'image_url': imageUrl,

                'option_groups':
                e.optionGroups.map((g) => g.toJson()).toList(),
              };
            }).toList(),
          },
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "SHOP DASHBOARD",
          style: TextStyle(
            color: _deepGreen,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _emerald,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _emerald,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LogoLoading(size: 60),
                  const SizedBox(height: 12),
                  Text(
                    'Loading orders...',
                    style: TextStyle(
                      color: _emerald,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) => _buildOrderList(tab)).toList(),
            ),
    );
  }

  Widget _buildOrderList(String tabName) {
    final filtered = _orders.where((o) {
      final s = o.status.toLowerCase();
      if (tabName == 'New') return s == 'pending' || s == 'paid';
      if (tabName == 'Preparing') return s == 'preparing';
      if (tabName == 'Ready') return s == 'ready';
      if (tabName == 'History') return s == 'completed' || s == 'cancelled';
      return false;
    }).toList();

    if (filtered.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: _emerald,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _buildOrderCard(filtered[index]),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final bool isBusy = _orderBusy[order.id] ?? false;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _goToOrderDetails(order), // ✅ navigate
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Column(
                children: [
                  _buildCardHeader(order),
                  _buildCardBody(order),
                  _buildCardActions(order),
                ],
              ),
              if (isBusy)
                Positioned.fill(
                  child: Container(
                    color: Colors.white70,
                    child: Center(
                      child: CircularProgressIndicator(color: _emerald),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(OrderModel order) {
    Color statusColor = _emerald;
    if (order.status == 'pending' || order.status == 'paid') {
      statusColor = Colors.orange;
    }
    if (order.status == 'cancelled') statusColor = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: _softBg.withValues(alpha: 0.5)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text("#${order.id}",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: _deepGreen)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Text(order.status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Text(_formatTime(order.placedat),
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCardBody(OrderModel order) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: _mint.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(Icons.receipt_long_outlined, color: _emerald),
      ),
       title: Text("Customer #${order.user?.name ?? 'Unknown'}",
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
          "${order.orderItems.length} items • ${order.orderItems.map((e) => e.namesnapshot).join(', ')}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: Text("\$${(order.totalcents / 100).toStringAsFixed(2)}",
          style: TextStyle(
              color: _emerald, fontWeight: FontWeight.w900, fontSize: 16)),
    );
  }

  Widget _buildCardActions(OrderModel order) {
    final s = order.status.toLowerCase();

    // Only show actions for active statuses
    if (s == 'completed' || s == 'cancelled') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          if (s == 'pending' || s == 'paid') ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateStatus(order, 'cancelled'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Decline"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStatus(order, 'preparing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _emerald,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Accept"),
              ),
            ),
          ],
          if (s == 'preparing')
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStatus(order, 'ready'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mint,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Mark as Ready"),
              ),
            ),
          if (s == 'ready')
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStatus(order, 'completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _deepGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Order Completed"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco_outlined, size: 60, color: _mint.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          const Text("No orders found in this section",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatTime(String? date) {
    if (date == null) return "";
    final dt = DateTime.parse(date);
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
