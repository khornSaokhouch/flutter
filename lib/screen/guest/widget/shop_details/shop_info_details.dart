import 'package:flutter/material.dart';
import '../../../../core/utils/utils.dart'; // Needed for formatTimeToAmPm
import '../../../../models/shop.dart';

class ShopInfoDetails extends StatelessWidget {
  final Shop shop;

  final Color _freshMintGreen = const Color(0xFF4E8D7C);

  const ShopInfoDetails({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    // Logic for Hours Text
    String hoursText = "Hours not listed";
    if (shop.openTime != null && shop.closeTime != null) {
      final open = formatTimeToAmPm(context, shop.openTime);
      final close = formatTimeToAmPm(context, shop.closeTime);
      if (open.isNotEmpty && close.isNotEmpty) {
        hoursText = '$open - $close';
      }
    }

    return Column(
      children: [
        // Location Card
        _buildDetailTile(
          icon: Icons.location_on_rounded,
          title: "Address",
          subtitle: shop.location ?? "Location not available",
        ),
        const SizedBox(height: 16),

        // Time Card
        _buildDetailTile(
          icon: Icons.access_time_filled_rounded,
          title: "Opening Hours",
          subtitle: hoursText,
        ),

        const SizedBox(height: 24),

        // Owner Card
        if (shop.owner.name.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: (shop.owner.profileImage != null)
                      ? NetworkImage(shop.owner.profileImage!)
                      : null,
                  child: (shop.owner.profileImage == null)
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.owner.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      "Store Manager",
                      style: TextStyle(color: _freshMintGreen, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.verified, color: Colors.blue, size: 20),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDetailTile({required IconData icon, required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _freshMintGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _freshMintGreen, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}