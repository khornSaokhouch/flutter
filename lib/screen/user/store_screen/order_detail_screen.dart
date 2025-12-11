import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailScreen({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    final int id = orderData['id'] ?? 0;
    final String status = orderData['status'] ?? 'Placed';
    final DateTime placedAt = DateTime.tryParse(orderData['placedat'].toString()) ?? DateTime.now();
    final double subtotal = (orderData['subtotalcents'] ?? 0) / 100;
    final double discount = (orderData['discountcents'] ?? 0) / 100;
    final double total = (orderData['totalcents'] ?? 0) / 100;
    final List<dynamic> items = orderData['items'] is List ? orderData['items'] as List<dynamic> : [];

    return Scaffold(
      appBar: AppBar(
        title: Text("Order #$id"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status & Date
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status", style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 6),
                      Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Placed", style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 6),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Items list
          Text("Items", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text("No item details available.", style: TextStyle(color: Colors.grey[600])),
            )
          else
            ...items.map((item) {
              // assume item is Map with name, qty, pricecents
              final name = (item is Map && item['name'] != null) ? item['name'].toString() : 'Item';
              final qty = (item is Map && item['quantity'] != null) ? item['quantity'] : (item is Map && item['qty'] != null ? item['qty'] : 1);
              final price = (item is Map && item['pricecents'] != null) ? (item['pricecents'] / 100) : (item is Map && item['price'] != null ? (item['price'] as num).toDouble() : 0.0);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(name),
                  subtitle: Text("Qty: $qty"),
                  trailing: Text("\$${price.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            }).toList(),

          const SizedBox(height: 12),

          // Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  _summaryRow("Subtotal", subtotal),
                  if (discount > 0) ...[
                    const SizedBox(height: 8),
                    _summaryRow("Discount", -discount, isDiscount: true),
                  ],
                  const Divider(),
                  _summaryRow("Total Paid", total, isBold: true),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Example action row (reorder, contact support)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Example: trigger reorder or open chat
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reorder tapped')));
                  },
                  child: const Text("Reorder"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Example: contact support
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact support tapped')));
                  },
                  child: const Text("Contact Support"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isDiscount = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(
          "${amount < 0 ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}",
          style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: isDiscount ? Colors.red : Colors.black87),
        ),
      ],
    );
  }
}