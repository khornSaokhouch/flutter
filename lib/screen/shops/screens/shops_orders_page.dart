import 'package:flutter/material.dart';

class ShopsOrdersPage extends StatefulWidget {
  const ShopsOrdersPage({super.key});

  @override
  State<ShopsOrdersPage> createState() => _ShopsOrdersPageState();
}

class _ShopsOrdersPageState extends State<ShopsOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  // --- Static Data ---
  final List<Map<String, dynamic>> _orders = [
    {
      'id': '#9021',
      'items': '2x Iced Latte, 1x Croissant',
      'total': 12.50,
      'status': 'Pending',
      'time': '2 mins ago',
      'customer': 'Alice M.'
    },
    {
      'id': '#9020',
      'items': '1x Americano (Hot)',
      'total': 3.50,
      'status': 'Preparing',
      'time': '10 mins ago',
      'customer': 'John D.'
    },
    {
      'id': '#9019',
      'items': '3x Matcha Frappe',
      'total': 18.00,
      'status': 'Ready',
      'time': '15 mins ago',
      'customer': 'Sarah L.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
          style: TextStyle(color: _espressoBrown, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 1.0),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _freshMintGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _freshMintGreen,
          isScrollable: true,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Pending (1)"),
            Tab(text: "Preparing (1)"),
            Tab(text: "Ready (1)"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList("Pending"),
          _buildOrderList("Preparing"),
          _buildOrderList("Ready"),
          _buildOrderList("History"), // Just re-using list for demo
        ],
      ),
    );
  }

  Widget _buildOrderList(String statusFilter) {
    // Filter logic (mock)
    final filtered = _orders.where((o) {
      if (statusFilter == "History") return true; // Show all for history demo
      return o['status'] == statusFilter;
    }).toList();

    if (filtered.isEmpty) return _buildEmptyState();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildOrderCard(filtered[index]);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    Color statusColor;
    String status = order['status'];
    
    if (status == 'Pending') statusColor = Colors.orange;
    else if (status == 'Preparing') statusColor = Colors.blue;
    else statusColor = _freshMintGreen;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Text(order['id'], style: TextStyle(fontWeight: FontWeight.bold, color: _espressoBrown, fontSize: 16)),
                  ],
                ),
                Text(order['time'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.receipt_long, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order['customer'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(order['items'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 8),
                      Text("\$${order['total'].toStringAsFixed(2)}", style: TextStyle(color: _freshMintGreen, fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions (Only for Pending/Preparing)
          if (status == 'Pending')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Decline"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _freshMintGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text("Accept"),
                    ),
                  ),
                ],
              ),
            ),
            
           if (status == 'Preparing')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _espressoBrown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("Mark as Ready"),
                ),
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
          Icon(Icons.inbox_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No orders found", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}