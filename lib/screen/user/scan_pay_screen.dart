import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
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
  String status = "Fetching user...";
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUser();
    _initPage();
  }
  Future<void> _initPage() async {
    try {
      // Check auth and fetch user
      user = await AuthUtils.checkAuthAndGetUser(
        context: context,
        userId: widget.userId,
      );
      if (user == null) return; // redirected to login

      // Fetch user location and sort stores
      // userPosition = await getUserLocation();
      // stores = sortStoresByDistance(userPosition!, stores);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }


  Future<void> _loadUser() async {
    try {
      final userModel = await UserService.getUserById(widget.userId);
      if (userModel?.user != null && mounted) {
        setState(() {
          user = userModel!.user;
          status = "Hello, ${user!.name?.split(' ').last}!";
        });
        print("✅ User fetched: ${user!.name}, ID: ${user!.id}");
      } else {
        setState(() {
          status = "❌ Failed to fetch user with ID ${widget.userId}";
        });
      }
    } catch (e) {
      setState(() {
        status = "❌ Error fetching user: $e";
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final String userName = user?.name?.split(' ').last ?? 'Guest';
    final String userPhone = user?.phone ?? '+855 000 000 000';
    final int userPoints =  0;
    final double userBalance =  0.0;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Tabs
            Container(
              color: colorScheme.background,
              child: TabBar(
                controller: _tabController,
                labelColor: colorScheme.primary,
                unselectedLabelColor:
                colorScheme.onBackground.withOpacity(0.6),
                indicatorColor: colorScheme.primary,
                indicatorWeight: 3.0,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Scan & Pay'),
                  Tab(text: 'Rewards Only'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Scan & Pay
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildUserCard(
                          theme,
                          userName,
                          userPhone,
                          userPoints,
                          userBalance,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  // Rewards Only
                  Center(
                    child: Text(
                      'Rewards Only Content',
                      style: textTheme.titleLarge
                          ?.copyWith(color: colorScheme.onBackground),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(
      ThemeData theme, String userName, String userPhone, int points, double balance) {
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4B2C20), Color(0xFF4E8D7C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildUserInfoRow(textTheme, userName, userPhone),
          const SizedBox(height: 24),
          _buildRewardsRow(textTheme, points),
          const SizedBox(height: 24),
          _buildBalance(textTheme, balance),
          const SizedBox(height: 24),
          _buildQRCode(userName, userPhone),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildUserInfoRow(
      TextTheme textTheme, String name, String phone) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: user?.profileImage != null
              ?NetworkImage('${ApiConstants.baseStorageUrl}/${user!.profileImage!}')  // User has profile image
              : const AssetImage('assets/images/default_avatar.png') as ImageProvider, // Default image
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: textTheme.titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              phone,
              style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRewardsRow(TextTheme textTheme, int points) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Rewards',
          style: textTheme.titleLarge
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text(
              '$points',
              style: textTheme.titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalance(TextTheme textTheme, double balance) {
    return Center(
      child: Text(
        '\$$balance',
        style: textTheme.displaySmall
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildQRCode(String userName, String userPhone) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: QrImageView(
          data: '$userName $userPhone',
          version: QrVersions.auto,
          size: 220,
        ),
      ),
    );
  }
}
