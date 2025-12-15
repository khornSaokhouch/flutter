// lib/screen/order/widgets/success_actions.dart
import 'package:flutter/material.dart';

import '../store_screen/order_detail_screen.dart';


class SuccessActions extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final Color freshMintGreen;
  final Color espressoBrown;

  const SuccessActions({
    super.key,
    required this.orderData,
    required this.freshMintGreen,
    required this.espressoBrown,
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        // Primary action: View Order Details (navigates to OrderDetailScreen)
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(orderData: orderData),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: freshMintGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text("View Order Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary action: Track Order (placeholder - currently same navigation)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              // Replace with actual tracking flow if you have one
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(orderData: orderData),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text("Track Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),

        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: Text("Back to Home", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
