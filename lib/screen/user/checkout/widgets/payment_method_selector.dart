import 'package:flutter/material.dart';

import '../../../../models/payment_method.dart';


class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod value;
  final ValueChanged<PaymentMethod> onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: PaymentMethod.values.map((method) {
        return RadioListTile<PaymentMethod>(
          value: method,
          groupValue: value,
          onChanged: (v) => onChanged(v!),
          title: Text(method.name.toUpperCase()),
        );
      }).toList(),
    );
  }
}
