import 'package:flutter/material.dart';
import 'package:frontend/models/payment_method.dart';

class PlaceOrderButton extends StatelessWidget {
  const PlaceOrderButton({super.key, required PaymentMethod paymentMethod});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, -5),
            color: Colors.black12,
          )
        ],
      ),
      child: SizedBox(
        height: 55,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4E8D7C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            "Place Order",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
