// import 'package:flutter/material.dart';
// import '../../controller/cart_controller.dart';
//
//
// class SummaryCard extends StatelessWidget {
//   final CartController controller;
//
//   const SummaryCard({super.key, required this.controller});
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Column(
//         children: [
//           _row("Subtotal", controller.subtotal),
//           _row("Discount", -controller.discount),
//           const Divider(),
//           _row("Total", controller.total, bold: true),
//         ],
//       ),
//     );
//   }
//
//   Widget _row(String label, double value, {bool bold = false}) {
//     return Padding(
//       padding: const EdgeInsets.all(8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label),
//           Text(
//             "\$${value.toStringAsFixed(2)}",
//             style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
//           ),
//         ],
//       ),
//     );
//   }
// }
