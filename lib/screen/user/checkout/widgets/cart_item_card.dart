import 'package:flutter/material.dart';

class CartItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const CartItemTile(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    final qty = item['qty'];
    final price = item['price'];

    return ListTile(
      title: Text("${qty}x ${item['name']}"),
      trailing: Text(
        "\$${(qty * price).toStringAsFixed(2)}",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
