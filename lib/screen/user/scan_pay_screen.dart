import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/utils/auth_utils.dart';
import '../../core/widgets/style_overlay_banner.dart';
import '../../models/user.dart';
import '../../server/user_service.dart';
import '../../server/notification_service.dart';

class ScanPayScreen extends StatefulWidget {
  final int userId;

  const ScanPayScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ScanPayScreen> createState() => _ScanPayScreenState();
}

class _ScanPayScreenState extends State<ScanPayScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  User? user;
  bool isLoading = true;

  // Theme colors
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _goldColor = const Color(0xFFFFD700);

  // Top banner
  OverlayEntry? _bannerEntry;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _initNotifications();
    _initPage();
  }

  // ====================================================
  // NOTIFICATIONS
  // ====================================================
  void _initNotifications() {
    NotificationService().init(
      onMessage: (title, body) {
        if (!mounted) return;
        _showTopBanner(title, body);
      },
    );
  }

  void _showTopBanner(String title, String body) {
    _removeTopBanner();

    _bannerEntry = OverlayEntry(
      builder: (context) {
        final topPadding = MediaQuery.of(context).padding.top;

        return Positioned(
          top: topPadding + 12,
          left: 16,
          right: 16,
          child: TopBanner(
            title: title,
            body: body,
            onClose: _removeTopBanner,
          ),
        );
      },
    );

    final overlay = Overlay.of(context, rootOverlay: true);

    overlay.insert(_bannerEntry!);

    _bannerTimer =
        Timer(const Duration(seconds: 4), _removeTopBanner);
  }

  void _removeTopBanner() {
    _bannerTimer?.cancel();
    _bannerTimer = null;

    _bannerEntry?.remove();
    _bannerEntry = null;
  }

  // ====================================================
  // PAGE INIT
  // ====================================================
  Future<void> _initPage() async {
    try {
      user = await AuthUtils.checkAuthAndGetUser(
        context: context,
        userId: widget.userId,
      );
      if (user == null) return;

      final userModel = await UserService.getUserById(widget.userId);
      if (mounted && userModel?.user != null) {
        setState(() => user = userModel!.user);
      }
    } catch (e) {
      debugPrint('ScanPayScreen error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _removeTopBanner();
    NotificationService().dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ====================================================
  // UI
  // ====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'PAYMENT',
          style: TextStyle(
            color: _espressoBrown,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        actions: [
          Icon(Icons.history_rounded, color: _espressoBrown),
          const SizedBox(width: 12),
        ],
      ),
      body: isLoading
          ? Center(
              child:
                  CircularProgressIndicator(color: _freshMintGreen),
            )
          : Column(
              children: [
                const SizedBox(height: 12),
                _buildCustomTabBar(),
                const SizedBox(height: 20),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildScanAndPayTab(),
                      _buildRewardsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ====================================================
  // TAB BAR
  // ====================================================
  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              offset: Offset(0, 2),
              color: Colors.black12,
            ),
          ],
        ),
        labelColor: _espressoBrown,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Scan & Pay'),
          Tab(text: 'Rewards Only'),
        ],
      ),
    );
  }

  // ====================================================
  // SCAN & PAY TAB
  // ====================================================
  Widget _buildScanAndPayTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildMembershipCard(),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(Icons.add_circle_outline, 'Top Up'),
                _buildActionButton(Icons.credit_card, 'Manage Card'),
                _buildActionButton(Icons.help_outline, 'Help'),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMembershipCard() {
    final name =
        user?.name?.split(' ').last.toUpperCase() ?? 'GUEST';
    final phone = user?.phone ?? 'NO PHONE';
    const balance = 0.0;
    const points = 120;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [_espressoBrown, _freshMintGreen],
        ),
        boxShadow: [
          BoxShadow(
            color: _freshMintGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage:
                    (user?.imageUrl?.isNotEmpty ?? false)
                        ? NetworkImage(user!.imageUrl!)
                        : const AssetImage(
                                'assets/images/default_avatar.png')
                            as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.star,
                      color: _goldColor, size: 16),
                  const SizedBox(width: 4),
                  Text('$points pts',
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('CURRENT BALANCE',
              style: TextStyle(color: Colors.white70)),
          Text('\$${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: '$name|$phone',
              size: 180,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: _freshMintGreen),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: _espressoBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }

  // ====================================================
  // REWARDS TAB
  // ====================================================
  Widget _buildRewardsTab() {
    return Center(
      child: QrImageView(
        data: 'REWARDS_ONLY:${user?.id}',
        size: 200,
      ),
    );
  }
}
