// lib/screen/order/order_success_screen.dart
import 'package:flutter/material.dart';

import '../widget/receipt_card.dart';
import '../widget/success_actions.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderSuccessScreen({super.key, required this.orderData});

  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  // helper: parse cents/dollars into double dollars
  double _parseAmountToDollars(dynamic v) {
    if (v == null) return 0.0;
    if (v is int) {
      // treat int as cents
      return v / 100.0;
    }
    if (v is double) return v;
    if (v is String) {
      final s = v.replaceAll(',', '').trim();
      if (s.isEmpty) return 0.0;
      // contains '.' => dollars
      if (s.contains('.')) {
        final d = double.tryParse(s);
        return d ?? 0.0;
      }
      // otherwise try int: ambiguous => treat as cents if length > 3, else dollars
      final n = int.tryParse(s);
      if (n == null) return 0.0;
      return (s.length > 3) ? (n / 100.0) : n.toDouble();
    }
    return 0.0;
  }

  DateTime _parsePlacedAt(dynamic v) {
    try {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      final s = v.toString();
      return DateTime.tryParse(s) ?? DateTime.now();
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Safely extract data from orderData map ---
    final int id = (orderData['id'] is int) ? orderData['id'] as int : int.tryParse('${orderData['id'] ?? 0}') ?? 0;
    (orderData['status'] ?? 'Placed').toString();

    final DateTime placedAt = _parsePlacedAt(orderData['placedat'] ?? orderData['placed_at'] ?? orderData['placedAt']);

    final double subtotal = orderData.containsKey('subtotal')
        ? _parseAmountToDollars(orderData['subtotal'])
        : _parseAmountToDollars(orderData['subtotalcents'] ?? orderData['subtotal_cents'] ?? orderData['subtotalCents']);

    final double discount = orderData.containsKey('discount')
        ? _parseAmountToDollars(orderData['discount'])
        : _parseAmountToDollars(orderData['discountcents'] ?? orderData['discount_cents'] ?? orderData['discountCents']);

    final double total = orderData.containsKey('total')
        ? _parseAmountToDollars(orderData['total'])
        : _parseAmountToDollars(orderData['totalcents'] ?? orderData['total_cents'] ?? orderData['totalCents']);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top row back icon (keeps centered content visually balanced)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.black87,
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // 1. Animated Success Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _freshMintGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: _freshMintGreen, size: 80),
            ),

            const SizedBox(height: 24),

            // 2. Success Message
            Text(
              "Order Placed Successfully!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _espressoBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Thank you for your order. We are preparing it now.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),

            const SizedBox(height: 40),

            // 3. Receipt Card (extracted widget) - pass extracted values
            ReceiptCard(
              id: id,
              placedAt: placedAt,
              subtotal: subtotal,
              discount: discount,
              total: total,
              bgGrey: _bgGrey,
              espressoBrown: _espressoBrown,
              freshMintGreen: _freshMintGreen,
            ),

            const Spacer(flex: 2),

            // 4. Buttons (extracted widget)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SuccessActions(
                orderData: orderData,
                freshMintGreen: _freshMintGreen,
                espressoBrown: _espressoBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
