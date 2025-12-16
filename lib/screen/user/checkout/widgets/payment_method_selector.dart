import 'package:flutter/material.dart';

import '../../../../models/payment_method.dart';


class PaymentMethodWidget extends StatelessWidget {
  final PaymentMethod value;
  final ValueChanged<PaymentMethod> onChanged;

  const PaymentMethodWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: PaymentMethod.values.map((m) {
        return RadioListTile(
          value: m,
          groupValue: value,
          onChanged: (v) => onChanged(v!),
          title: Text(m.name.toUpperCase()),
        );
      }).toList(),
    );
  }
}
