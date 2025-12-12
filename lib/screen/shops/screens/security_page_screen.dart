import 'package:flutter/material.dart';



// ---------------------------------------------------------------------------
// 5. Security Page (Settings)
// ---------------------------------------------------------------------------
class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _twoFactorEnabled = true;
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Security Settings")),
      body: ListView(
        children: [
          _buildSectionHeader("Login & Authentication"),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text("Change Password"),
            subtitle: const Text("Last changed 3 months ago"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          SwitchListTile(
            secondary: const Icon(Icons.phonelink_lock),
            title: const Text("Two-Factor Authentication"),
            subtitle: const Text("Secure your account with 2FA"),
            value: _twoFactorEnabled,
            onChanged: (val) {
              setState(() => _twoFactorEnabled = val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text("Biometric Login"),
            value: _biometricEnabled,
            onChanged: (val) {
              setState(() => _biometricEnabled = val);
            },
          ),

          const Divider(),
          _buildSectionHeader("Access Control"),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text("Manage Staff Access"),
            subtitle: const Text("3 active staff members"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text("Active Sessions"),
            subtitle: const Text("Manage devices logged into your shop"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),

          const Divider(),
          _buildSectionHeader("Alerts"),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text("Security Alerts"),
            subtitle: const Text("Get notified of suspicious activity"),
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
            },
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.privacy_tip),
              label: const Text("View Privacy Policy"),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.grey),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
            color: Colors.indigo[800],
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0),
      ),
    );
  }
}