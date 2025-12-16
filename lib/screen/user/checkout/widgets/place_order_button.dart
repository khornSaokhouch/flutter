import 'package:flutter/material.dart';

class PlaceOrderButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const PlaceOrderButton({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text("Place Order"),
    );
  }
}
