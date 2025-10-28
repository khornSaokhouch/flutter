// lib/screen/user/layout.dart
import 'package:flutter/material.dart';
import '../account/account_page.dart';
import 'coffeeAppHome.dart';
import 'store_screen/select_store_page.dart';
import 'scan_pay_screen.dart';
import '../../routes/footer_nav_routes.dart';

class Layout extends StatefulWidget {
  final int userId;
  const Layout({super.key, required this.userId});

  @override
  State<Layout> createState() => _LayoutState();

}

class _LayoutState extends State<Layout> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    HomeScreen(userId: widget.userId),
    ScanPayScreen(userId: widget.userId),
    SelectStorePage(stores: [],),
    const PlaceholderWidget(text: 'Rewards Screen'),
    AccountPage(userId: widget.userId),

  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(30.0),
        child: AppBar(
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
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: FooterNav(selectedIndex: _selectedIndex, onItemTapped: _onItemTapped),
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  final String text;
  const PlaceholderWidget({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
    child: Text(text, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
  );
}
