import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// 3. My Shop Page (Dashboard View)
// ---------------------------------------------------------------------------
class MyShopPage extends StatelessWidget {
  const MyShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Shop"),
        actions: [
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.8),
                image: const DecorationImage(
                  image: NetworkImage('https://via.placeholder.com/600x200'),
                  fit: BoxFit.cover,
                  opacity: 0.4,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.store, size: 35),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Tech Gadgets Store",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Electronics & Accessories",
                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction(Icons.inventory_2, "Products"),
                  _buildQuickAction(Icons.people, "Customers"),
                  _buildQuickAction(Icons.reviews, "Reviews"),
                  _buildQuickAction(Icons.edit, "Edit Info"),
                ],
              ),
            ),

            const Divider(height: 40),

            // Products Grid Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Popular Products",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: const Text("View All"))
                ],
              ),
            ),

            // Product List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
                    title: Text("Product Item #${index + 1}"),
                    subtitle: const Text("Stock: 24 | Sales: 120"),
                    trailing: const Text("\$49.99",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                );
              },
            ),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.indigo.shade50,
          child: Icon(icon, color: Colors.indigo),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}


