import 'package:flutter/material.dart';
import 'package:frontend/screen/shops/screens/shops_home_page.dart';
import 'package:frontend/screen/shops/screens/shops_orders_page.dart';
import 'package:frontend/screen/shops/screens/shops_products_page.dart';
import 'package:frontend/screen/shops/screens/shops_profile_page.dart';

class ShopsDashboard extends StatefulWidget {
  final String userId;

  const ShopsDashboard({super.key, required this.userId});

  @override
  State<ShopsDashboard> createState() => _ShopsDashboardState();
}

class _ShopsDashboardState extends State<ShopsDashboard> {
  int _selectedIndex = 0;

  // Theme Colors
  final Color _freshMintGreen = const Color(0xFF4E8D7C);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ShopsHomePage(userId: widget.userId),  // 0: Home
      const ShopsOrdersPage(),               // 1: Orders
      const ShopsProductsPage(),             // 2: Products
      const ShopsProfilePage(),              // 3: Profile
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), 
      // AppBar removed here so ShopsHomePage controls its own header (removing back button there)
      
      body: _pages[_selectedIndex],
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            
            // Theme Colors
            selectedItemColor: _freshMintGreen,
            unselectedItemColor: Colors.grey.shade400,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            
            items: const [
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
                icon: Icon(Icons.storefront_outlined),
                activeIcon: Icon(Icons.store),
                label: 'Products',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}