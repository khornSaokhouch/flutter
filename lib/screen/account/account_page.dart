import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screen/account/payment_history_screen.dart';
import 'package:frontend/screen/account/personal_info_screen.dart';
import '../../core/utils/auth_utils.dart';
import '../../models/user.dart';
import '../../server/user_service.dart';
import '../guest/guest_screen.dart';

class AccountPage extends StatefulWidget {
  final int userId;
  const AccountPage({super.key, required this.userId});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  User? user;
  bool twoFactorAuth = true;
  bool faceId = true;
  bool passcodeLock = false;
  bool isLoading = true;
  bool _isLoggingOut = false;

  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    setState(() => isLoading = true);
    try {
      user = await AuthUtils.checkAuthAndGetUser(
        context: context,
        userId: widget.userId,
      );
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _onLogoutPressed() async {
    // ui ios logout
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Log Out"),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text("Are you sure you want to log out?"),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel",
              style: TextStyle(color: Colors.black), // 👈 BLACK TEXT
            ),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoggingOut = true);

    try {
      final success = await UserService.logout();
      if (!mounted) return;

      if (success) {
        // Navigate to login and remove all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => GuestLayout()),
              (route) => false,
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logout failed. Please try again.')),
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred while logging out.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: _freshMintGreen))
          : RefreshIndicator(
        onRefresh: _initPage,
        color: _freshMintGreen,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Large App Bar with Profile Info
            SliverAppBar(
              backgroundColor: _bgGrey,
              expandedHeight: 220.0,
              pinned: true,
              elevation: 0,

              // 👇 REMOVE centerTitle or set to false
              centerTitle: true,
              automaticallyImplyLeading: false,
              title: Text(
                "My Profile",
                style: TextStyle(
                  color: _espressoBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),

              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.only(top: 80.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _freshMintGreen, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: (user?.imageUrl != null && user!.imageUrl!.isNotEmpty)
                              ? NetworkImage(user!.imageUrl!)
                              : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.name ?? 'Guest User',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _espressoBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'No email linked',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Settings Sections
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("General"),
                    _buildSectionContainer([
                      _buildSettingsTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Personal Info',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UpdateProfileScreen(userId: user?.id ?? widget.userId),
                            ),
                          );
                          if (result == true) _initPage();
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.credit_card_rounded,
                        title: 'Cards & Payments',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.history_rounded,
                        title: 'Transaction History',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentHistoryScreen(
                                userId: widget.userId,
                              ),
                            ),
                          );
                        },
                      ),
                    ]),

                    const SizedBox(height: 24),

                    _buildSectionTitle("Security"),
                    _buildSectionContainer([
                      _buildSwitchTile(
                        title: '2-factor authentication',
                        value: twoFactorAuth,
                        onChanged: (val) => setState(() => twoFactorAuth = val),
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        title: 'Face ID',
                        value: faceId,
                        onChanged: (val) => setState(() => faceId = val),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    _buildSectionTitle("Support"),
                    _buildSectionContainer([
                      _buildSettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy & Data',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help Center',
                        onTap: () {},
                      ),
                    ]),

                    const SizedBox(height: 40),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isLoggingOut ? null : _onLogoutPressed,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.red.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoggingOut
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: Colors.red,
                          ),
                        )
                            : const Text(
                          "Log Out",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _freshMintGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _freshMintGreen, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: _freshMintGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 0.5, color: Colors.grey[200], indent: 60);
  }
}
