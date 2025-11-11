import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class FooterNav extends StatelessWidget { // Change to StatelessWidget
  final int selectedIndex;
  final Function(int) onItemTapped;

  const FooterNav({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = AppTheme.lightTheme.scaffoldBackgroundColor;
    Color lineColor = AppTheme.lightTheme.colorScheme.onSurface;
    return Column(

      mainAxisSize: MainAxisSize.min,
      children: [
        // Remove the "Footer Nav" label if it's not part of the final design
        // or integrate it differently if it's meant as a debugging label.
        // For now, removing to match common app layouts.
        Container(
          decoration:  BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
            ),
            border: Border(
              top: BorderSide(
                color: lineColor, // use color from TextTheme
                width: 0.1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.deepPurple,
            unselectedItemColor: Colors.grey,
            currentIndex: selectedIndex, // Use the passed selectedIndex
            onTap: onItemTapped,         // Use the passed onItemTapped
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner),
                label: 'Scan / Pay',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.coffee),
                label: 'Order',
              ),

               BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Account',
              ),
            ],
          ),
        ),

      ],
    );
  }
}