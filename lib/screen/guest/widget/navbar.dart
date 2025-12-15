import 'package:flutter/material.dart';

class GuestNavbar extends StatelessWidget {
  const GuestNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Image.asset('assets/images/img_1.png', height: 36),
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
          onPressed: () {},
        ),
      ],
    );
  }
}
