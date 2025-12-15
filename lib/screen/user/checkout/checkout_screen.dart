import 'package:flutter/material.dart';
import 'package:frontend/screen/user/checkout/widgets/payment_method_selector.dart';
import '../../../models/payment_method.dart';
import 'widgets/section_header.dart';
import 'widgets/cart_item_card.dart';
import 'widgets/notes_input.dart';
import 'widgets/promo_tile.dart';
import 'widgets/payment_summary_card.dart';
import 'widgets/place_order_button.dart';
import 'widgets/empty_cart.dart';


PaymentMethod _selectedPayment = PaymentMethod.stripe;

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}
class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod _selectedPayment = PaymentMethod.stripe;

  @override
  Widget build(BuildContext context) {
    final bool isCartEmpty = false;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Checkout",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: isCartEmpty
          ? const EmptyCart()
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: "Order Details"),
                  const SizedBox(height: 12),
                  const CartItemCard(),

                  const SizedBox(height: 24),
                  const SectionHeader(title: "Notes"),
                  const SizedBox(height: 8),
                  const NotesInput(),

                  const SizedBox(height: 24),
                  const SectionHeader(title: "Order Discount"),
                  const SizedBox(height: 12),
                  const PromoTile(),

                  const SizedBox(height: 24),
                  const SectionHeader(title: "Payment Method"),
                  const SizedBox(height: 12),

                  /// 🔽 PAYMENT METHOD SELECTOR
                  PaymentMethodSelector(
                    selected: _selectedPayment,
                    onChanged: (method) {
                      setState(() {
                        _selectedPayment = method;
                      });
                    },
                  ),

                  const SizedBox(height: 24),
                  const SectionHeader(title: "Payment Details"),
                  const SizedBox(height: 12),
                  const PaymentSummaryCard(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          PlaceOrderButton(
            paymentMethod: _selectedPayment,
          ),
        ],
      ),
    );
  }
}

