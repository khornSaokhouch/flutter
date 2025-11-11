import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/utils.dart';
import '../../core/widgets/card/drink_card.dart';
// import '../../routes/footer_nav_routes.dart';
import '../auth/login_screen.dart';
import '../home_screen.dart'; // Make sure FooterNav is imported correctly

class GuestScreen extends StatefulWidget {
  const GuestScreen({Key? key}) : super(key: key);

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightTheme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Navbar(),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good ${getGreeting()}',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onBackground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Login and get free',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.coffee, size: 18, color: Colors.grey[700]),
                    ],
                  ),
                ],
              ),
            ),

            // Rewards Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A6B5C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Join the Rewards program to enjoy free beverages, special offers and more!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle Join Now
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6F4E37),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'JOIN NOW',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle Guest Order
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4B499),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'GUEST ORDER',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Login Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  Text(
                    'Already have an account?',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF4A6B5C), width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'LOGIN',
                      style: TextStyle(
                          fontSize: 16, color: Color(0xFF4A6B5C), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Drinks Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Drinks',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('See all', style: TextStyle(fontSize: 14, color: Color(0xFF4A6B5C))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Expanded(
                          child: DrinkCard(image: 'assets/images/coffee.png', title: 'Hot Coffees')),
                      SizedBox(width: 16),
                      Expanded(
                          child: DrinkCard(image: 'assets/images/coffee.png', title: 'Hot Teas')),
                      SizedBox(width: 16),
                      Expanded(
                          child: DrinkCard(image: 'assets/images/coffee.png', title: 'Hot Drinks')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // // ✅ Fixed Footer Navigation
      // bottomNavigationBar: FooterNav(
      //   selectedIndex: _selectedIndex,
      //   onItemTapped: _onItemTapped,
      // ),
    );
  }
}

class Navbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black),
        onPressed: () {},
      ),
      centerTitle: true,
      title: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFD4B499),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.coffee_outlined, color: Color(0xFF6F4E37), size: 24),
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
              onPressed: () {},
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A6B5C),
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: const Text(
                  '0',
                  style: TextStyle(color: Colors.white, fontSize: 8),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}



// class FooterNav extends StatefulWidget {
//   @override
//   _FooterNavState createState() => _FooterNavState();
// }
//
// class _FooterNavState extends State<FooterNav> {
//   int _selectedIndex = 0;
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//     // Add navigation logic here based on index
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BottomNavigationBar(
//       items: const <BottomNavigationBarItem>[
//         BottomNavigationBarItem(
//           icon: Icon(Icons.home),
//           label: 'Home',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.qr_code_scanner),
//           label: 'Scan / Pay',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.local_cafe),
//           label: 'Order',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.person),
//           label: 'Account',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.star_border),
//           label: 'Rewards',
//         ),
//       ],
//       currentIndex: _selectedIndex,
//       selectedItemColor: Color(0xFF4A6B5C), // Green for selected item
//       unselectedItemColor: Colors.grey,
//       showUnselectedLabels: true,
//       onTap: _onItemTapped,
//       backgroundColor: Colors.white,
//       type: BottomNavigationBarType.fixed, // Ensure all labels are visible
//       selectedLabelStyle: TextStyle(fontSize: 12),
//       unselectedLabelStyle: TextStyle(fontSize: 12),
//     );
//   }
// }

// To run this code, you'll need to add placeholder images to your assets folder:
// Create an 'assets' folder in your project root.
// Add the following images (or similar placeholder images) to the 'assets' folder:
// - hot_coffees.png
// - hot_teas.png
// - hot_drinks.png
//
// Then, update your pubspec.yaml file:
//
// flutter:
//   uses-material-design: true
//   assets:
//     - assets/
//
// Example of main.dart to use this:
//
// import 'package:flutter/material.dart';
// import 'package:your_app_name/guest_screen.dart'; // Adjust import path

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Coffee App',
//       theme: ThemeData(
//         primarySwatch: Colors.green,
//         scaffoldBackgroundColor: Color(0xFFF5F5ED), // Light beige background
//       ),
//       home: GuestScreen(),
//     );
//   }
// }