import 'package:flutter/material.dart';

class ShopsProductsPage extends StatefulWidget {
  const ShopsProductsPage({super.key});

  @override
  State<ShopsProductsPage> createState() => _ShopsProductsPageState();
}

class _ShopsProductsPageState extends State<ShopsProductsPage> {
  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  // --- Static Data ---
  final List<Map<String, dynamic>> _products = [
    {
      'id': 1,
      'name': 'Caramel Macchiato',
      'price': 4.50,
      'category': 'Coffee',
      'image': 'https://upload.wikimedia.org/wikipedia/commons/4/46/Caramel_Macchiato.jpg',
      'active': true,
    },
    {
      'id': 2,
      'name': 'Blueberry Muffin',
      'price': 3.00,
      'category': 'Bakery',
      'image': '', // No image test
      'active': true,
    },
    {
      'id': 3,
      'name': 'Green Tea',
      'price': 2.50,
      'category': 'Tea',
      'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Green_Tea.jpg/1200px-Green_Tea.jpg',
      'active': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "PRODUCTS",
          style: TextStyle(color: _espressoBrown, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 1.0),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add product logic
        },
        backgroundColor: _espressoBrown,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search products...",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // 2. Product List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildProductRow(_products[index]);
              },
              childCount: _products.length,
            ),
          ),
          
          // Bottom padding for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> product) {
    bool isActive = product['active'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? Colors.transparent : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Stack(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (product['image'] != '')
                    ? Image.network(
                        product['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.grey),
                      )
                    : Icon(Icons.coffee, color: _freshMintGreen),
              ),
            ),
            if(!isActive)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Icon(Icons.visibility_off, size: 20, color: Colors.black54)),
                ),
              )
          ],
        ),
        title: Text(
          product['name'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.black87 : Colors.grey,
          ),
        ),
        subtitle: Text(
          "${product['category']} • \$${product['price'].toStringAsFixed(2)}",
          style: TextStyle(color: isActive ? _freshMintGreen : Colors.grey[400], fontWeight: FontWeight.w600),
        ),
        trailing: Switch(
          value: isActive,
          activeColor: _freshMintGreen,
          onChanged: (val) {
            setState(() {
              product['active'] = val;
            });
          },
        ),
      ),
    );
  }
}