import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class FooterNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const FooterNav({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Get the Green color from your Theme
    final activeColor = AppTheme.lightTheme.colorScheme.secondary; // This is Color(0xFF4E8D7C)
    final inactiveColor = Colors.grey.shade400;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        // Rounded corners only at the top for a modern sheet look
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        // Subtle shadow to separate from content
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          
          // 2. Set the Selected Color to GREEN
          selectedItemColor: activeColor, 
          unselectedItemColor: inactiveColor,
          
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),

          currentIndex: selectedIndex,
          onTap: onItemTapped,

          items: [
            _buildItem(Icons.home_rounded, Icons.home_outlined, 'Home', 0),
            _buildItem(Icons.qr_code_scanner_rounded, Icons.qr_code_scanner, 'Scan', 1),
            _buildItem(Icons.coffee_rounded, Icons.coffee_outlined, 'Order', 2),
            _buildItem(Icons.history_rounded, Icons.history_outlined, 'History', 3),
            _buildItem(Icons.person_rounded, Icons.person_outline, 'Account', 4),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildItem(
    IconData activeIcon, 
    IconData inactiveIcon, 
    String label, 
    int index
  ) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: Icon(
          // Switch icon style based on selection
          selectedIndex == index ? activeIcon : inactiveIcon,
          size: 26,
        ),
      ),
      label: label,
    );
  }
}