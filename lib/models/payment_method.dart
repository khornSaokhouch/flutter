enum PaymentMethod { stripe, khqr, bank }

/// Helpers for API conversion
PaymentMethod? paymentMethodFromString(String? value) {
  switch (value) {
    case 'stripe':
    case 'card':
    case 'visa':
    case 'klarna':
      return PaymentMethod.stripe;

    case 'khqr':
    case 'aba':
    case 'bakong':
    case 'bank_transfer':
      return PaymentMethod.khqr;



    default:
      return null;
  }
}

String paymentMethodToString(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.stripe:
      return 'stripe';
    case PaymentMethod.khqr:
      return 'khqr';

      return 'wallet';
    case PaymentMethod.bank:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
