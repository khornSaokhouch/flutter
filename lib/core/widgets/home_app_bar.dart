import 'package:flutter/material.dart';

class CustomHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomHomeAppBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight); // Standard AppBar height

  @override
  Widget build(BuildContext context) {
    // You might want to define colors and text styles in your app's theme
    final Color iconColor = Colors.black; // Adjust based on your theme
    final double iconSize = 28.0; // Adjust icon size as needed

    return AppBar(
      backgroundColor: Colors.white, // Light background as in your image
      elevation: 2, // A slight shadow to match the image's raised look
      shadowColor: Colors.grey.withOpacity(0.3), // Softer shadow color

      // Left side: Hamburger Menu Icon
      leading: IconButton(
        icon: Icon(Icons.menu, color: iconColor, size: iconSize),
        onPressed: () {
          // TODO: Implement action for opening a drawer or menu
          Scaffold.of(context).openDrawer(); // Example: opens a Scaffold drawer
        },
      ),

      // Center: Image Title (e.g., a coffee cup icon)
      title: Image.asset(
        'assets/images/drink_icon.png', // Replace with your actual image path
        height: 40, // Adjust size to match your image
        fit: BoxFit.contain,
      ),
      centerTitle: true, // Ensures the title image is centered

      // Right side: Shopping Bag Icon
      actions: [
        IconButton(
          icon: Icon(Icons.shopping_bag_outlined, color: iconColor, size: iconSize),
          onPressed: () {
            // TODO: Implement action for navigating to the shopping cart
            print('Shopping Bag tapped!');
          },
        ),
        const SizedBox(width: 8), // Add some spacing to the right
      ],
    );
  }
}

// Example of how to use this AppBar in a Scaffold:
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomHomeAppBar(),
      drawer: Drawer( // Example Drawer to show functionality
        child: ListView(
          padding: EdgeInsets.zero,
          children: const <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Drawer Header', style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              title: Text('Item 1'),
            ),
            ListTile(
              title: Text('Item 2'),
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text('Your main content goes here!'),
      ),
    );
  }
}

// To run this example, ensure you have an image at 'assets/images/drink_icon.png'
// and updated your pubspec.yaml:
/*
flutter:
  assets:
    - assets/images/drink_icon.png
*/