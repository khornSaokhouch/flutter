// import 'package:flutter/material.dart';
// import 'package:flutter_stripe/flutter_stripe.dart' hide PaymentMethod;
//

// import '../../../server/payment_service.dart';
// import '../checkout/widgets/aba_khqr_dialog.dart';
// import '../checkout/widgets/payment_method_selector.dart';
//
// class CartController extends ChangeNotifier {
//   // ================= STATE =================
//   PaymentMethod selectedPayment = PaymentMethod.stripe;
//
//   double total = 0;
//   bool isPaying = false;
//
//   final int? userId;
//
//   CartController({this.userId});
//
//   // ================= ROUTER =================
//   Future<bool> processPayment({
//     required BuildContext context,
//     required int orderId,
//     required double totalAmount,
//   }) async {
//     total = totalAmount;
//
//     switch (selectedPayment) {
//       case PaymentMethod.stripe:
//         return handleStripePayment(
//           context: context,
//           orderId: orderId,
//         );
//
//       case PaymentMethod.khqr:
//         return handleKHQRPayment(
//           context: context,
//           orderId: orderId,
//         );
//
//       case PaymentMethod.bankTransfer:
//         return handleBankTransfer(
//           context: context,
//           orderId: orderId,
//         );
//     }
//   }
//
//   // ================= STRIPE =================
//   int _toCents(double amount) => (amount * 100).round();
//
//   Future<bool> handleStripePayment({
//     required BuildContext context,
//     required int orderId,
//   }) async {
//     isPaying = true;
//     notifyListeners();
//
//     try {
//       final resp = await StripeService.createPaymentIntent(
//         amount: _toCents(total),
//         currency: 'usd',
//         orderId: orderId,
//         userId: userId,
//       );
//
//       final clientSecret =
//           resp['client_secret'] ?? resp['clientSecret'];
//       final publishableKey =
//           resp['publishableKey'] ?? resp['publishable_key'];
//
//       if (publishableKey is String && publishableKey.isNotEmpty) {
//         Stripe.publishableKey = publishableKey;
//         await Stripe.instance.applySettings();
//       }
//
//       if (clientSecret == null) {
//         throw Exception('Missing client secret');
//       }
//
//       await Stripe.instance.initPaymentSheet(
//         paymentSheetParameters: SetupPaymentSheetParameters(
//           paymentIntentClientSecret: clientSecret,
//           merchantDisplayName: 'Your Shop',
//         ),
//       );
//
//       await Stripe.instance.presentPaymentSheet();
//       return true;
//     } catch (e) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(SnackBar(content: Text('Payment failed: $e')));
//       }
//       return false;
//     } finally {
//       isPaying = false;
//       notifyListeners();
//     }
//   }
//
//   // ================= KHQR =================
//   Future<bool> handleKHQRPayment({
//     required BuildContext context,
//     required int orderId,
//   }) async {
//     const currency = 'USD';
//
//     isPaying = true;
//     notifyListeners();
//
//     try {
//       final resp = await ABAPaymentService.createKHQR(
//         orderId: orderId,
//         amount: total,
//         currency: currency,
//       );
//
//       final paid = await showDialog<bool>(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => ABAKHQRDialog(
//           orderId: orderId,
//           qrImageBase64: resp['qrImage'],
//           deeplink: resp['abapay_deeplink'],
//           currency: currency,
//         ),
//       );
//
//       return paid == true;
//     } catch (e) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(SnackBar(content: Text('Payment error: $e')));
//       }
//       return false;
//     } finally {
//       isPaying = false;
//       notifyListeners();
//     }
//   }
//
//   // ================= BANK =================
//   Future<bool> handleBankTransfer({
//     required BuildContext context,
//     required int orderId,
//   }) async {
//     await showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Bank Transfer"),
//         content: const Text(
//           "Please transfer to:\n\n"
//               "ABA Bank\nAccount: 123-456-789\n\n"
//               "Then contact support.",
//         ),
//         actions: [
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Done"),
//           ),
//         ],
//       ),
//     );
//
//     return true;
//   }
// }
