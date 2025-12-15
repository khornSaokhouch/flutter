// navbar.dart
import 'package:flutter/material.dart';
import '../order/order_screen.dart';

class Navbar extends StatelessWidget {
  final int userId;
  const Navbar({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: () {}),
      centerTitle: true,
      title: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/img_1.png', fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.coffee, color: Color(0xFF1B4D3E))),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AllOrdersScreen(userId: userId)));
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
