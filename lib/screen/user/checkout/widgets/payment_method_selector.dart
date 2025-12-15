import 'package:flutter/material.dart';
import '../../../../models/payment_method.dart';
// adjust import

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _tile(
          method: PaymentMethod.stripe,
          icon: Icons.credit_card,
          title: "Card / Apple Pay / Google Pay",
          subtitle: "Visa, Mastercard, Apple Pay",
        ),
        _tile(
          method: PaymentMethod.khqr,
          icon: Icons.qr_code,
          title: "KHQR",
          subtitle: "ABA / Bakong",
        ),
        _tile(
          method: PaymentMethod.wallet,
          icon: Icons.account_balance_wallet_outlined,
          title: "Wallet",
          subtitle: "Use wallet balance",
        ),
        _tile(
          method: PaymentMethod.cash,
          icon: Icons.payments_outlined,
          title: "Cash",
          subtitle: "Pay on delivery",
        ),
      ],
    );
  }

  Widget _tile({
    required PaymentMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = selected == method;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF4E8D7C) : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: () => onChanged(method),
        leading: Icon(icon,
            color: isSelected ? const Color(0xFF4E8D7C) : Colors.black54),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF4E8D7C) : Colors.black,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFF4E8D7C))
            : const Icon(Icons.radio_button_unchecked),
      ),
    );
  }
}
