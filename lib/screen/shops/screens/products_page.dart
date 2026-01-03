import 'package:flutter/material.dart';
import 'package:frontend/models/item_model.dart';
import 'package:frontend/server/item_service.dart';
import 'package:frontend/screen/shops/screens/add_product_page.dart'; // Will create this page

class ProductsPage extends StatefulWidget {
  final int shopId;
  const ProductsPage({super.key, required this.shopId});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<ShopItem> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final response = await ItemService.fetchItemsByShopCheckToken(widget.shopId);
      if (response != null && response.data.isNotEmpty) {
        setState(() {
          _products = response.data;
        });
      } else {
        setState(() {
          _errorMessage = 'No products found or failed to load.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching products: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _products.isEmpty
                  ? const Center(child: Text('No products available.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 2.0,
                          child: ListTile(
                            leading: product.item.imageUrl.isNotEmpty
                                ? Image.network(
                                    product.item.imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image, size: 50),
                                  )
                                : const Icon(Icons.image_not_supported, size: 50),
                            title: Text(
                              product.item.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Price: \$${(product.item.priceCents / 100).toStringAsFixed(2)}\n'
                              'Category: ${product.category.name}\n'
                              'Status: ${product.inactive == 0 ? 'Active' : 'Inactive'}',
                            ),
                            trailing: product.inactive == 0
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : const Icon(Icons.cancel, color: Colors.red),
                            isThreeLine: true,
                            onTap: () {
                              // TODO: Implement navigation to product detail page
                            },
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddProductPage(shopId: widget.shopId)),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}
