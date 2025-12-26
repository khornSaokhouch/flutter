import 'package:flutter/material.dart';
import '../../../models/promotion_model.dart';

class PromotionCard extends StatelessWidget {
  final PromotionModel promotion;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onDelete;
  final VoidCallback onCopyCode;

  const PromotionCard({
    super.key,
    required this.promotion,
    required this.onToggleActive,
    required this.onDelete,
    required this.onCopyCode,
  });

  // ✅ FORMAT VALUE (CENTS → UI)
  String _formattedValue(PromotionModel promotion) {
    if (promotion.type == "percent") {
      return "${promotion.value}%";
    }

    // fixed → cents to dollars
    return "\$${(promotion.value / 100).toStringAsFixed(2)}";
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpired = promotion.expiresAt?.isBefore(DateTime.now()) ?? false;
    final Color emerald = const Color(0xFF2D6A4F);
    final Color mint = const Color(0xFF52B788);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left Discount Badge
            Container(
              width: 85,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isExpired ? [Colors.grey, Colors.blueGrey] : [emerald, mint],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formattedValue(promotion),
                    style: const TextStyle(
                      color: Colors.white, // or remove if not needed
                      fontWeight: FontWeight.w900,
                      fontSize: 18, // or 20 if you prefer
                    ),
                  ),

                  const Text("OFF", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(promotion.code, style: TextStyle(fontWeight: FontWeight.bold, color: emerald, fontSize: 16)),
                        IconButton(onPressed: onCopyCode, icon: Icon(Icons.copy, size: 14, color: mint), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isExpired ? "EXPIRED" : (promotion.isActive ? "ACTIVE" : "PAUSED"),
                      style: TextStyle(
                        color: isExpired ? Colors.red : (promotion.isActive ? mint : Colors.orange),
                        fontSize: 11, fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (promotion.endsat != null)
                      Text("Expires: ${promotion.endsat!.split(' ')[0]}", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  ],
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(value: promotion.isActive, onChanged: onToggleActive, activeColor: mint),
                  ),
                  IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}