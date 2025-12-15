enum PaymentMethod {
  stripe, // card, apple pay, google pay
  khqr,   // ABA / Bakong
  wallet,
  cash,
}

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

    case 'wallet':
      return PaymentMethod.wallet;

    case 'cash':
      return PaymentMethod.cash;

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
    case PaymentMethod.wallet:
      return 'wallet';
    case PaymentMethod.cash:
      return 'cash';
  }
}
