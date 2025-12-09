import 'package:flutter/material.dart';

class ShopsProfilePage extends StatefulWidget {
  const ShopsProfilePage({super.key});

  @override
  State<ShopsProfilePage> createState() => _ShopsProfilePageState();
}

class _ShopsProfilePageState extends State<ShopsProfilePage> {
  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      body: CustomScrollView(
        slivers: [
          // 1. Header
          SliverAppBar(
            backgroundColor: _espressoBrown,
            expandedHeight: 180,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.only(top: 60, bottom: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 33,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: const NetworkImage("https://i.pravatar.cc/150?img=12"), // Mock avatar
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "James Anderson",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Owner Account",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Stats Dashboard
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem("Today's Sales", "\$450.00", Icons.attach_money),
                  Container(width: 1, height: 40, color: Colors.grey[200]),
                  _buildStatItem("Total Orders", "128", Icons.shopping_bag),
                ],
              ),
            ),
          ),

          // 3. Settings Menu
          SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionTitle("Shop Management"),
              _buildSettingTile(Icons.store, "My Shops", () {}),
              _buildSettingTile(Icons.people_outline, "Staff Management", () {}),
              _buildSettingTile(Icons.pie_chart_outline, "Reports & Analytics", () {}),
              
              _buildSectionTitle("Account"),
              _buildSettingTile(Icons.notifications_outlined, "Notifications", () {}),
              _buildSettingTile(Icons.lock_outline, "Security", () {}),
              _buildSettingTile(Icons.help_outline, "Help & Support", () {}),
              
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () {
                    // Logout logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: _freshMintGreen, size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _espressoBrown)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _freshMintGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: _freshMintGreen, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}