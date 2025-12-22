// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as context show read;
//
// import '../../controller/cart_controller.dart';
//
//
// void showPromoDialog(BuildContext context) {
//   showDialog(
//     context: context,
//     builder: (_) {
//       final c = context.context.read<CartController>();
//       return AlertDialog(
//         title: const Text("Promo Code"),
//         content: TextField(
//           controller: c.promoController,
//           decoration: const InputDecoration(hintText: "Enter code"),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               await c.applyPromo(context);
//               Navigator.pop(context);
//             },
//             child: const Text("Apply"),
//           ),
//         ],
//       );
//     },
//   );
// }
//
// extension on BuildContext {
//   get context => null;
// }
