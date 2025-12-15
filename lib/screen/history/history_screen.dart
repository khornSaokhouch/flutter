import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../server/order_service.dart';

/// Top-level helper to normalize possibly-relative image URLs.
String? _resolveImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) return url;

  const base = 'http://127.0.0.1:8000/'; // change to your API base
  if (url.startsWith('/')) return base + url.substring(1);
  return base + url;
}

class HistoryScreen extends StatefulWidget {
  final int userId;
  const HistoryScreen({required this.userId, super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  bool _isLoading = false;
  String? _error;
  List<OrderModel> _orders = [];

  // initial/full-page load vs pull-to-refresh
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      final orders = await OrderService.fetchAllOrders(userid: widget.userId);

      if (!mounted) return;

      setState(() {
        _orders = orders;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });

      // show a short snackbar to notify the user
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load orders: $_error')));
        }
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  /// Add a sample item to an order locally, and optionally persist.
  Future<void> _addSampleItemToOrder(OrderModel order) async {
    final newItemMap = {
      'id': 99,
      'name': 'Latte',
      'price': '4.50', // dollars -> 450 cents if your model converts
      'image_url': null,
    };

    setState(() {
      order.addItemFromItem(newItemMap, quantity: 1);
    });

    // If you have an API to persist this change, call it and handle errors.
  }

  OrderStatus _statusFromString(String? s) {
    final str = (s ?? '').toLowerCase();
    if (str.contains('pending')) return OrderStatus.pending;
    if (str.contains('paid')) return OrderStatus.paid;
    if (str.contains('prepar')) return OrderStatus.preparing;
    if (str.contains('ready')) return OrderStatus.ready;
    if (str.contains('complete')) return OrderStatus.completed;
    if (str.contains('cancel')) return OrderStatus.cancelled;
    if (str.contains('process')) return OrderStatus.processing;
    if (str.contains('upcom')) return OrderStatus.upcoming;
    return OrderStatus.pending;
  }

  String _formattedItemsText(OrderModel order) {
    if (order.orderItems.isEmpty) return 'No items';
    return order.orderItems.map((it) => '${it.quantity}x ${it.namesnapshot}').join(', ');
  }

  int _itemsCount(OrderModel order) {
    if (order.orderItems.isEmpty) return 0;
    return order.orderItems.fold<int>(0, (prev, it) => prev + it.quantity);
  }

  String _formatPriceFromCents(int cents) {
    final d = cents / 100.0;
    return d.toStringAsFixed(2);
  }

  List<OrderModel> get _pastOrders => _orders.where((o) => _statusFromString(o.status) != OrderStatus.upcoming).toList();
  List<OrderModel> get _upcomingOrders => _orders.where((o) => _statusFromString(o.status) == OrderStatus.upcoming).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text("HISTORY", style: TextStyle(color: _espressoBrown, fontWeight: FontWeight.w800, letterSpacing: 1.0, fontSize: 18)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey[200], height: 1)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey.shade200)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(color: _freshMintGreen, borderRadius: BorderRadius.circular(20)),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[500],
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              tabs: const [Tab(text: 'Past Orders'), Tab(text: 'Upcoming')],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Past Orders Tab
                RefreshIndicator(
                  onRefresh: () => _loadOrders(fromRefresh: true),
                  child: _buildOrdersListView(_pastOrders, emptyMessage: 'No past orders'),
                ),

                // Upcoming Tab
                RefreshIndicator(
                  onRefresh: () => _loadOrders(fromRefresh: true),
                  child: _buildOrdersListView(_upcomingOrders, emptyMessage: 'No Upcoming Orders'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersListView(List<OrderModel> orders, {required String emptyMessage}) {
    if (_isLoading && !_isRefreshing) {
      // full-page loading placeholder
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemBuilder: (_, __) => _buildLoadingPlaceholderCard(),
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemCount: 6,
      );
    }

    if (_error != null && orders.isEmpty) {
      return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [Center(child: Padding(padding: const EdgeInsets.all(28.0), child: Text('Error: $_error')))]);
    }

    if (orders.isEmpty) {
      return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [SizedBox(height: 60), _buildEmptyState()]);
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildOrderCard(orders[index]),
    );
  }

  Widget _buildLoadingPlaceholderCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6))]),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 14, color: Colors.grey[100]), const SizedBox(height: 8), Container(height: 12, width: 120, color: Colors.grey[100])])),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Container(height: 16, width: 60, color: Colors.grey[100]), const SizedBox(height: 8), Container(height: 12, width: 60, color: Colors.grey[100])])
          ]),
          const SizedBox(height: 12),
          Container(width: double.infinity, height: 20, color: Colors.grey[100]),
          const SizedBox(height: 12),
          Row(children: [Container(height: 30, width: 90, color: Colors.grey[100]), const Spacer(), Container(height: 30, width: 70, color: Colors.grey[100])])
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final statusEnum = _statusFromString(order.status);
    final itemsText = _formattedItemsText(order);
    final itemsCount = _itemsCount(order);
    final priceText = _formatPriceFromCents(order.totalcents);

    final String? rawImage = order.orderItems.isNotEmpty ? (order.orderItems.first.item?.imageUrl) : null;
    final String? imageUrl = _resolveImageUrl(rawImage);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderData: order))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6))]),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // IMAGE THUMBNAIL
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
                  clipBehavior: Clip.hardEdge,
                  child: imageUrl != null
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: 50,
                    height: 50,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)));
                    },
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_cafe_outlined, size: 28, color: Colors.grey),
                  )
                      : const Icon(Icons.local_cafe_outlined, size: 28, color: Colors.grey),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(order.orderItems.isNotEmpty ? order.orderItems.first.namesnapshot : 'Shop', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(order.placedat ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ]),
                ),

                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text("\$$priceText", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _espressoBrown)),
                  const SizedBox(height: 4),
                  Text("$itemsCount items", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ]),
              ]),

              const SizedBox(height: 12),

              Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: _bgGrey, borderRadius: BorderRadius.circular(8)), child: Text(itemsText, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey[700], fontStyle: FontStyle.italic))),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              Row(children: [
                _buildStatusBadge(statusEnum),
                const Spacer(),
                if (statusEnum == OrderStatus.completed) ...[
                  _buildActionButton(label: "Rate", textColor: Colors.black, bgColor: Colors.white, borderColor: Colors.grey.shade300, onTap: () {/* rate */}),
                  const SizedBox(width: 10),
                  _buildActionButton(label: "Reorder", textColor: Colors.white, bgColor: _freshMintGreen, borderColor: _freshMintGreen, onTap: () {
                    _addSampleItemToOrder(order);
                  }),
                ] else ...[
                  _buildActionButton(label: "Help", textColor: Colors.grey, bgColor: Colors.white, borderColor: Colors.grey.shade200, onTap: () {/* help */}),
                ]
              ])
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange.shade700;
        text = "Pending";
        icon = Icons.hourglass_empty_rounded;
        break;
      case OrderStatus.paid:
        color = Colors.green.shade700;
        text = "Paid";
        icon = Icons.payment_rounded;
        break;
      case OrderStatus.preparing:
        color = Colors.deepOrange;
        text = "Preparing";
        icon = Icons.kitchen_rounded;
        break;
      case OrderStatus.ready:
        color = Colors.blue.shade600;
        text = "Ready";
        icon = Icons.check_circle_outline;
        break;
      case OrderStatus.completed:
        color = _freshMintGreen;
        text = "Completed";
        icon = Icons.check_circle_rounded;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = "Cancelled";
        icon = Icons.cancel_rounded;
        break;
      case OrderStatus.processing:
        color = Colors.orange;
        text = "Processing";
        icon = Icons.access_time_filled_rounded;
        break;
      case OrderStatus.upcoming:
        color = Colors.blue;
        text = "Upcoming";
        icon = Icons.schedule_rounded;
        break;
    }

    return Row(children: [Icon(icon, color: color, size: 16), const SizedBox(width: 6), Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))]);
  }

  Widget _buildActionButton({required String label, required Color textColor, required Color bgColor, required Color borderColor, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor)),
          child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: Icon(Icons.receipt_long_rounded, size: 50, color: Colors.grey[300])),
        const SizedBox(height: 20),
        Text("No Upcoming Orders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _espressoBrown)),
        const SizedBox(height: 8),
        const Text("Looks like you don't have any\nactive orders right now.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 30),
        ElevatedButton(onPressed: () {/* go home */}, style: ElevatedButton.styleFrom(backgroundColor: _freshMintGreen, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)), child: const Text("Start Ordering", style: TextStyle(fontWeight: FontWeight.bold))),
      ]),
    );
  }
}

enum OrderStatus { pending, paid, preparing, ready, completed, cancelled, processing, upcoming }

class OrderDetailScreen extends StatelessWidget {
  final OrderModel orderData;
  const OrderDetailScreen({required this.orderData, super.key});

  @override
  Widget build(BuildContext context) {
    final statusText = orderData.status;
    final price = (orderData.totalcents / 100.0).toStringAsFixed(2);
    final itemsText = orderData.orderItems.isNotEmpty ? orderData.orderItems.map((i) => '${i.quantity}x ${i.namesnapshot}').join(', ') : 'No items';

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details'), backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Order #${orderData.id ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Text("Placed at: ${orderData.placedat ?? ''}"),
            const SizedBox(height: 8),
            Text("Status: $statusText"),
            const SizedBox(height: 8),
            Text("Items: $itemsText"),
            const SizedBox(height: 8),
            Text("Total: \$$price"),
            const SizedBox(height: 16),
            if (orderData.orderItems.isNotEmpty)
              ...orderData.orderItems.map((it) {
                final imageUrl = _resolveImageUrl(it.item?.imageUrl);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[50]),
                    clipBehavior: Clip.hardEdge,
                    child: imageUrl != null ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.local_cafe_outlined)) : const Icon(Icons.local_cafe_outlined),
                  ),
                  title: Text('${it.quantity} x ${it.namesnapshot}'),
                  subtitle: Text('\$${(it.unitpriceCents / 100.0).toStringAsFixed(2)}'),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}
