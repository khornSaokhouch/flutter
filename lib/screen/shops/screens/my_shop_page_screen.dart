import 'package:flutter/material.dart';
import 'package:frontend/screen/shops/screens/customers_page.dart';
import 'package:frontend/screen/shops/screens/edit_info_page.dart';
import 'package:frontend/screen/shops/screens/products_page.dart';
import 'package:frontend/screen/shops/screens/reviews_page.dart';

class MyShopPage extends StatelessWidget {
  final int shopId;
  const MyShopPage({super.key, required this.shopId});

  // --- Premium Emerald Theme Palette ---
  final Color _deepGreen = const Color(0xFF1B4332);
  final Color _emerald = const Color(0xFF2D6A4F);
  final Color _mint = const Color(0xFF52B788);
  final Color _softBg = const Color(0xFFF8FAF9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Header Banner ---
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_deepGreen, _emerald],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1441986300917-64674bd600d8?q=80&w=1000&auto=format&fit=crop'),
                      fit: BoxFit.cover,
                      opacity: 0.3,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            'https://via.placeholder.com/150', // Replace with shop logo
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Tech Gadgets Store",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              shadows: [Shadow(color: Colors.black26, blurRadius: 10)],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _mint.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Electronics & Accessories",
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 5),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // --- Quick Actions Grid ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  _buildQuickAction(Icons.inventory_2_outlined, "Products", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductsPage()));
                  }),
                  _buildQuickAction(Icons.group_outlined, "Customers", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CustomersPage()));
                  }),
                  _buildQuickAction(Icons.star_outline_rounded, "Reviews", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewsPage()));
                  }),
                  _buildQuickAction(Icons.edit_note_rounded, "Edit Info", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => EditInfoPage(shopId: shopId,)));
                  }),
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(thickness: 1, color: Color(0xFFEEEEEE)),
            ),
            const SizedBox(height: 15),

            // --- Popular Products Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Popular Products",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _deepGreen),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text("View All", style: TextStyle(color: _emerald, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),

            // --- Product List ---
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _softBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.image_outlined, color: _emerald.withOpacity(0.5)),
                    ),
                    title: Text(
                      "Premium Gadget #${index + 1}",
                      style: TextStyle(fontWeight: FontWeight.w800, color: _deepGreen),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          _buildSmallBadge("Stock: 24", Colors.blueGrey),
                          const SizedBox(width: 8),
                          _buildSmallBadge("Sales: 120", _mint),
                        ],
                      ),
                    ),
                    trailing: Text(
                      "\$49.99",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _emerald),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 100), // Space for Floating Button
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: _emerald,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("ADD PRODUCT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Icon(icon, color: _emerald, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _deepGreen.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}