import 'package:flutter/material.dart';
import '../../config/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/auth_utils.dart';
import '../../core/utils/utils.dart';
import '../../models/user.dart';

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
      user = await AuthUtils.checkAuthAndGetUser(context: context, userId: widget.userId);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightTheme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
          ? const Center(child: Text("No user data"))
          : CustomScrollView(
        slivers: [
          // Black line at top
          SliverToBoxAdapter(
            child: Container(
              height: 5,
              width: double.infinity,
              color: Colors.black,
            ),
          ),

          // SliverAppBar
          SliverAppBar(
            backgroundColor: colorScheme.primary,
            pinned: true,
            floating: false,
            elevation: 0,
            expandedHeight: 40,
            automaticallyImplyLeading: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Stack(
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: colorScheme.onBackground),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                        child: Text(
                          '0',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Main content
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
                            style: textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onBackground,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Welcome back!',
                            style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: user?.profileImage != null
                            ? NetworkImage('${ApiConstants.baseStorageUrl}/${user!.profileImage!}') // Combine base URL + relative path
                            : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                      ),

                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Nearby Stores',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                // Store list
                ListView.builder(
                  itemCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.store, color: Colors.orange),
                        title: Text('Store ${index + 1}'),
                        subtitle: const Text('Street name or location here'),
                        onTap: () {},
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
