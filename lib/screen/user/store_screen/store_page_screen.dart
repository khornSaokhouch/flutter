import 'package:flutter/material.dart';
import 'select_store_page.dart'; // Import Store model

class StorePageScreen extends StatelessWidget {
  final Store store;

  const StorePageScreen({Key? key, required this.store}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(store.name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(store.image, width: 200, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 20),
            Text(store.name,
                style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(store.address),
            const SizedBox(height: 10),
            Text("Hours: ${store.openHours}"),
          ],
        ),
      ),
    );
  }
}
