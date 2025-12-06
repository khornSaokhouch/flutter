import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  final dynamic item;
  final int quantity;
  final double subtotal;
  final List selectedModifiers;

  const CartScreen({
    super.key,
    required this.item,
    required this.quantity,
    required this.subtotal,
    required this.selectedModifiers,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}


class _CartScreenState extends State<CartScreen> {
  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  // --- Static Data ---
  final List<Map<String, dynamic>> _cartItems = [
    {
      'id': 1,
      'name': 'Iced Americano',
      'image': 'https://upload.wikimedia.org/wikipedia/commons/0/09/Iced_coffee.jpg',
      'price': 3.50,
      'qty': 1,
      'options': 'Large, No Sugar, Less Ice'
    },
    {
      'id': 2,
      'name': 'Croissant',
      'image': 'https://upload.wikimedia.org/wikipedia/commons/2/28/2018_01_Croissant_IMG_0685.JPG',
      'price': 2.80,
      'qty': 2,
      'options': 'Warmed'
    },
    {
      'id': 3,
      'name': 'Matcha Latte',
      'image': 'https://upload.wikimedia.org/wikipedia/commons/d/d8/Matcha_Latte.jpg',
      'price': 4.25,
      'qty': 1,
      'options': 'Medium, Oat Milk'
    },
  ];

  double get _subtotal {
    return _cartItems.fold(0, (sum, item) => sum + (item['price'] * item['qty']));
  }

  double get _tax => _subtotal * 0.05; // 5% tax
  double get _total => _subtotal + _tax;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "MY ORDER",
          style: TextStyle(
            color: _espressoBrown,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Order List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _cartItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildCartItem(_cartItems[index], index);
              },
            ),
          ),

          // 2. Bill Details
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Summary Rows
                    _buildSummaryRow("Subtotal", _subtotal),
                    const SizedBox(height: 8),
                    _buildSummaryRow("Tax (5%)", _tax),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _espressoBrown,
                          ),
                        ),
                        Text(
                          "\$${_total.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _freshMintGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Checkout Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Order Placed Successfully!"),
                              backgroundColor: _freshMintGreen,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _espressoBrown,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          "Checkout",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- Widgets ---

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return Dismissible(
      key: Key(item['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (direction) {
        setState(() {
          _cartItems.removeAt(index);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item['image'],
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Icon(Icons.coffee, color: Colors.grey[400]),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _espressoBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['options'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "\$${(item['price'] * item['qty']).toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _freshMintGreen,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity Controls
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        item['qty']++;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.add, size: 16, color: _espressoBrown),
                    ),
                  ),
                  Text(
                    "${item['qty']}",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _espressoBrown),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (item['qty'] > 1) {
                          item['qty']--;
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.remove, size: 16, color: _espressoBrown),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 15, color: Colors.grey[600]),
        ),
        Text(
          "\$${amount.toStringAsFixed(2)}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}