import '../../../models/promotion_model.dart';

double computeDiscount(
    PromotionAdapter promo,
    double subtotal,
    ) {
  final int subtotalCents = (subtotal * 100).round();
  int discountCents = 0;

  switch (promo.type) {
    case PromotionType.percentage:
      discountCents =
          ((subtotalCents * promo.value) / 100).round();
      break;

    case PromotionType.fixed:
      discountCents = promo.value.round();
      break;

    default:
      discountCents = 0;
  }

  return (discountCents.clamp(0, subtotalCents)) / 100;
}
