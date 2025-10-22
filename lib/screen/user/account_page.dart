import 'package:flutter/material.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool twoFactorAuth = true;
  bool faceId = true;
  bool passcodeLock = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        title: const Icon(Icons.local_cafe, color: Colors.brown, size: 28),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF9F6F0),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Account",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Welcome Vasken!",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.black12,
                  child: Icon(Icons.person, size: 40),
                ),
              ],
            ),

            const SizedBox(height: 25),
            const Text("Profile",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildListTile(Icons.person_outline, "Personal Info"),
            _buildListTile(Icons.credit_card, "Cards & Payments"),
            _buildListTile(Icons.history, "Transaction History"),
            _buildListTile(Icons.privacy_tip_outlined, "Privacy & Data"),
            _buildListTile(Icons.badge_outlined, "Account ID"),

            const SizedBox(height: 20),
            const Text("Security",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildSwitchTile("2-factor authentication", twoFactorAuth,
                    (value) => setState(() => twoFactorAuth = value)),
            _buildSwitchTile(
                "Face ID", faceId, (value) => setState(() => faceId = value)),
            _buildSwitchTile("Passcode Lock", passcodeLock,
                    (value) => setState(() => passcodeLock = value)),

            const SizedBox(height: 20),
            const Text("Notification Preferences",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),

    );
  }

  ListTile _buildListTile(IconData icon, String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title,
          style: const TextStyle(fontSize: 16, color: Colors.black87)),
      trailing: const Icon(Icons.info_outline, color: Colors.grey),
      onTap: () {},
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: const TextStyle(fontSize: 16, color: Colors.black87)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.green,
    );
  }
}
