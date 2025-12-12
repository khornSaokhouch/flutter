import 'package:flutter/material.dart';



// // ---------------------------------------------------------------------------
// // 4. Reports Page (Analytics)
// // ---------------------------------------------------------------------------
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reports & Analytics")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Overview",
                    style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: "This Week",
                  items: ["Today", "This Week", "This Month"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {},
                  underline: Container(),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Stat Cards
            Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                        "Total Sales", "\$12,450", Colors.green, Icons.attach_money)),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildStatCard(
                        "Orders", "1,205", Colors.orange, Icons.shopping_bag)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                        "Visitors", "34.5k", Colors.blue, Icons.people)),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildStatCard(
                        "Refunds", "12", Colors.red, Icons.assignment_return)),
              ],
            ),

            const SizedBox(height: 30),

            // Placeholder Graph
            const Text("Sales Trend",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 80, color: Colors.indigo[100]),
                    Text("Graph Placeholder",
                        style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Recent Transactions
            const Text("Recent Transactions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 5,
              separatorBuilder: (c, i) => const Divider(),
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: const Icon(Icons.receipt, color: Colors.black54),
                  ),
                  title: Text("Order #100${20 + index}"),
                  subtitle: Text("Today, 10:${30 + index} AM"),
                  trailing: Text("+\$${(index + 1) * 25}.00",
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Icon(Icons.arrow_upward, color: Colors.green[300], size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style:
              const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }
}
