import 'package:flutter/material.dart';

class ShopBottomBar extends StatelessWidget {
  final double? distanceKm;
  final double? shopDistance;
  final bool isOpen;
  final VoidCallback onOrderPressed;

  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _freshMintGreen = const Color(0xFF4E8D7C);

  const ShopBottomBar({
    super.key,
    required this.distanceKm,
    required this.shopDistance,
    required this.isOpen,
    required this.onOrderPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Format distance string
    String distanceStr = "— km";
    if (distanceKm != null) {
      distanceStr = "${distanceKm!.toStringAsFixed(2)} km";
    } else if (shopDistance != null) {
      distanceStr = "${shopDistance!.toStringAsFixed(2)} km";
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Distance",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  distanceStr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _espressoBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: isOpen ? onOrderPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _freshMintGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  isOpen ? "Order Now" : "Currently Closed",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}