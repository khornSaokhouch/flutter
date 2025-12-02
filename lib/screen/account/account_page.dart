import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screen/account/personal_info_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Uncomment if needed for logout
import '../../core/utils/auth_utils.dart';
import '../../models/user.dart';

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
                    centerTitle: true,
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
                            // Avatar
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
                            // Name
                            Text(
                              user?.name ?? 'Guest User',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _espressoBrown,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Email/Role
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
                                    builder: (context) => UpdateProfileScreen(userId: user!.id!),
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
                              onTap: () {},
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

                          // Logout Button (Visual only based on your snippet)
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                // Add logout logic here
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.red.withOpacity(0.05),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text(
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
            color: Colors.black.withOpacity(0.03),
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
                  color: _freshMintGreen.withOpacity(0.1),
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