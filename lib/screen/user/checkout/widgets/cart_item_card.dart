import 'package:flutter/material.dart';

class CartItemCard extends StatelessWidget {
  const CartItemCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.coffee, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("1x Latte",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Icon(Icons.edit_outlined,
                        size: 16, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 8),
                _row("Base Price", "\$3.50"),
                _row("Milk: Oat", ""),
                const SizedBox(height: 8),
                _row("Subtotal", "\$3.50", bold: true),
              ],
            ),
          )
        ],
      ),
    );
  }

  static Widget _row(String left, String right, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(left,
            style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        if (right.isNotEmpty)
          Text(right,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
      ],
    );
  }
}
