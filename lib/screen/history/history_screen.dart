import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  final int userId;

  // Corrected constructor
  const HistoryScreen({required this.userId, Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  // --- Static Data ---
  final List<StaticOrder> _orders = [
    StaticOrder(
      id: "#28492",
      shopName: "Starbucks - Central Market",
      date: "Today, 10:23 AM",
      items: "2x Iced Americano, 1x Croissant",
      price: 12.50,
      status: OrderStatus.completed,
      imageUrl: "https://upload.wikimedia.org/wikipedia/en/thumb/d/d3/Starbucks_Corporation_Logo_2011.svg/1200px-Starbucks_Corporation_Logo_2011.svg.png",
    ),
    StaticOrder(
      id: "#28455",
      shopName: "The Coffee Bean & Tea Leaf",
      date: "Yesterday, 4:15 PM",
      items: "1x Matcha Latte (Large)",
      price: 5.75,
      status: OrderStatus.cancelled,
      imageUrl: "https://upload.wikimedia.org/wikipedia/en/thumb/9/9f/The_Coffee_Bean_%26_Tea_Leaf_logo.svg/1200px-The_Coffee_Bean_%26_Tea_Leaf_logo.svg.png",
    ),
    StaticOrder(
      id: "#28102",
      shopName: "Brown Coffee and Bakery",
      date: "Sep 24, 08:30 AM",
      items: "1x Cappuccino, 1x Bagel",
      price: 8.20,
      status: OrderStatus.upcoming,
      imageUrl: "", // Will use fallback icon
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "HISTORY",
          style: TextStyle(
            color: _espressoBrown,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // 1. Custom Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _freshMintGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _freshMintGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[500],
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              tabs: const [
                Tab(text: 'Past Orders'),
                Tab(text: 'Upcoming'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Past Orders List
                ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: _orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildOrderCard(_orders[index]);
                  },
                ),

                // Upcoming (Empty State Example)
                _buildEmptyState(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets ---

  Widget _buildOrderCard(StaticOrder order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Row: Image + Name + Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Logo
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: order.imageUrl.isNotEmpty
                        ? Image.network(
                            order.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.store, color: _freshMintGreen),
                          )
                        : Icon(Icons.store, color: _freshMintGreen),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.date,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "\$${order.price.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _espressoBrown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${order.items.split(',').length} items",
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                )
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Items Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _bgGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                order.items,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Bottom Actions
            Row(
              children: [
                _buildStatusBadge(order.status),
                const Spacer(),
                if (order.status == OrderStatus.completed) ...[
                  _buildActionButton(
                    label: "Rate",
                    textColor: Colors.black,
                    bgColor: Colors.white,
                    borderColor: Colors.grey.shade300,
                    onTap: () {},
                  ),
                  const SizedBox(width: 10),
                  _buildActionButton(
                    label: "Reorder",
                    textColor: Colors.white,
                    bgColor: _freshMintGreen,
                    borderColor: _freshMintGreen,
                    onTap: () {},
                  ),
                ] else ...[
                   _buildActionButton(
                    label: "Help",
                    textColor: Colors.grey,
                    bgColor: Colors.white,
                    borderColor: Colors.grey.shade200,
                    onTap: () {},
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
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

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color textColor,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
              ],
            ),
            child: Icon(Icons.receipt_long_rounded, size: 50, color: Colors.grey[300]),
          ),
          const SizedBox(height: 20),
          Text(
            "No Upcoming Orders",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _espressoBrown,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Looks like you don't have any\nactive orders right now.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // Navigate to Home
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _freshMintGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text("Start Ordering", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// --- Static Data Models ---

enum OrderStatus { completed, cancelled, processing, upcoming }

class StaticOrder {
  final String id;
  final String shopName;
  final String date;
  final String items;
  final double price;
  final OrderStatus status;
  final String imageUrl;

  StaticOrder({
    required this.id,
    required this.shopName,
    required this.date,
    required this.items,
    required this.price,
    required this.status,
    required this.imageUrl,
  });
}