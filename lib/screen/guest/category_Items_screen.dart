import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../server/category_service.dart';
import './guest_store_screen/guest_detail_item.dart';

class CategoryItemsScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryItemsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  late Future<List<Item>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = CategoryService.fetchItemsByCategory(widget.categoryId);
  }

  String formatPrice(String? priceCents) {
    if (priceCents == null) return '';
    final s = priceCents.trim();
    if (s.isEmpty) return '';

    // cents like "243"
    final cents = int.tryParse(s);
    if (cents != null) {
      return (cents / 100).toStringAsFixed(2);
    }

    // decimals like "2.43"
    final dbl = double.tryParse(s.replaceAll(',', '.'));
    if (dbl != null) {
      return dbl.toStringAsFixed(2);
    }

    return s;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // <- Set screen background to white
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: FutureBuilder<List<Item>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B4D3E)),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error loading items: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No items found for this category.'),
            );
          }

          final items = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];



              return Container(
                decoration: BoxDecoration(
                  color: Colors.white, // <- ListTile background
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                      
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: SizedBox(
                    width: 60,
                    height: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                          item.imageUrl ?? '',
                              fit: BoxFit.cover,
                              headers: const {"Connection": "Keep-Alive"},
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2));
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image,
                                    size: 40, color: Colors.grey);
                              },
                            )
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    item.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(formatPrice(item.priceCents),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4D3E),
                    ),
                  ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GuestDetailItem(
                      itemId: item.id, // make sure your Item model has an id field
                      shopId: item.id, // or pass a shopId you have
                    ),
                  ),
                );
              },

                ),
              );
            },
          );
        },
      ),
    );
  }
}
