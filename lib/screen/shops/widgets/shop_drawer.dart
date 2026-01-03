import 'package:flutter/material.dart';

class ShopDrawer extends StatelessWidget {
  final String userId;
  final List<dynamic> shops;
  final Function(int shopId) onShopTap;

  const ShopDrawer({
    super.key,
    required this.userId,
    required this.shops,
    required this.onShopTap,
  });

  @override
  Widget build(BuildContext context) {
    // Premium Color Palette
    const Color primaryDark = Color(0xFF1A1C1E);
    const Color coffeeAccent = Color(0xFFD97706);
    const Color softGreen = Color(0xFF10B981);
    const Color lightGrey = Color(0xFFF1F3F4);

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
         Container(
              padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
              decoration: BoxDecoration(
                color: Colors.grey[300], // <-- Gray background
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981), // softGreen circle border
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Color(0xFF1A1C1E), size: 35),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Manager Hub",
                            style: TextStyle(
                              color: Colors.black87, // dark text for gray background
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "ID: $userId",
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

                      // --- MENU ITEMS ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              children: [
                _buildSectionHeader("NAVIGATION"),
                _buildDrawerItem(
                  icon: Icons.dashboard_rounded,
                  label: "Home Dashboard",
                  color: softGreen,
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.analytics_outlined,
                  label: "Global Reports",
                  color: coffeeAccent,
                  onTap: () {},
                ),
                
                const SizedBox(height: 25),
                _buildSectionHeader("MANAGE YOUR SHOPS"),
                
                // Dynamic Shop List
                ...shops.map((shop) => _buildDrawerItem(
                      icon: Icons.coffee_maker_rounded,
                      label: shop.name,
                      color: coffeeAccent,
                      onTap: () {
                        Navigator.pop(context);
                        onShopTap(shop.id);
                      },
                    )),

                const SizedBox(height: 10),
                _buildDrawerItem(
                  icon: Icons.add_circle_outline,
                  label: "Add New Branch",
                  color: Colors.grey,
                  onTap: () {},
                ),
              ],
            ),
          ),

          // --- FOOTER SECTION ---
          const Divider(indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.only(bottom: 20, left: 12, right: 12),
            child: _buildDrawerItem(
              icon: Icons.logout_rounded,
              label: "Logout",
              color: Colors.redAccent,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: SECTION TITLE ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 10, top: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // --- WIDGET HELPER: FANCY LIST ITEM ---
  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        visualDensity: const VisualDensity(vertical: -2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: color.withOpacity(0.1),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF1A1C1E),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      ),
    );
  }
}