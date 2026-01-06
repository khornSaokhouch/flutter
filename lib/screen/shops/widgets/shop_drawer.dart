import 'package:flutter/material.dart';
import '../screens/sale_reports.dart';

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

  // --- LOGOUT POPUP DIALOG ---
  void _showLogoutDialog(BuildContext context) {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text("Are you sure you want to sign out from the Manager Hub?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close Dialog
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Add your actual logout logic here (clear tokens, etc.)
                Navigator.pop(context); // Close Dialog
                Navigator.pop(context); // Close Drawer
                // Example: Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("LOGOUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF2E7D32);
    const Color accentAmber = Color(0xFFD97706);

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // PREMIUM HEADER
          Container(
            padding: const EdgeInsets.only(top: 60, left: 24, right: 20, bottom: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryGreen, const Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(topRight: Radius.circular(30)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFF1F8E9),
                    child: Icon(Icons.person_rounded, color: primaryGreen, size: 35),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Manager Hub",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      Text(
                        "ID: $userId",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                _buildSectionHeader("CORE MANAGEMENT"),
                _buildDrawerItem(
                  icon: Icons.dashboard_rounded, 
                  label: "Global Dashboard", 
                  color: primaryGreen, 
                  onTap: () => Navigator.pop(context)
                ),
                _buildDrawerItem(
  icon: Icons.analytics_outlined,
  label: "Sales Reports",
  color: accentAmber,
  onTap: () {
    Navigator.pop(context); // close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SalesReportsPage(),
      ),
    );
  },
),

                
                const SizedBox(height: 20),
                _buildSectionHeader("YOUR BRANCHES"),
                
                ...shops.map((shop) => _buildDrawerItem(
                  icon: Icons.coffee_rounded,
                  label: shop.name,
                  color: primaryGreen,
                  onTap: () {
                    Navigator.pop(context);
                    onShopTap(shop.id);
                  },
                )),

                const SizedBox(height: 10),
                _buildDrawerItem(
                  icon: Icons.add_business_outlined, 
                  label: "Add New Branch", 
                  color: Colors.grey[600]!, 
                  onTap: () {}
                ),
              ],
            ),
          ),

          const Divider(indent: 24, endIndent: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
            child: _buildDrawerItem(
              icon: Icons.logout_rounded, 
              label: "Logout", 
              color: Colors.redAccent, 
              onTap: () => _showLogoutDialog(context), // <--- TRIGGER DIALOG
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12, top: 12),
      child: Text(
        title, 
        style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label, 
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3133))
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
    );
  }
}