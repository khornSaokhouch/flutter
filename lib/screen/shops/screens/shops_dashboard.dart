// file: shops_dashboard.dart
import 'package:flutter/material.dart';
//import 'package:frontend/screen/shops/screens/shops_categories_page.dart';
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

  late final List<Widget> _pages = [
    ShopsHomePage(userId: widget.userId),  // 0: Home
    const ShopsOrdersPage(),               // 1: Orders
     // ShopsCategoriesPage(),           // 2: Categories
    const ShopsProductsPage(),             // 3: Products
    const ShopsProfilePage(),              // 4: Profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    print(widget.userId);

    return Scaffold(
      // hide top app bar when Categories is selected -> full screen page
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.category),
          //   label: 'Categories',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
