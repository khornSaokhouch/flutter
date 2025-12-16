import 'package:flutter/material.dart';

class CartItemsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;

  const CartItemsWidget({super.key, required this.cartItems});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: cartItems
          .map((i) => ListTile(
        title: Text("${i['qty']}x ${i['name']}"),
        trailing:
        Text("\$${(i['price'] * i['qty']).toStringAsFixed(2)}"),
      ))
          .toList(),
    );
  }
}
