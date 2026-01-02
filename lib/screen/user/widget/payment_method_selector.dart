import 'package:flutter/material.dart';

// Moved the Enum here so it's shared
enum PaymentMethod { stripe, khqr, bankTransfer }

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod> onChanged;

  // Use your app's specific colors
  final Color primaryColor = const Color(0xFF4E8D7C); // Fresh Mint Green
  final Color titleColor = const Color(0xFF4B2C20);   // Espresso Brown

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _paymentTile(
          title: "Credit / Debit Card",
          subtitle: "Visa, MasterCard",
          value: PaymentMethod.stripe,
          icon: Icons.credit_card,
        ),
        const SizedBox(height: 12),
        _paymentTile(
          title: "KHQR",
          subtitle: "ABA, Acleda, Wing",
          value: PaymentMethod.khqr,
          icon: Icons.qr_code_scanner,
        ),
        const SizedBox(height: 12),
        _paymentTile(
          title: "Bank Transfer",
          subtitle: "Pay via bank slip",
          value: PaymentMethod.bankTransfer,
          icon: Icons.account_balance,
        ),
      ],
    );
  }

  Widget _paymentTile({
    required String title,
    required String subtitle,
    required PaymentMethod value,
    required IconData icon,
  }) {
    final isSelected = selectedMethod == value;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryColor : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? titleColor : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Custom Radio Indicator
            Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                child: Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}