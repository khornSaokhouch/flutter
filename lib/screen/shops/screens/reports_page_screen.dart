import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  // --- Premium Emerald Theme Palette ---
  final Color _deepGreen = const Color(0xFF1B4332);
  final Color _emerald = const Color(0xFF2D6A4F);
  final Color _mint = const Color(0xFF52B788);
  final Color _softBg = const Color(0xFFF8FAF9);

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
          style: TextStyle(color: _deepGreen, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
        ),
        iconTheme: IconThemeData(color: _deepGreen),
      ),
      body: SingleChildScrollView(
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButton<String>(
                    value: "This Week",
                    items: ["Today", "This Week", "This Month"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) {},
                    underline: const SizedBox(),
                    icon: Icon(Icons.keyboard_arrow_down, color: _emerald, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Stat Cards Grid ---
            Row(
              children: [
                Expanded(child: _buildStatCard("Total Sales", "\$12,450", Icons.payments_outlined, true)),
                const SizedBox(width: 15),
                Expanded(child: _buildStatCard("Orders", "1,205", Icons.shopping_cart_outlined, false)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildStatCard("Visitors", "34.5k", Icons.analytics_outlined, false)),
                const SizedBox(width: 15),
                Expanded(child: _buildStatCard("Refunds", "12", Icons.assignment_return_outlined, false, isNegative: true)),
              ],
            ),

            const SizedBox(height: 32),

            // --- Sales Trend Section ---
            Text(
              "Sales Trend",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _deepGreen),
            ),
            const SizedBox(height: 12),
            Container(
              height: 220,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Icon(Icons.insights_rounded, size: 60, color: _mint.withOpacity(0.3)),
                    ),
                  ),
                  Text("Graph Data Coming Soon", style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

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
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 5,
              itemBuilder: (context, index) {
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
                    title: Text("Order #100${20 + index}", style: TextStyle(fontWeight: FontWeight.w800, color: _deepGreen)),
                    subtitle: Text("Today, 10:${30 + index} AM", style: const TextStyle(fontSize: 12)),
                    trailing: Text(
                      "+\$${(index + 1) * 25}.00",
                      style: TextStyle(color: _mint, fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
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
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
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
                decoration: BoxDecoration(color: _mint.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _deepGreen),
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
}