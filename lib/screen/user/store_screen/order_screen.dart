import 'package:flutter/material.dart';
import 'dart:convert';

class CartScreen extends StatefulWidget {
  /// Now takes explicit fields for a single incoming item:
  /// - id
  /// - name
  /// - quantity
  /// - subtotal (used to infer price if provided)
  /// - selectedModifiers
  /// - imageUrl
  final String id;
  final String name;
  final int quantity; // used when a single item map is provided
  final double subtotal; // optional initial subtotal (we recalc anyway)
  final List selectedModifiers;
  final String imageUrl;

  const CartScreen({
    super.key,
    required this.name,
    this.id = '',
    this.quantity = 1,
    this.subtotal = 0.0,
    this.selectedModifiers = const [],
    this.imageUrl = '',
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  // internal cart representation
  final List<Map<String, dynamic>> _cartItems = [];

  // local subtotal (kept in sync)
  double _subtotalLocal = 0.0;

  double get _tax => _subtotalLocal * 0.05; // 5% tax
  double get _total => _subtotalLocal + _tax;

  @override
  void initState() {
    super.initState();

    // Build an incoming item using the explicit widget fields
    final incomingPrice = (widget.subtotal > 0 && widget.quantity > 0)
        ? (widget.subtotal / widget.quantity)
        : 0.0;

    final Map<String, dynamic> incoming = {
      'id': widget.id.isNotEmpty ? widget.id : UniqueKey().toString(),
      'name': widget.name,
      'price': incomingPrice,
      'qty': widget.quantity > 0 ? widget.quantity : 1,
      'modifiers': widget.selectedModifiers.isNotEmpty ? widget.selectedModifiers : [],
      'image': widget.imageUrl,
    };

    // Normalize and add/merge
    _addOrMergeItem(_normalizeItemMap(incoming));

    // compute initial subtotal
    _recalculateSubtotal();
  }

  Map<String, dynamic> _normalizeItemMap(Map<String, dynamic> raw) {
    // Build a normalized item map with safe types and fields the UI expects.
    final id = raw['id']?.toString() ?? UniqueKey().toString();
    final name = raw['name']?.toString() ?? 'Item';
    final price = (raw['price'] is num) ? (raw['price'] as num).toDouble() : 0.0;
    final qty = (raw['qty'] is int) ? raw['qty'] as int : int.tryParse('${raw['qty']}') ?? 1;
    final image = raw['image']?.toString() ?? widget.imageUrl;
    final modifiers = (raw['modifiers'] is List) ? List.from(raw['modifiers']) : <dynamic>[];
    final optionsFromModifiers = _buildOptionsText(modifiers);

    return {
      'id': id,
      'name': name,
      'price': price,
      'qty': qty,
      'image': image,
      // keep both: 'options' (string for UI) and 'modifiers' (structured)
      'options': (raw['options']?.toString().isNotEmpty == true) ? raw['options'] : optionsFromModifiers,
      'modifiers': modifiers,
    };
  }

  /// Merge if same id AND same modifiers (deep equality). Otherwise append new item.
  void _addOrMergeItem(Map<String, dynamic> item) {
    // Create a canonical key for modifiers (JSON string) for easy comparison
    final incomingModsKey = _modifiersKey(item['modifiers']);

    for (int i = 0; i < _cartItems.length; i++) {
      final existing = _cartItems[i];
      final existingModsKey = _modifiersKey(existing['modifiers']);
      if (existing['id'].toString() == item['id'].toString() && existingModsKey == incomingModsKey) {
        // merge quantities
        final existingQty = (existing['qty'] is int) ? existing['qty'] as int : int.tryParse('${existing['qty']}') ?? 1;
        final incomingQty = (item['qty'] is int) ? item['qty'] as int : int.tryParse('${item['qty']}') ?? 1;
        setState(() {
          _cartItems[i]['qty'] = existingQty + incomingQty;
        });
        return;
      }
    }

    // not found -> add new
    setState(() {
      _cartItems.add(item);
    });
  }

  String _modifiersKey(dynamic mods) {
    try {
      // sort to make order-insensitive if mods is a list of maps with keys
      if (mods is List) {
        final normalized = mods.map((m) {
          if (m is Map) {
            final sorted = Map.fromEntries(
              (m.entries.toList()..sort((a, b) => a.key.compareTo(b.key))),
            );
            return sorted;
          }
          return m;
        }).toList();
        return jsonEncode(normalized);
      }
      return jsonEncode(mods);
    } catch (_) {
      return mods.toString();
    }
  }

  String _buildOptionsText(List<dynamic> modifiers) {
    if (modifiers.isEmpty) return '';
    try {
      return modifiers
          .map((m) {
        if (m is Map) {
          final group = (m['group_name'] ?? m['group'] ?? m['groupId'] ?? '').toString();
          final sel = (m['selected_option'] ?? m['selected'] ?? m['option'] ?? '').toString();
          if (group.isEmpty && sel.isEmpty) return '';
          if (group.isEmpty) return sel;
          if (sel.isEmpty) return group;
          return "$group: $sel";
        } else {
          return m.toString();
        }
      })
          .where((s) => s.isNotEmpty)
          .join(", ");
    } catch (_) {
      return modifiers.join(", ");
    }
  }

  void _recalculateSubtotal() {
    double sum = 0.0;
    for (final it in _cartItems) {
      final price = (it['price'] is num) ? (it['price'] as num).toDouble() : 0.0;
      final qty = (it['qty'] is int) ? it['qty'] as int : int.tryParse('${it['qty']}') ?? 1;
      sum += price * qty;
    }
    setState(() {
      _subtotalLocal = sum;
    });
  }

  @override
  Widget build(BuildContext context) {
    // For debugging:
    // print('_cartItems: $_cartItems');
    // print('subtotal: $_subtotalLocal');

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
            child: _cartItems.isEmpty
                ? Center(child: Text("Your cart is empty", style: TextStyle(color: _espressoBrown)))
                : ListView.separated(
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
                    _buildSummaryRow("Subtotal", _subtotalLocal),
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
                        onPressed: _cartItems.isEmpty
                            ? null
                            : () {
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
    final id = item['id']?.toString() ?? UniqueKey().toString();
    final image = item['image']?.toString() ?? widget.imageUrl;
    final name = item['name']?.toString() ?? 'Item';
    // Prefer the 'options' string (pre-computed), otherwise build from modifiers
    final optionsString = (item['options']?.toString().isNotEmpty == true)
        ? item['options'].toString()
        : _buildOptionsText(item['modifiers'] ?? []);
    final price = (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0;
    final qty = (item['qty'] is int) ? item['qty'] as int : int.tryParse('${item['qty']}') ?? 1;
    final modifiers = (item['modifiers'] is List) ? List.from(item['modifiers']) : <dynamic>[];

    return Dismissible(
      key: Key('$id-$optionsString'),
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
          _recalculateSubtotal();
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
                  image,
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
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _espressoBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (optionsString.isNotEmpty)
                    Text(
                      optionsString,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    "\$${(price * qty).toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _freshMintGreen,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

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
                        _cartItems[index]['qty'] =
                            ((_cartItems[index]['qty'] is int) ? _cartItems[index]['qty'] as int : int.tryParse('${_cartItems[index]['qty']}') ?? 1) +
                                1;
                      });
                      _recalculateSubtotal();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.add, size: 16, color: _espressoBrown),
                    ),
                  ),
                  Text(
                    "${_cartItems[index]['qty']}",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _espressoBrown),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        final currentQty = (_cartItems[index]['qty'] is int) ? _cartItems[index]['qty'] as int : int.tryParse('${_cartItems[index]['qty']}') ?? 1;
                        if (currentQty > 1) {
                          _cartItems[index]['qty'] = currentQty - 1;
                        }
                      });
                      _recalculateSubtotal();
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
