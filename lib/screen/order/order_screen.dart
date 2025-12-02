import 'package:flutter/material.dart';

class AllOrdersScreen extends StatefulWidget {
  final int userId;

  // Constructor with required userId
  const AllOrdersScreen({required this.userId, Key? key}) : super(key: key);

  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  // --- Static Data ---
  final List<StaticOrder> _thisMonthOrders = [
    StaticOrder(
      id: "OD-2204",
      shop: "Starbucks - Central",
      items: "2x Caramel Macchiato",
      date: "Oct 24, 10:30 AM",
      price: 14.50,
      status: "Completed",
    ),
    StaticOrder(
      id: "OD-2201",
      shop: "Brown Coffee",
      items: "1x Iced Latte, 1x Cake",
      date: "Oct 22, 08:15 AM",
      price: 9.20,
      status: "Completed",
    ),
    StaticOrder(
      id: "OD-2198",
      shop: "Amazon Cafe",
      items: "1x Black Coffee",
      date: "Oct 20, 2:00 PM",
      price: 3.50,
      status: "Cancelled",
    ),
  ];

  final List<StaticOrder> _septOrders = [
    StaticOrder(
      id: "OD-2150",
      shop: "Koi The",
      items: "2x Bubble Tea (L)",
      date: "Sep 28, 4:45 PM",
      price: 6.80,
      status: "Completed",
    ),
    StaticOrder(
      id: "OD-2112",
      shop: "Starbucks - Central",
      items: "1x Americano",
      date: "Sep 15, 09:00 AM",
      price: 4.20,
      status: "Completed",
    ),
  ];

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
                      decoration: InputDecoration(
                        hintText: "Search by ID or Shop...",
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    color: _freshMintGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _freshMintGreen.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.tune_rounded, color: _freshMintGreen),
                ),
              ],
            ),
          ),

          // 3. Scrollable List
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSectionHeader("This Month"),
                ..._thisMonthOrders.map((order) => _buildOrderTile(order)),

                const SizedBox(height: 10),
                
                _buildSectionHeader("September 2023"),
                ..._septOrders.map((order) => _buildOrderTile(order)),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildOrderTile(StaticOrder order) {
    final bool isCompleted = order.status == "Completed";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order.shop,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "\$${order.price.toStringAsFixed(2)}",
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
                      order.items,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          order.date,
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
                    )
                  ],
                ),
              ),
            ],
          ),
          
          // Reorder Divider (Only for completed)
          if(isCompleted) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Colors.grey[100]),
            ),
            InkWell(
              onTap: () {
                // Reorder Logic
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
                  )
                ],
              ),
            )
          ]
        ],
      ),
    );
  }
}

// --- Simple Static Model ---
class StaticOrder {
  final String id;
  final String shop;
  final String items;
  final String date;
  final double price;
  final String status;

  StaticOrder({
    required this.id,
    required this.shop,
    required this.items,
    required this.date,
    required this.price,
    required this.status,
  });
}