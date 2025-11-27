import 'package:flutter/material.dart';
class ShopProductDetail extends StatelessWidget {
  final  item; // replace Product with your model type

  const ShopProductDetail({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.name ?? 'Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // show image, description, price, etc.
            Text(item.description ?? ''),
          ],
        ),
      ),
    );
  }
}
