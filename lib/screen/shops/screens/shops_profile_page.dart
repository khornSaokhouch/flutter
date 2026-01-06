import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screen/shops/screens/reports_page_screen.dart';
import 'package:frontend/screen/shops/screens/security_page_screen.dart';
import 'package:intl/intl.dart';

import '../../../models/order_model.dart';
import '../../../models/shop.dart';
import '../../../server/order_service.dart';
import '../../../server/shop_service.dart';
import '../../guest/guest_screen.dart';
import 'edit_info_page.dart';

class ShopsProfilePage extends StatefulWidget {
  final int shopId;
  const ShopsProfilePage({super.key, required this.shopId});

  @override
  State<ShopsProfilePage> createState() => _ShopsProfilePageState();
}

class _ShopsProfilePageState extends State<ShopsProfilePage> {
  // --- Emerald & Mint UI Palette ---
  final Color _deepGreen = const Color(0xFF1B4332);
  final Color _emerald = const Color(0xFF2D6A4F);
  final Color _softBg = const Color(0xFFF8FAF9);

  bool _isLoggingOut = false;
  late Future<Shop?> _shopFuture;
  List<OrderModel> _orders = [];

  // Stats
  int _todaySalesCents = 0;
  int _totalOrders = 0;

  @override
  void initState() {
    super.initState();
    _shopFuture = ShopService.fetchShopById(widget.shopId);
    _loadOrders();
  }

  // --- LOGIC FUNCTIONS (UNCHANGED) ---
  Future<void> _loadOrders() async {
    try {
      final orders =
          await OrderService.fetchAllOrdersForShop(shopid: widget.shopId);
      if (!mounted) return;
      setState(() => _orders = orders);
      _computeStats();
    } catch (e) {
      debugPrint('Error loading orders: $e');
    }
  }

  void _computeStats(
      {DateTime? countDate, bool onlyCompleted = true, int minTotalCents = 1}) {
    final DateTime now = DateTime.now();
    final DateTime targetDate = countDate ?? now;
    int totalOrders = _orders.length;
    int todaySales = 0;
    late int todayCountedOrders = 0;
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm:ss');
    for (final o in _orders) {
      if (onlyCompleted && o.status.toLowerCase() != 'completed') continue;
      if (o.totalcents < minTotalCents) continue;
      DateTime? parsed;
      final s = o.placedat?.trim();
      if (s != null && s.isNotEmpty) {
        try {
          parsed = dateFmt.parseStrict(s).toLocal();
        } catch (_) {
          try {
            parsed = DateTime.parse(s.replaceFirst(' ', 'T')).toLocal();
          } catch (_) {
            parsed = null;
          }
        }
      }
      if (parsed != null && _isSameLocalDate(parsed, targetDate)) {
        todaySales += o.totalcents;
        todayCountedOrders++;
      }
    }
    if (mounted) {
      setState(() {
        _totalOrders = totalOrders;
        _todaySalesCents = todaySales;
      });
    }
  }

  bool _isSameLocalDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  String _formatMoney(int cents) => '\$${(cents / 100.0).toStringAsFixed(2)}';

  Future<void> _onLogoutPressed() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, true),
              isDestructiveAction: true,
              child: const Text("Logout")),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoggingOut = true);
    try {
      await UserService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const GuestLayout()), (_) => false);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Logout failed: $e")));
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softBg,
      body: CustomScrollView(
        slivers: [
          // Banner AppBar without background image
          SliverAppBar(
            backgroundColor: _deepGreen,
            expandedHeight: 180,
            pinned: true,
            automaticallyImplyLeading: false,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: FutureBuilder<Shop?>(
                future: _shopFuture,
                builder: (context, snap) {
                  final shop = snap.data;
                  return Container(
                    color: _deepGreen, // solid background
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: Colors.white30, shape: BoxShape.circle),
                          child:CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: Image.network(
                                (shop?.imageUrl != null && shop!.imageUrl!.isNotEmpty)
                                    ? shop.imageUrl!
                                    : '', // empty → trigger errorBuilder
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    width: 90,
                                    height: 90,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.storefront,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                        ),
                        const SizedBox(height: 12),
                        Text(shop?.name ?? "Shop Owner",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900)),
                        Text(shop?.location ?? "Primary Shop Account",
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // FIXED STATS DASHBOARD (CENTERED)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _deepGreen.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      Icons.insights_rounded,
                      _formatMoney(_todaySalesCents),
                      "Today's Revenue",
                      iconBgColor: _deepGreen.withValues(alpha: 0.1),
                    ),
                  ),
                  Container(
                      height: 60,
                      width: 1,
                      color: Colors.grey.withValues(alpha: 0.15)),
                  Expanded(
                    child: _buildStatItem(
                      Icons.auto_graph_rounded,
                      _totalOrders.toString(),
                      "Total Orders",
                      iconBgColor: _deepGreen.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu Sections
          SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionTitle("Operations"),
              _buildMenuTile(Icons.storefront_rounded, "Shop Profile",
                  "Edit info, location, & hours", () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EditInfoPage(shopId: widget.shopId,)));
              }),
              _buildMenuTile(Icons.badge_outlined, "Staff Management",
                  "Manage employee access", () {}),
              _buildMenuTile(Icons.bar_chart_rounded, "Advanced Reports",
                  "View sales & trends", () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ReportsPage(shopId: widget.shopId,)));
              }),

              _buildSectionTitle("Account & Support"),
              _buildMenuTile(Icons.notifications_none_rounded, "Notifications",
                  "Alerts & order sounds", () {}),
              _buildMenuTile(
                  Icons.security_rounded, "Security", "Passwords & 2FA", () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => SecurityPage()));
              }),
              _buildMenuTile(Icons.help_outline_rounded, "Help Center",
                  "Get support from our team", () {}),

              const SizedBox(height: 32),

              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextButton.icon(
                  onPressed: _isLoggingOut ? null : _onLogoutPressed,
                  icon: _isLoggingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.redAccent))
                      : const Icon(Icons.logout_rounded,
                          color: Colors.redAccent, size: 20),
                  label: const Text("SIGN OUT ACCOUNT",
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ]),
          ),
        ],
      ),
    );
  }

  // FIXED: Centered UI Item
  Widget _buildStatItem(IconData icon, String value, String label,
      {Color iconBgColor = Colors.grey}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _deepGreen, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          value,
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Text(title.toUpperCase(),
          style: TextStyle(
              color: _emerald,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5)),
    );
  }

  Widget _buildMenuTile(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: _softBg, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: _emerald, size: 22),
        ),
        title: Text(title,
            style: TextStyle(
                color: _deepGreen, fontWeight: FontWeight.w800, fontSize: 15)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: Colors.grey, size: 22),
      ),
    );
  }
}

class UserService {
  static Future<bool> logout() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return true;
  }
}
