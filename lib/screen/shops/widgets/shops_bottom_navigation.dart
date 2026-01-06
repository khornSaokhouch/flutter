import 'package:flutter/material.dart';

/// Reusable bottom navigation scaffold used in the Shops area.
///
/// Use by passing a list of pages that match the number of items (default 4).
class ShopsBottomNavigation extends StatefulWidget {
  final List<Widget> pages;
  final int initialIndex;
  final Color accentColor;
  final List<BottomNavigationBarItem>? items;

  const ShopsBottomNavigation({
    super.key,
    required this.pages,
    this.initialIndex = 0,
    this.accentColor = const Color(0xFF4E8D7C),
    this.items,
  })  : assert(pages.length == (items?.length ?? 5), 'pages length must match items length');

  @override
  State<ShopsBottomNavigation> createState() => _ShopsBottomNavigationState();
}

class _ShopsBottomNavigationState extends State<ShopsBottomNavigation> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items ??
        const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined), // ← Promotions icon
            activeIcon: Icon(Icons.local_offer),
            label: 'Promotions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.store),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];

    final bodyContent = (_selectedIndex >= 0 && _selectedIndex < widget.pages.length)
        ? widget.pages[_selectedIndex]
        : widget.pages.first;

    return Scaffold(
      body: bodyContent,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: Offset(0, -5))],
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: widget.accentColor,
            unselectedItemColor: Colors.grey.shade400,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            items: items,
          ),
        ),
      ),
    );
  }
}
