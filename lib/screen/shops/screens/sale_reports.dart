import 'package:flutter/material.dart';

class SalesReportsPage extends StatefulWidget {
  const SalesReportsPage({super.key});

  @override
  State<SalesReportsPage> createState() => _SalesReportsPageState();
}

class _SalesReportsPageState extends State<SalesReportsPage> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color accentAmber = const Color(0xFFD97706);
  final Color bgGrey = const Color(0xFFF8F9FA);

  String selectedPeriod = "This Week";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Text("Sales Analytics", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.download_rounded, color: Color(0xFF2E7D32))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. PERIOD SELECTOR
            _buildPeriodSelector(),

            const SizedBox(height: 25),

            // 2. MAIN TOTAL REVENUE CARD
            _buildMainRevenueCard(),

            const SizedBox(height: 20),

            // 3. SECONDARY STATS ROW
            Row(
              children: [
                Expanded(child: _buildStatCard("Orders", "1,284", Icons.shopping_bag_outlined, Colors.blue)),
                const SizedBox(width: 15),
                Expanded(child: _buildStatCard("Customers", "856", Icons.people_outline, Colors.orange)),
              ],
            ),

            const SizedBox(height: 30),

            // 4. SALES GRAPH (SIMULATED)
            const Text("Sales Revenue Trend", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 15),
            _buildSimulatedChart(),

            const SizedBox(height: 30),

            // 5. TOP SELLING ITEMS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Top Selling Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text("View All", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 15),
            _buildTopItem("Espresso Roast", "452 Sales", "\$1,350.00", "assets/images/img_1.png"),
            _buildTopItem("Caramel Macchiato", "312 Sales", "\$945.50", "assets/images/img_1.png"),
            _buildTopItem("Iced Americano", "285 Sales", "\$712.00", "assets/images/img_1.png"),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 45,
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: ["Today", "This Week", "This Month"].map((period) {
          bool isSelected = selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedPeriod = period),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  period,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMainRevenueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryGreen, const Color(0xFF1B5E20)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: primaryGreen.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Revenue", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          const Text("\$12,450.80", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.greenAccent, size: 18),
              const SizedBox(width: 5),
              const Text("+12.5% ", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              Text("vs last $selectedPeriod", style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 15),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSimulatedChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildBar(0.4), _buildBar(0.6), _buildBar(0.9), _buildBar(0.5), _buildBar(0.7), _buildBar(0.3), _buildBar(1.0),
        ],
      ),
    );
  }

  Widget _buildBar(double heightFactor) {
    return Container(
      width: 15,
      height: 140 * heightFactor,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryGreen, primaryGreen.withValues(alpha: 0.5)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildTopItem(String name, String sales, String amount, String img) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(img, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.coffee)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(sales, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(fontWeight: FontWeight.w900, color: primaryGreen)),
        ],
      ),
    );
  }
}