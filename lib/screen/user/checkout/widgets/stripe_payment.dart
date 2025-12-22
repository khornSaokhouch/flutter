import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../../server/payment_service.dart';


Future<bool> payWithStripe(int orderId, double total, int? userId) async {
  final res = await StripeService.createPaymentIntent(
    amount: (total * 100).round(),
    currency: 'usd',
    orderId: orderId,
    userId: userId,
  );

  Stripe.publishableKey = res['publishableKey'];
  await Stripe.instance.applySettings();

  await Stripe.instance.initPaymentSheet(
    paymentSheetParameters: SetupPaymentSheetParameters(
      paymentIntentClientSecret: res['client_secret'],
      merchantDisplayName: 'Shop',
    ),
  );

  try {
    await Stripe.instance.presentPaymentSheet();
    return true;
  } catch (_) {
    return false;
  }
}
