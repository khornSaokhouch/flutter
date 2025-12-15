// lib/screen/order/widgets/status_header.dart
import 'package:flutter/material.dart';

class StatusHeader extends StatelessWidget {
  final String status;
  final Color freshMintGreen;
  final Color espressoBrown;
  final VoidCallback? onTap;

  const StatusHeader({
    super.key,
    required this.status,
    required this.freshMintGreen,
    required this.espressoBrown,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String displayStatus = "Order Placed";
    String displayMsg = "Waiting for store confirmation";

    if (status == 'preparing') {
      displayStatus = "Preparing";
      displayMsg = "We are making your drink";
    } else if (status == 'ready') {
      displayStatus = "Ready for Pickup";
      displayMsg = "Head to the counter!";
    } else if (status == 'completed') {
      displayStatus = "Completed";
      displayMsg = "Enjoy your drink!";
    } else if (status == 'cancelled') {
      displayStatus = "Cancelled";
      displayMsg = "This order was cancelled";
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Hero(
            tag: 'status_icon',
            child: Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle, boxShadow: [
                BoxShadow(color: freshMintGreen.withOpacity(0.2), blurRadius: 30, spreadRadius: 5),
              ]),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset('assets/images/img_1.png', fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(displayStatus, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: espressoBrown)),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios, size: 14, color: freshMintGreen),
            ],
          ),
          const SizedBox(height: 8),
          Text(displayMsg, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }
}
