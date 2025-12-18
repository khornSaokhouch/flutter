import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../../server/payment_service.dart';


Future<bool> handleStripePayment(int orderId) async {
  final resp = await StripeService.createPaymentIntent(
    amount: 0, // override before calling
    currency: 'usd',
    orderId: orderId,
  );

  await Stripe.instance.initPaymentSheet(
    paymentSheetParameters: SetupPaymentSheetParameters(
      paymentIntentClientSecret: resp['client_secret'],
      merchantDisplayName: 'Your Shop',
    ),
  );

  await Stripe.instance.presentPaymentSheet();
  return true;
}
