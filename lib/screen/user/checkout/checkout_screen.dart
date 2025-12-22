// import 'package:flutter/material.dart';
// import 'package:frontend/screen/user/checkout/widgets/cart_item_card.dart';
// import 'cart_state.dart';
// import 'widgets/section_header.dart';
//
// import 'widgets/payment_method_selector.dart';
//
// class CartScreen extends StatefulWidget {
//   const CartScreen({super.key, required int shopId});
//
//   @override
//   State<CartScreen> createState() => _CartScreenState();
// }
//
// class _CartScreenState extends State<CartScreen>
//     with CartState<CartScreen> {
//
//   @override
//   void initState() {
//     super.initState();
//
//     cartItems.add({
//       'name': 'Coffee',
//       'price': 3.5,
//       'qty': 2,
//     });
//
//     recalculateSubtotal();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Checkout")),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           const SectionHeader("Order Items"),
//           ...cartItems.map(CartItemTile.new),
//
//           const SizedBox(height: 20),
//           const SectionHeader("Payment Method"),
//           PaymentMethodSelector(
//             value: selectedPayment,
//             onChanged: (v) => setState(() => selectedPayment = v),
//           ),
//
//           const SizedBox(height: 20),
//           Text("Total: \$${total.toStringAsFixed(2)}"),
//         ],
//       ),
//     );
//   }
// }
