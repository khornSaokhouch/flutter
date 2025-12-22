import 'package:flutter/material.dart';

import '../../../models/payment_method.dart';


mixin CartState<T extends StatefulWidget> on State<T> {
  PaymentMethod selectedPayment = PaymentMethod.stripe;

  final List<Map<String, dynamic>> cartItems = [];
  double subtotal = 0.0;
  double discount = 0.0;

  bool isPlacingOrder = false;
  bool isPaying = false;
  bool isApplyingPromo = false;

  final promoController = TextEditingController();
  final noteController = TextEditingController();
  final noteFocusNode = FocusNode();

  double get total => (subtotal - discount).clamp(0.0, double.infinity);

  int toCents(double value) => (value * 100).round();

  double parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  int parseInt(dynamic v, {int fallback = 1}) {
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }

  void recalculateSubtotal() {
    subtotal = cartItems.fold(
      0.0,
          (sum, it) => sum + parseDouble(it['price']) * parseInt(it['qty']),
    );
    setState(() {});
  }
}
