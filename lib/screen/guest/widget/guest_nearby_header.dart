import 'package:flutter/material.dart';

import '../guest_screen.dart';


class GuestNearbyHeader extends StatelessWidget {
  const GuestNearbyHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nearby Stores',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4D3E),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GuestLayout(selectedIndex: 2),
                  ),
                );
              },
              child: const Text(
                'See All',
                style: TextStyle(color: Color(0xFF4A6B5C)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
