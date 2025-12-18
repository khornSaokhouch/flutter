import 'package:flutter/material.dart';
import '../../../../models/shop.dart';

class ShopTitleSection extends StatelessWidget {
  final Shop shop;
  final bool isOpen;

  // Colors
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _freshMintGreen = const Color(0xFF4E8D7C);

  const ShopTitleSection({super.key, required this.shop, required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        Text(
          shop.name,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _espressoBrown,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        
        // Status Pill
        _buildStatusPill(isOpen),
        
        const SizedBox(height: 24),

        // Quick Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickAction(icon: Icons.map_outlined, label: "Map", onTap: () {}),
            _buildQuickAction(icon: Icons.call_outlined, label: "Call", onTap: () {}),
            _buildQuickAction(icon: Icons.share_outlined, label: "Share", onTap: () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusPill(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen ? _freshMintGreen.withOpacity(0.1) : Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: isOpen ? _freshMintGreen : Colors.red),
          const SizedBox(width: 6),
          Text(
            isOpen ? "Open Now" : "Closed",
            style: TextStyle(
              color: isOpen ? _freshMintGreen : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: _espressoBrown, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            )
          ],
        ),
      ),
    );
  }
}