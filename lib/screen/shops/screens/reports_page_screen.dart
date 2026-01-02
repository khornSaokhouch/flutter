import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/order_model.dart';
import '../../../server/order_service.dart';

class ReportsPage extends StatefulWidget {
  final int shopId;

  const ReportsPage({super.key, required this.shopId});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // --- Premium Emerald Theme Palette ---
  final Color _deepGreen = const Color(0xFF1B4332);
  final Color _emerald = const Color(0xFF2D6A4F);
  final Color _mint = const Color(0xFF52B788);
  final Color _softBg = const Color(0xFFF8FAF9);

  late Future<List<OrderModel>> _ordersFuture;
  String _selectedFilter = "This Week";

  @override
  void initState() {
    super.initState();
    // Fetch data once when page loads
    _ordersFuture = OrderService.fetchAllOrdersForShop(shopid: widget.shopId);
  }

  // --- Filtering Logic ---
  List<OrderModel> _getFilteredOrders(List<OrderModel> allOrders) {
    final now = DateTime.now();
    return allOrders.where((order) {
      if (order.placedat == null) return false;
      try {
        final orderDate = DateTime.parse(order.placedat!);

        switch (_selectedFilter) {
          case "Today":
            return orderDate.year == now.year &&
                orderDate.month == now.month &&
                orderDate.day == now.day;
          case "This Week":
          // Orders within the last 7 days
            final sevenDaysAgo = now.subtract(const Duration(days: 7));
            return orderDate.isAfter(sevenDaysAgo);
          case "This Month":
            return orderDate.year == now.year && orderDate.month == now.month;
          default:
            return true;
        }
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // --- Calculations ---
  double _calculateSales(List<OrderModel> orders) {
    return orders.fold(0.0, (sum, item) => sum + (item.totalcents)) / 100.0;
  }

  int _calculateRefunds(List<OrderModel> orders) {
    return orders.where((o) => o.status.toLowerCase() == 'refunded').length;
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
          "REPORTS & ANALYTICS",
          style: TextStyle(
            color: _deepGreen,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        iconTheme: IconThemeData(color: _deepGreen),
      ),
      body: FutureBuilder<List<OrderModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _emerald));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading data", style: TextStyle(color: _deepGreen)));
          }

          final allOrders = snapshot.data ?? [];
          final filteredOrders = _getFilteredOrders(allOrders);

          final double totalSales = _calculateSales(filteredOrders);
          final int totalOrders = filteredOrders.length;
          final int refunds = _calculateRefunds(filteredOrders);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header & Date Filter ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Business Overview",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _deepGreen),
                    ),
                    _buildFilterDropdown(),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Stat Cards Grid ---
                Row(
                  children: [
                    Expanded(child: _buildStatCard("Total Sales", "\$${totalSales.toStringAsFixed(2)}", Icons.payments_outlined, false)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildStatCard("Orders", "$totalOrders", Icons.shopping_cart_outlined, false)),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildStatCard("Customers", "$totalOrders", Icons.analytics_outlined, false)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildStatCard("Refunds", "$refunds", Icons.assignment_return_outlined, false, isNegative: true)),
                  ],
                ),

                const SizedBox(height: 32),

                // --- Sales Trend Section ---
                Text(
                  "Sales Trend",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _deepGreen),
                ),
                const SizedBox(height: 12),
                _buildTrendPlaceholder(),

                const SizedBox(height: 32),

                // --- Recent Transactions ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recent Transactions",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _deepGreen),
                    ),
                    Icon(Icons.history_toggle_off, color: _emerald, size: 20),
                  ],
                ),
                const SizedBox(height: 12),

                // Transaction List
                filteredOrders.isEmpty
                    ? Center(child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text("No transactions for this period", style: TextStyle(color: Colors.grey[400])),
                ))
                    : ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: filteredOrders.length > 5 ? 5 : filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return _buildTransactionItem(order);
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI Components ---

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButton<String>(
        value: _selectedFilter,
        items: ["Today", "This Week", "This Month"]
            .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _selectedFilter = v);
        },
        underline: const SizedBox(),
        icon: Icon(Icons.keyboard_arrow_down, color: _emerald, size: 20),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, bool isCurrency, {bool isNegative = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _mint.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: _emerald, size: 20),
              ),
              Icon(
                isNegative ? Icons.trending_down : Icons.trending_up,
                color: isNegative ? Colors.redAccent : _mint,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _deepGreen),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendPlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insights_rounded, size: 50, color: _mint.withValues(alpha: 0.2)),
          const SizedBox(height: 10),
          Text("Analytics for $_selectedFilter synced",
              style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(OrderModel order) {
    final double amount = (order.totalcents) / 100.0;
    String dateStr = "Recently";

    if (order.placedat != null) {
      try {
        DateTime dt = DateTime.parse(order.placedat!);
        dateStr = DateFormat('MMM dd, hh:mm a').format(dt);
      } catch (_) {
        dateStr = order.placedat!.split('T')[0];
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: _softBg,
          child: Icon(Icons.receipt_long_outlined, color: _emerald, size: 20),
        ),
        title: Text("Order #${order.id}", style: TextStyle(fontWeight: FontWeight.w800, color: _deepGreen)),
        subtitle: Text(dateStr, style: const TextStyle(fontSize: 12)),
        trailing: Text(
          "+\$${amount.toStringAsFixed(2)}",
          style: TextStyle(color: _mint, fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
    );
  }
}