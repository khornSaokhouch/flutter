import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/utils/auth_utils.dart';
import '../../models/user.dart';
import '../../server/user_service.dart';

class ScanPayScreen extends StatefulWidget {
  final int userId;
  const ScanPayScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ScanPayScreen> createState() => _ScanPayScreenState();
}

class _ScanPayScreenState extends State<ScanPayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? user;
  bool isLoading = true;

  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _goldColor = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initPage();
  }

  Future<void> _initPage() async {
    try {
      // 1. Check Auth & Get User
      user = await AuthUtils.checkAuthAndGetUser(
        context: context,
        userId: widget.userId,
      );
      if (user == null) return; // redirected

      // 2. Fetch fresh user data (balance/points)
      final userModel = await UserService.getUserById(widget.userId);
      if (userModel?.user != null && mounted) {
        setState(() {
          user = userModel!.user;
        });
      }
    } catch (e) {
      debugPrint('Error loading scan page: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'PAYMENT',
          style: TextStyle(
            color: _espressoBrown,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: _espressoBrown),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: _freshMintGreen))
          : Column(
              children: [
                const SizedBox(height: 10),
                
                // 1. Custom Tab Bar
                _buildCustomTabBar(),

                const SizedBox(height: 20),

                // 2. Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // --- Tab 1: Scan & Pay ---
                      _buildScanAndPayTab(),

                      // --- Tab 2: Rewards Only ---
                      _buildRewardsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ====================================================
  // 1. CUSTOM TAB BAR
  // ====================================================
  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        labelColor: _espressoBrown,
        unselectedLabelColor: Colors.grey[500],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        tabs: const [
          Tab(text: 'Scan & Pay'),
          Tab(text: 'Rewards Only'),
        ],
      ),
    );
  }

  // ====================================================
  // 2. SCAN & PAY TAB CONTENT
  // ====================================================
  Widget _buildScanAndPayTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // 2.1 The Premium User Card
          _buildMembershipCard(),

          const SizedBox(height: 30),

          // 2.2 Payment Methods / Top Up
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(Icons.add_circle_outline, "Top Up", () {}),
                _buildActionButton(Icons.credit_card, "Manage Card", () {}),
                _buildActionButton(Icons.help_outline, "Help", () {}),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMembershipCard() {
    final userName = user?.name?.split(' ').last.toUpperCase() ?? 'GUEST';
    final userPhone = user?.phone ?? 'NO PHONE LINKED';
    final userBalance = 0.0; // Replace with actual balance variable
    final userPoints = 120; // Replace with actual points variable

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _freshMintGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          colors: [_espressoBrown, _freshMintGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background Pattern (Optional)
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.coffee_rounded, size: 150, color: Colors.white.withOpacity(0.05)),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header: Avatar + Name + Points
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: (user?.imageUrl != null && user!.imageUrl!.isNotEmpty)
                            ? NetworkImage(user!.imageUrl!)
                            : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "WELCOME BACK",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Points Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: _goldColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "$userPoints pts",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),

                // Balance Section
                Text(
                  "CURRENT BALANCE",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  "\$${userBalance.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 30),

                // QR Code Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: '$userName|$userPhone',
                        version: QrVersions.auto,
                        size: 180,
                        foregroundColor: Colors.black,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Scan to Pay or Earn Points",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: _freshMintGreen, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: _espressoBrown,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // 3. REWARDS ONLY TAB CONTENT
  // ====================================================
  Widget _buildRewardsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stars_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Rewards QR Code",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _espressoBrown,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Use this code to earn points without paying.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                )
              ],
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: QrImageView(
              data: 'REWARDS_ONLY:${user?.id}',
              version: QrVersions.auto,
              size: 200,
            ),
          ),
        ],
      ),
    );
  }
}