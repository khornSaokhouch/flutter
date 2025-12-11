import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import './order_detail_screen.dart';


class OrderSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderSuccessScreen({super.key, required this.orderData});

  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context) {
    // Data Parsing
    final int id = orderData['id'] ?? 0;
    final String status = orderData['status'] ?? 'Placed';
    final DateTime placedAt = DateTime.tryParse(orderData['placedat'].toString()) ?? DateTime.now();

    final double subtotal = (orderData['subtotalcents'] ?? 0) / 100;
    final double discount = (orderData['discountcents'] ?? 0) / 100;
    final double total = (orderData['totalcents'] ?? 0) / 100;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top row with back icon (left) - keeps centered content visually balanced
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.black87,
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // 1. Animated Success Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _freshMintGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: _freshMintGreen, size: 80),
            ),

            const SizedBox(height: 24),

            // 2. Success Message
            Text(
              "Order Placed Successfully!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _espressoBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Thank you for your order. We are preparing it now.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),

            const SizedBox(height: 40),

            // 3. Receipt Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _bgGrey,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Order ID", style: TextStyle(color: Colors.grey[600])),
                      Text("#$id", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Date", style: TextStyle(color: Colors.grey[600])),
                      Text(DateFormat('MMM dd, hh:mm a').format(placedAt), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Colors.grey),
                  ),
                  _buildDetailRow("Subtotal", subtotal),
                  if (discount > 0) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow("Discount", -discount, isDiscount: true),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total Paid", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _espressoBrown)),
                      Text(
                        "\$${total.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _freshMintGreen),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // 4. Buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Primary action: View Order Details (navigates to OrderDetailScreen)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(orderData: orderData),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _freshMintGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("View Order Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Secondary action: Track Order (placeholder - you can integrate tracking)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: replace with your tracking page/logic
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(orderData: orderData),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Track Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: Text("Back to Home", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, double amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(
          "${amount < 0 ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDiscount ? Colors.red : Colors.black87,
          ),
        ),
      ],
    );
  }
}



