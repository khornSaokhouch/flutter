import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screen/account/personal_info_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    try {
      user = await AuthUtils.checkAuthAndGetUser(
        context: context,
        userId: widget.userId,
      );
      if (user == null) return;
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      body: user == null || isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFFF9F6F0),
            expandedHeight: 150.0, // Increased expanded height
            floating: true,
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Padding(
                // Adjust top padding to account for status bar and give space
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: kToolbarHeight + 10, bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end, // Keep this to align to bottom
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Account",
                              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Welcome ${user?.name ?? 'Guest'}!",
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                            image: user?.profileImage != null
                                ? DecorationImage(
                              fit: BoxFit.cover,
                              image: NetworkImage(user!.profileImage!),
                            )
                                : const DecorationImage(
                              image: AssetImage('assets/images/profile.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Profile",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 15),
                      _buildSettingsTile(
                        context,
                        'Personal Info',
                        Icons.info_outline,
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PersonalInfoScreen(user: user!.id!),
                            ),
                          );
                        },
                      ),

                      _buildSettingsTile(
                        context,
                        'Cards & Payments',
                        Icons.credit_card,
                            () {
                          // Handle tap
                        },
                      ),
                      _buildSettingsTile(
                        context,
                        'Transaction History',
                        Icons.receipt_long,
                            () {
                          // Handle tap
                        },
                      ),
                      _buildSettingsTile(
                        context,
                        'Privacy & Data',
                        Icons.handshake_outlined,
                            () {
                          // Handle tap
                        },
                      ),
                      _buildSettingsTile(
                        context,
                        'Account ID',
                        Icons.badge_outlined,
                            () {
                          // Handle tap
                        },
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Security",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 15),
                      _buildSwitchTile(
                        context,
                        '2- factor authentication',
                        twoFactorAuth,
                            (bool newValue) {
                          setState(() {
                            twoFactorAuth = newValue;
                          });
                          // Save preference
                        },
                      ),
                      _buildSwitchTile(
                        context,
                        'Face ID',
                        faceId,
                            (bool newValue) {
                          setState(() {
                            faceId = newValue;
                          });
                          // Save preference
                        },
                      ),
                      _buildSwitchTile(
                        context,
                        'Passcode Lock',
                        passcodeLock,
                            (bool newValue) {
                          setState(() {
                            passcodeLock = newValue;
                          });
                          // Save preference
                        },
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Notification Preferences",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      // Add more tiles for Notification Preferences here
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, color: Colors.black),
            ),
            Icon(icon, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(BuildContext context, String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, color: Colors.black),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}