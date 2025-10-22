import 'package:flutter/material.dart';
import 'account_page.dart';

class Layout extends StatefulWidget {
  const Layout({super.key});

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  int _selectedIndex = 0;

  // Add multiple screens if needed
  final List<Widget> _screens = [
    const AccountPage(),
    const Center(child: Text("Scan / Pay")),
    const Center(child: Text("Order")),
    const Center(child: Text("Gift")),
    const Center(child: Text("Rewards")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: "Scan / Pay"),
          BottomNavigationBarItem(icon: Icon(Icons.local_cafe_outlined), label: "Order"),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: "Gift"),
          BottomNavigationBarItem(icon: Icon(Icons.star_border), label: "Rewards"),
        ],
      ),
    );
  }
}
