enum PaymentMethod {
  stripe,
  khqr,
  bankTransfer,
}

class PromotionNotFoundException implements Exception {
  final String? message;
  PromotionNotFoundException([this.message]);

  @override
  String toString() => message ?? 'PromotionNotFoundException';
}
