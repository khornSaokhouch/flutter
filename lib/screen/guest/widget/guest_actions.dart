import 'package:flutter/material.dart';

import '../guest_screen.dart';


class GuestActions extends StatelessWidget {
  const GuestActions({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _card(
              title: "Pickup",
              active: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GuestLayout(selectedIndex: 2),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            _card(title: "Delivery", active: false),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    bool active = true,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: active ? onTap : null,
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: active ? Colors.green : Colors.grey,
          ),
          alignment: Alignment.bottomLeft,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
