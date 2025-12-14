import 'package:flutter/material.dart';
import '../../../models/promotion_model.dart';

class PromotionCard extends StatelessWidget {
  final PromotionModel promotion;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onDelete;
  
  

  const PromotionCard({
    super.key,
    required this.promotion,
    required this.onToggleActive,
    required this.onDelete, required void Function() onCopyCode,
  });

  @override
  Widget build(BuildContext context) {
    final expired = promotion.expiresAt?.isBefore(DateTime.now()) ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildBadge(),
            const SizedBox(width: 12),
            Expanded(child: _buildInfo(expired)),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    final label = promotion.type == "percent"
        ? "${promotion.value.toStringAsFixed(0)}%"
        : "\$${promotion.value.toStringAsFixed(2)}";

    return Container(
      width: 70,
      height: 70,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfo(bool expired) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(promotion.code, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Shop #${promotion.shopid}"),
        Text(expired ? "Expired" : "Active"),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        Switch(value: promotion.isActive, onChanged: onToggleActive),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: onDelete,
        ),
      ],
    );
  }
}
