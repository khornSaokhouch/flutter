// screens/payment_history_screen.dart
import 'package:flutter/material.dart';

import '../../models/payment_model.dart';
import '../../server/payment_service.dart';


class PaymentHistoryScreen extends StatelessWidget {
  final int userId;

  const PaymentHistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: FutureBuilder<List<PaymentModel>>(
        future: StripeService.getPaymentsByUser(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final payments = snapshot.data!;

          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, i) {
              final p = payments[i];

              return ListTile(
                leading: Icon(
                  p.paymentMethod == 'card'
                      ? Icons.credit_card
                      : Icons.account_balance_wallet,
                ),
                title: Text(
                  '\$${(p.amountCents / 100).toStringAsFixed(2)}',
                ),
                subtitle: Text(
                  '${p.paymentMethod ?? 'Unknown'} • ${p.status}',
                ),
                trailing: Text(
                  p.createdAt.toString(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
