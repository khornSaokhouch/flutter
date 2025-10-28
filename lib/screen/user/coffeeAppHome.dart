import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/auth_utils.dart';
import '../../models/user.dart';
import '../../server/user_serveice.dart';

import '../../core/utils/utils.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  const HomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : _buildHomeContent(theme),
    );
  }

  Widget _buildHomeContent(ThemeData theme) {
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate(
            [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good ${getGreeting()}, ${user?.name?.split(' ').last ?? 'Guest'}!',
                          style: textTheme.headlineMedium?.copyWith(color: colorScheme.onBackground),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: user?.profileImage != null
                          ? NetworkImage(user!.profileImage!)
                          : const AssetImage('assets/images/profile.png') as ImageProvider,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
