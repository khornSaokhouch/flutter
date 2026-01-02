import 'package:flutter/material.dart';// Your login bottom sheet
import '../login_botton_sheet.dart';
import '../guest/guest_store_screen/guest_no_store_nearby_screen.dart';
import 'guest_home_screen.dart';
import '../../routes/footer_nav_routes.dart';
// import '../history/history_screen.dart';

class GuestLayout extends StatefulWidget {
  final int selectedIndex;

  const GuestLayout({super.key, this.selectedIndex = 0});

  @override
  State<GuestLayout> createState() => _GuestLayoutState();
}

class _GuestLayoutState extends State<GuestLayout> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  // Screens for tabs (only Home is accessible for guests)
  List<Widget> get _screens => [
    const GuestScreen(), // Home tab
    const SizedBox.shrink(), // Order - restricted
    const GuestNoStoreNearbyScreen(),
    // const HistoryScreen(), // Rewards - restricted
    const SizedBox.shrink(), // Account - restricted
  ];

  void _onItemTapped(int index) {
    if (index == 0 || index == 2) {
      setState(() => _selectedIndex = index);
    } else {
      // Other tabs show login bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Material(
            type: MaterialType.transparency,
            child: LoginBottomSheet(), // Your login bottom sheet widget
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: FooterNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}