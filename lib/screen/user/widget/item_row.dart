import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/format_utils.dart';

class ItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final NumberFormat moneyFmt;

  const ItemRow({
    super.key,
    required this.item,
    required this.moneyFmt,
  });

  /// Convert options / option_groups to displayable string
  String _parseOptions(dynamic v) {
    if (v == null) return '';

    // Already normalized (e.g. "S, More Iced")
    if (v is String) return v;

    // Backend format: List<Map>
    if (v is List) {
      return v
          .map((e) {
        if (e is Map<String, dynamic>) {
          return e['selected_option'] ??
              e['name'] ??
              '';
        }
        return '';
      })
          .where((e) => e.toString().isNotEmpty)
          .join(', ');
    }

    return '';
  }

  /// Resolve unit price safely from multiple possible keys
  double _parseUnitPrice(Map<String, dynamic> item) {
    if (item.containsKey('pricecents')) {
      return parseAmountToDollars(
        item['pricecents'],
        inputIsCentsIfInt: true,
      );
    }

    if (item.containsKey('unitprice')) {
      return parseAmountToDollars(
        item['unitprice'],
        inputIsCentsIfInt: false,
      );
    }

    if (item.containsKey('price')) {
      final p = item['price'];
      if (p is int) return p / 100.0;
      return parseAmountToDollars(p, inputIsCentsIfInt: false);
    }

    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final String name =
    (item['name'] ?? item['namesnapshot'] ?? item['title'] ?? 'Item')
        .toString();

    final String options = _parseOptions(
      item['options'] ?? item['option_groups'],
    );

    final int qty = parseIntSafe(
      item['qty'] ?? item['quantity'] ?? 1,
    );

    final double unitPrice = _parseUnitPrice(item);

    final String imgUrl = (item['image'] ??
        item['image_url'] ??
        item['item']?['image_url'] ??
        '')
        .toString();


    final String? notesRaw =
    (item['notes'] ?? item['note'])?.toString();
    final String notes =
    (notesRaw == null || notesRaw.trim().isEmpty) ? '' : notesRaw;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantity
          Text(
            "${qty}x  ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),

          // Item image
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imgUrl.isNotEmpty
                  ? Image.network(
                imgUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.coffee, size: 20, color: Colors.grey),
              )
                  : const Icon(Icons.coffee,
                  size: 20, color: Colors.grey),
            ),
          ),

          const SizedBox(width: 12),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),

                if (options.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      options,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),

                if (notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      notes,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Price
          Text(
            moneyFmt.format(unitPrice * qty),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
