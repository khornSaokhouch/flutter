import 'package:flutter/material.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  // --- Premium Emerald Theme Palette ---
  final Color _deepGreen = const Color(0xFF1B4332);
  final Color _emerald = const Color(0xFF2D6A4F);
  final Color _mint = const Color(0xFF52B788);
  final Color _softBg = const Color(0xFFF8FAF9);

  bool _twoFactorEnabled = true;
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "SECURITY CENTER",
          style: TextStyle(color: _deepGreen, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
        ),
        iconTheme: IconThemeData(color: _deepGreen),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          _buildSectionHeader("Login & Authentication"),
          _buildSettingItem(
            icon: Icons.lock_reset_rounded,
            title: "Change Password",
            subtitle: "Last updated 3 months ago",
            trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            onTap: () {},
          ),
          _buildSwitchItem(
            icon: Icons.phonelink_lock_rounded,
            title: "Two-Factor Auth",
            subtitle: "Extra layer of security for logins",
            value: _twoFactorEnabled,
            onChanged: (val) => setState(() => _twoFactorEnabled = val),
          ),
          _buildSwitchItem(
            icon: Icons.fingerprint_rounded,
            title: "Biometric Login",
            subtitle: "Use FaceID or Fingerprint",
            value: _biometricEnabled,
            onChanged: (val) => setState(() => _biometricEnabled = val),
          ),

          const SizedBox(height: 10),
          _buildSectionHeader("Access Control"),
          _buildSettingItem(
            icon: Icons.admin_panel_settings_outlined,
            title: "Staff Permissions",
            subtitle: "3 members with active access",
            trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            onTap: () {},
          ),
          _buildSettingItem(
            icon: Icons.devices_other_rounded,
            title: "Connected Devices",
            subtitle: "Manage devices logged into shop",
            trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            onTap: () {},
          ),

         const SizedBox(height: 10),
          _buildSectionHeader("Notifications"),
          _buildSwitchItem(
            // Changed from shield_notifications_outlined to a more compatible icon
            icon: Icons.notifications_active_outlined, 
            title: "Security Alerts",
            subtitle: "Notify on suspicious login attempts",
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
          ),

          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.privacy_tip_outlined, size: 18, color: _emerald),
              label: Text("VIEW PRIVACY POLICY", 
                style: TextStyle(color: _emerald, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.1)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _emerald.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: _emerald, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
      ),
    );
  }

  // Generic Setting Tile
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _softBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: _emerald, size: 22),
        ),
        title: Text(title, style: TextStyle(color: _deepGreen, fontWeight: FontWeight.w800, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: trailing,
      ),
    );
  }

  // Switch Setting Tile
  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _softBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: _emerald, size: 22),
        ),
        title: Text(title, style: TextStyle(color: _deepGreen, fontWeight: FontWeight.w800, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: _mint,
          activeTrackColor: _mint.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}