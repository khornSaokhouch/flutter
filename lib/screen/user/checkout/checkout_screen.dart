// import 'package:flutter/material.dart';
// import 'package:frontend/screen/user/checkout/widgets/bank_payment.dart';
// import 'package:frontend/screen/user/checkout/widgets/cart_item_card.dart';
// import 'package:frontend/screen/user/checkout/widgets/empty_cart.dart';
// import 'package:frontend/screen/user/checkout/widgets/khqr_payment.dart';
// import 'package:frontend/screen/user/checkout/widgets/payment_method_selector.dart';
// import 'package:frontend/screen/user/checkout/widgets/payment_summary_card.dart';
// import 'package:frontend/screen/user/checkout/widgets/place_order_button.dart';
// import 'package:frontend/screen/user/checkout/widgets/stripe_payment.dart';
//
// import '../../../models/order_model.dart';
// import '../../../models/payment_method.dart';
// import '../../../server/order_service.dart';
// import '../store_screen/order_success_screen.dart';
//
//
//
// class CartScreen extends StatefulWidget {
//   final int shopId;
//   final int? userId;
//
//   const CartScreen({super.key, required this.shopId, this.userId});
//
//   @override
//   State<CartScreen> createState() => _CartScreenState();
// }
//
// class _CartScreenState extends State<CartScreen> {
//   final List<Map<String, dynamic>> cartItems = [
//     {'id': 1, 'name': 'Coffee', 'price': 2.5, 'qty': 2}
//   ];
//
//   final TextEditingController noteController = TextEditingController();
//   PaymentMethod paymentMethod = PaymentMethod.stripe;
//   bool loading = false;
//
//   double get subtotal =>
//       cartItems.fold(0, (s, i) => s + i['price'] * i['qty']);
//   double get total => subtotal;
//   int toCents(double v) => (v * 100).round();
//
//   Future<void> placeOrder() async {
//     if (loading) return;
//     setState(() => loading = true);
//
//     try {
//       final order = await OrderService().createOrder(
//         OrderModel(
//           userid: widget.userId ?? 0,
//           shopid: widget.shopId,
//           status: 'pending_payment',
//           subtotalcents: toCents(subtotal),
//           discountcents: 0,
//           totalcents: toCents(total),
//           placedat: DateTime.now().toIso8601String(),
//           orderItems: [],
//         ),
//       );
//
//       bool paid = false;
//       switch (paymentMethod) {
//         case PaymentMethod.stripe:
//           paid = await payWithStripe(order.id!, total, widget.userId);
//           break;
//         case PaymentMethod.khqr:
//           paid = await payWithKHQR(context, order.id!, total);
//           break;
//         case PaymentMethod.bank:
//           paid = await payWithBank(context);
//           break;
//       }
//
//       if (!paid) return;
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => OrderSuccessScreen(orderData: order.toJson()),
//         ),
//       );
//     } finally {
//       setState(() => loading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Checkout")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             CartItemsWidget(cartItems: cartItems),
//             NotesWidget(controller: noteController),
//             PaymentMethodWidget(
//               value: paymentMethod,
//               onChanged: (v) => setState(() => paymentMethod = v),
//             ),
//             PaymentSummaryWidget(subtotal: subtotal, total: total),
//             const Spacer(),
//             PlaceOrderButton(
//               loading: loading,
//               onPressed: placeOrder,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
