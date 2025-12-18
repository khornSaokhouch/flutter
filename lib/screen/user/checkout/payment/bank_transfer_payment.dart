import 'package:flutter/material.dart';

class BankTransferExampleScreen extends StatefulWidget {
  const BankTransferExampleScreen({super.key});

  @override
  State<BankTransferExampleScreen> createState() =>
      _BankTransferExampleScreenState();
}

class _BankTransferExampleScreenState
    extends State<BankTransferExampleScreen> {
  int orderId = 1001;

  /// MAIN HANDLER
  Future<bool> handleBankTransfer(int orderId) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Bank Transfer"),
        content: const Text(
          "Please transfer to:\n\n"
              "ABA Bank\n"
              "Account: 123-456-789\n\n"
              "Then contact support.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Done"),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// AFTER PAYMENT LOGIC
  Future<void> onPayNow() async {
    final success = await handleBankTransfer(orderId);

    if (!mounted) return;

    if (success) {
      // TODO: call backend API (mark order as PENDING)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order placed. Waiting for bank verification."),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bank transfer cancelled."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Center(
        child: ElevatedButton(
          onPressed: onPayNow,
          child: const Text("Pay with Bank Transfer"),
        ),
      ),
    );
  }
}
