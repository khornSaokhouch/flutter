import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../../../models/order_model.dart';
import '../../../models/shop.dart';
import '../../../server/order_service.dart';
 // adjust path/name if different
import '../../../server/shop_serviec.dart';
import '../../guest/guest_screen.dart';

class ShopsProfilePage extends StatefulWidget {
  final int shopId;
  const ShopsProfilePage({super.key, required this.shopId});

  @override
  State<ShopsProfilePage> createState() => _ShopsProfilePageState();
}

class _ShopsProfilePageState extends State<ShopsProfilePage> {
  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  bool _isLoggingOut = false;

  late Future<Shop?> _shopFuture;
  List<OrderModel> _orders = [];

  // Stats
  int _todaySalesCents = 0;
  int _totalOrders = 0;
  int _todayOrdersCounted = 0; // how many orders contributed to today's sales

  @override
  void initState() {
    super.initState();
    _shopFuture = ShopService.fetchShopById(widget.shopId);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await OrderService.fetchAllOrdersForShop(shopid: widget.shopId);
      if (!mounted) return;
      setState(() {
        _orders = orders;
      });
      // compute stats (defaults: today's date, only completed, minTotalCents = 1)
      _computeStats();
    } catch (e) {
      debugPrint('Error loading orders: $e');
      // If you want, set an _error string and display in UI
    }
  }

  /// Compute stats for a given date (defaults to today).
  /// Defaults: only count completed orders and orders with totalcents >= minTotalCents.
  /// Will attempt to parse `placedat` (format "yyyy-MM-dd HH:mm:ss") first, then ISO fallback.
  void _computeStats({DateTime? countDate, bool onlyCompleted = true, int minTotalCents = 1}) {
    final DateTime now = DateTime.now();
    final DateTime targetDate = countDate ?? now;

    int totalOrders = _orders.length;
    int todaySales = 0;
    int todayCountedOrders = 0;

    // Use DateFormat for backend style "yyyy-MM-dd HH:mm:ss"
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm:ss');

    for (final o in _orders) {
      // Business rules
      if (onlyCompleted && o.status.toLowerCase() != 'completed') continue;
      if (o.totalcents < minTotalCents) continue;

      DateTime? parsed;

      // 1) try placedat as backend "yyyy-MM-dd HH:mm:ss"
      final s = o.placedat?.trim();
      if (s != null && s.isNotEmpty) {
        try {
          parsed = dateFmt.parseStrict(s).toLocal();
        } catch (_) {
          // fallback: try replacing first space with 'T' and parse as ISO
          try {
            parsed = DateTime.parse(s.replaceFirst(' ', 'T')).toLocal();
          } catch (_) {
            parsed = null;
          }
        }
      }

      // 2) fallback: created_at from toJson() if available and parsable
      if (parsed == null) {
        try {
          final created = o.toJson()['created_at']?.toString();
          if (created != null && created.isNotEmpty) {
            parsed = DateTime.parse(created).toLocal();
          }
        } catch (_) {
          parsed = null;
        }
      }

      if (parsed == null) {
        // couldn't parse any timestamp; skip
        continue;
      }

      if (_isSameLocalDate(parsed, targetDate)) {
        todaySales += o.totalcents;
        todayCountedOrders++;
      }
    }

    if (mounted) {
      setState(() {
        _totalOrders = totalOrders;
        _todaySalesCents = todaySales;
        _todayOrdersCounted = todayCountedOrders;
      });
    }
  }

  // helper to check same local date (year-month-day)
  bool _isSameLocalDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // format cents to currency string (USD style, adjust to your locale if needed)
  String _formatMoney(int cents) {
    final dollars = cents / 100.0;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  Future<void> _onLogoutPressed() async {
    // Ask user for confirmation
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
            onPressed: () => Navigator.pop(context, false),
            isDefaultAction: true,
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            isDestructiveAction: true,
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoggingOut = true);

    try {
      // 1) Call backend logout if needed
      await UserService.logout();

      // // 2) Clear local stored tokens
      // await UserService.clearLocalSession(); // <-- implement this

      if (!mounted) return;

      // 3) Navigate to Guest/Login screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const GuestLayout()),
            (_) => false,
      );

    } catch (e) {
      debugPrint("Logout error: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logout failed: $e")),
        );
      }

    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }


  // debug helper to recompute for a specific date
  void debugComputeFor(int year, int month, int day) {
    _computeStats(countDate: DateTime(year, month, day));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      body: CustomScrollView(
        slivers: [
          // Header with shop info from future
          SliverAppBar(
            backgroundColor: _espressoBrown,
            expandedHeight: 200,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FutureBuilder<Shop?>(
              future: _shopFuture,
              builder: (context, snap) {
                final shop = snap.data;
                return FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.only(top: 60, bottom: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 33,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: (shop?.imageUrl != null && shop!.imageUrl!.isNotEmpty)
                                ? NetworkImage(shop.imageUrl!)
                                : const NetworkImage("https://i.pravatar.cc/150?img=12"),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          shop?.name ?? "Shop Owner",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          shop?.location ?? "Owner Account",
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Stats Dashboard
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Today's Sales: show amount and number of counted orders below
                  Column(
                    children: [
                      Icon(Icons.attach_money, color: _freshMintGreen, size: 24),
                      const SizedBox(height: 8),
                      Text(_formatMoney(_todaySalesCents), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _espressoBrown)),
                      Text("Today's Sales", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text('$_todayOrdersCounted orders', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),

                  Container(width: 1, height: 56, color: Colors.grey[200]),

                  // Total Orders
                  Column(
                    children: [
                      Icon(Icons.shopping_bag, color: _freshMintGreen, size: 24),
                      const SizedBox(height: 8),
                      Text('$_totalOrders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _espressoBrown)),
                      Text("Total Orders", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Settings Menu (same as your original)
          SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionTitle("Shop Management"),
              _buildSettingTile(Icons.store, "My Shops", () {}),
              _buildSettingTile(Icons.people_outline, "Staff Management", () {}),
              _buildSettingTile(Icons.pie_chart_outline, "Reports & Analytics", () {}),

              _buildSectionTitle("Account"),
              _buildSettingTile(Icons.notifications_outlined, "Notifications", () {}),
              _buildSettingTile(Icons.lock_outline, "Security", () {}),
              _buildSettingTile(Icons.help_outline, "Help & Support", () {}),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: _isLoggingOut ? null : _onLogoutPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoggingOut
                      ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: Colors.red,
                    ),
                  )
                      : const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _freshMintGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: _freshMintGreen, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}

class UserService {
  static Future<bool> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}


