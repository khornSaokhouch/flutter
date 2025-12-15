import 'package:flutter/material.dart';

class EmptyCart extends StatelessWidget {
  const EmptyCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.shopping_cart_outlined,
              size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text("Cart is empty",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
