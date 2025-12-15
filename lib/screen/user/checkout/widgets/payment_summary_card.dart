import 'package:flutter/material.dart';

class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _row("Subtotal", "\$3.50"),
          const SizedBox(height: 8),
          _row("Discount", "-\$0.50", red: true),
          const Divider(height: 32),
          _row("Total Payment", "\$3.00", big: true),
        ],
      ),
    );
  }

  static Widget _row(String label, String value,
      {bool red = false, bool big = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: big ? 16 : 14, fontWeight: FontWeight.w600)),
        Text(
          value,
          style: TextStyle(
            fontSize: big ? 20 : 14,
            fontWeight: FontWeight.bold,
            color: red ? Colors.red : Colors.black,
          ),
        ),
      ],
    );
  }
}
