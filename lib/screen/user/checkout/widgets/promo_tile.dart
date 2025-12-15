import 'package:flutter/material.dart';

class PromoTile extends StatelessWidget {
  const PromoTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {},
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      leading: const Icon(Icons.confirmation_number_outlined),
      title: const Text("Use Voucher",
          style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text("Save orders with promos"),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }
}
