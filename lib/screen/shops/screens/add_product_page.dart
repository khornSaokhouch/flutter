import 'package:flutter/material.dart';

class AddProductPage extends StatelessWidget {
  final int shopId;
  const AddProductPage({super.key, required this.shopId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
      ),
      body: Center(
        child: Text('Add product form for Shop ID: ${shopId} will go here.'),
      ),
    );
  }
}