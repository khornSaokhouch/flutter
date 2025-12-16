import 'package:flutter/material.dart';

class PaymentSummaryWidget extends StatelessWidget {
  final double subtotal;
  final double total;

  const PaymentSummaryWidget({
    super.key,
    required this.subtotal,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row("Subtotal", subtotal),
        _row("Total", total, bold: true),
      ],
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          "\$${value.toStringAsFixed(2)}",
          style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }
}
