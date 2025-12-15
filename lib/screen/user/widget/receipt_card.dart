// lib/screen/order/widgets/receipt_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/date_utils.dart';


class ReceiptCard extends StatelessWidget {
  final int id;
  final DateTime placedAt;
  final double subtotal;
  final double discount;
  final double total;

  // styling passed from parent
  final Color bgGrey;
  final Color espressoBrown;
  final Color freshMintGreen;

  const ReceiptCard({
    super.key,
    required this.id,
    required this.placedAt,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.bgGrey,
    required this.espressoBrown,
    required this.freshMintGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _row("Order ID", "#$id", colorRight: Colors.black87),
          const SizedBox(height: 12),
          _row("Date", formatPlacedAtShort(placedAt)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.grey),
          ),
          _detailRow("Subtotal", subtotal),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _detailRow("Discount", -discount, isDiscount: true),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Paid", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: espressoBrown)),
              Text(
                NumberFormat.currency(locale: 'en_US', symbol: '\$').format(total),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: freshMintGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String left, String right, {Color? colorRight}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(left, style: TextStyle(color: Colors.grey[600])),
        Text(right, style: TextStyle(fontWeight: FontWeight.bold, color: colorRight ?? Colors.black87)),
      ],
    );
  }

  Widget _detailRow(String label, double amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(
          "${amount < 0 ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDiscount ? Colors.red : Colors.black87,
          ),
        ),
      ],
    );
  }
}
