import 'package:flutter/material.dart';

import '../guest_screen.dart';


class GuestPickupDelivery extends StatelessWidget {
  const GuestPickupDelivery({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _card(
              title: "Pickup",
              image: 'assets/images/pickup.jpg',
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
            _card(
              title: "Delivery",
              image: 'assets/images/pickup.jpg',
              active: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required String image,
    required bool active,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: active ? onTap : null,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: DecorationImage(
              image: AssetImage(image),
              fit: BoxFit.cover,
              colorFilter: active
                  ? null
                  : const ColorFilter.mode(
                  Colors.grey, BlendMode.saturation),
            ),
          ),
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: TextStyle(
              color: active ? Colors.white : Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
