import 'dart:convert';
import 'package:flutter/material.dart';

// Adjust these imports to match your project structure:
import '../../../models/order_model.dart';
import '../../../models/promotion_model.dart';
import '../../../server/order_service.dart';
import '../../../server/promotion_service.dart';

/// Small local exception so our `on PromotionNotFoundException` works
class PromotionNotFoundException implements Exception {
  final String? message;
  PromotionNotFoundException([this.message]);
  @override
  String toString() => message ?? 'PromotionNotFoundException';
}

class CartScreen extends StatefulWidget {
  final int id;
  final String name;
  final int quantity; // used when a single item map is provided
  final double subtotal; // optional initial subtotal (we recalc anyway)
  final List selectedModifiers;
  final String imageUrl;
  final int shopId;

  final int? userId;

  const CartScreen({
    super.key,
    required this.name,
    required this.id,
    this.quantity = 1,
    this.subtotal = 0.0,
    this.selectedModifiers = const [],
    this.imageUrl = '',
    required this.shopId,
    this.userId,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Theme colors
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  // Internal state
  final List<Map<String, dynamic>> _cartItems = [];
  double _subtotalLocal = 0.0;
  bool _isPlacingOrder = false;

  // Promo code state
  final TextEditingController _promoController = TextEditingController();
  String? _promoCode; // applied promo code
  bool _isPromoApplied = false;
  double _discountAmount = 0.0; // in dollars

  // Tracks whether a promo validation call is in progress
  bool _isApplying = false;

  double get _discountedSubtotal => (_subtotalLocal - _discountAmount).clamp(0.0, double.infinity);
  double get _tax => _discountedSubtotal * 0.05; // tax applied after discount
  double get _total => _discountedSubtotal + _tax;



  @override
  void initState() {
    super.initState();

    // Add the single incoming item (if provided) to the cart
    final incomingPrice =
    (widget.subtotal > 0 && widget.quantity > 0) ? (widget.subtotal / widget.quantity) : 0.0;

    final incoming = {
      'id': widget.id,
      'name': widget.name,
      'price': incomingPrice,
      'qty': widget.quantity > 0 ? widget.quantity : 1,
      'modifiers': widget.selectedModifiers.isNotEmpty ? widget.selectedModifiers : [],
      'image': widget.imageUrl,
    };

    _addOrMergeItem(_normalizeItem(incoming));
    _recalculateSubtotal(); // initial subtotal
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  // ---------- Helpers ----------

  String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

  double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  int _parseInt(dynamic v, {int fallback = 1}) {
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }

  Map<String, dynamic> _normalizeItem(Map<String, dynamic> raw) {
    final id = raw['id']?.toString() ?? _genId();
    final name = raw['name']?.toString() ?? 'Item';
    final price = _parseDouble(raw['price']);
    final qty = _parseInt(raw['qty']);
    final image = raw['image']?.toString() ?? widget.imageUrl;
    final modifiers = (raw['modifiers'] is List) ? List.from(raw['modifiers']) : <dynamic>[];
    final optionsFromModifiers = _optionsText(modifiers);

    final optionsField = (raw.containsKey('options') && raw['options'] != null && raw['options'].toString().isNotEmpty)
        ? raw['options'].toString()
        : optionsFromModifiers;

    return {
      'id': id,
      'name': name,
      'price': price,
      'qty': qty,
      'image': image,
      'options': optionsField,
      'modifiers': modifiers,
    };
  }

  String _modifiersKey(dynamic mods) {
    try {
      if (mods is List) {
        final normalized = mods.map((m) {
          if (m is Map) {
            final entries = m.entries.toList()..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
            return Map.fromEntries(entries);
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

  String _optionsText(List<dynamic> modifiers) {
    if (modifiers.isEmpty) return '';
    try {
      return modifiers.map((m) {
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
      }).where((s) => s.isNotEmpty).join(", ");
    } catch (_) {
      return modifiers.join(", ");
    }
  }

  void _addOrMergeItem(Map<String, dynamic> item) {
    final incomingKey = _modifiersKey(item['modifiers']);
    for (int i = 0; i < _cartItems.length; i++) {
      final existing = _cartItems[i];
      if (existing['id'].toString() == item['id'].toString() && _modifiersKey(existing['modifiers']) == incomingKey) {
        final newQty = _parseInt(existing['qty']) + _parseInt(item['qty']);
        setState(() {
          _cartItems[i]['qty'] = newQty;
          _recalculateSubtotalInternal();
        });
        return;
      }
    }
    setState(() {
      _cartItems.add(item);
      _recalculateSubtotalInternal();
    });
  }

  void _removeItemAt(int index) {
    if (index < 0 || index >= _cartItems.length) return;
    setState(() {
      _cartItems.removeAt(index);
      _recalculateSubtotalInternal();
    });
  }

  void _updateQtyAt(int index, int qty) {
    if (index < 0 || index >= _cartItems.length) return;
    final newQty = qty < 1 ? 1 : qty;
    setState(() {
      _cartItems[index]['qty'] = newQty;
      _recalculateSubtotalInternal();
    });
  }

  // subtotal calculations (internal + setState wrapper)
  void _recalculateSubtotalInternal() {
    double sum = 0.0;
    for (final it in _cartItems) {
      final price = _parseDouble(it['price']);
      final qty = _parseInt(it['qty']);
      sum += price * qty;
    }
    _subtotalLocal = sum;

    // Keep discount amount as-is. If you want to re-validate promos
    // on subtotal change, store the applied PromotionModel and re-run
    // _computeDiscountForPromotion against it here.
  }

  void _recalculateSubtotal() => setState(_recalculateSubtotalInternal);

  // ---------- Promo logic ----------
// inside _CartScreenState

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter a promo code.')));
      return;
    }

    if (_isApplying) return;

    setState(() => _isApplying = true);

    try {
      final promotion = await PromotionService().getPromotionByCode(code);
      if (promotion == null) throw PromotionNotFoundException();

      final adapter = promotion.toAdapter();

      // -------------------------------
      // 👉 NEW: SHOP ID VALIDATION
      // -------------------------------
      // Assumes your current shop id is stored in `_currentShopId`.
      // If adapter.shopId is null, we treat the promo as global (apply). Change logic
      // if you want null to mean "invalid".
      if (adapter.shopId != widget.shopId) {
        throw PromotionNotFoundException("This promo is not valid for this shop.");
      }

      // -------------------------------
      // 👉 NEW VALIDATION CHECKS
      // -------------------------------
      final now = DateTime.now().toUtc();
      final bool isActive = adapter.isActive ?? false;
      final DateTime? startsAt = adapter.startsAt;
      final DateTime? endsAt = adapter.endsAt;

      // 1. Check active flag
      if (!isActive) {
        throw PromotionNotFoundException("This promo is not active.");
      }

      // 2. Check start date (not valid yet)
      if (startsAt != null && now.isBefore(startsAt)) {
        throw PromotionNotFoundException("This promo is not valid yet.");
      }

      // 3. Check end date (expired)
      if (endsAt != null && now.isAfter(endsAt)) {
        throw PromotionNotFoundException("This promo has expired.");
      }

      // -------------------------------
      // 👉 Calculate discount
      // -------------------------------
      final computed = _computeDiscountForAdapter(adapter, _subtotalLocal);

      if (computed <= 0) {
        setState(() {
          _promoCode = null;
          _isPromoApplied = false;
          _discountAmount = 0.0;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(adapter.message ?? 'Promo not applicable.')));
      } else {
        setState(() {
          _promoCode = adapter.code;
          _isPromoApplied = true;
          _discountAmount = computed;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Promo applied: ${_formatDiscountDisplayFromAdapter(adapter, computed)}')),
        );
      }
    } on PromotionNotFoundException catch (e) {
      setState(() {
        _promoCode = null;
        _isPromoApplied = false;
        _discountAmount = 0.0;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Promo code not valid')));
    } catch (e, st) {
      debugPrint('promo error: $e\n$st');
      setState(() {
        _promoCode = null;
        _isPromoApplied = false;
        _discountAmount = 0.0;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to validate promo: ${_friendlyError(e)}')));
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  double _computeDiscountForAdapter(PromotionAdapter promo, double subtotal) {
    final now = DateTime.now().toUtc();

    // --- Validate active status (like backend) ---
    if (promo.isActive == false) return 0.0;

    // --- Not started yet ---
    if (promo.startsAt != null && now.isBefore(promo.startsAt!)) {
      return 0.0;
    }

    // --- Already expired ---
    if (promo.endsAt != null && now.isAfter(promo.endsAt!)) {
      return 0.0;
    }

    // --- Compute the discount ---
    double discount = 0.0;

    if (promo.type == PromotionType.percentage) {
      // Percentage discount: e.g. 10% => subtotal * 0.10
      discount = subtotal * (promo.value / 100.0);

      // Optional maxDiscount enforcement (if backend adds later)
      if (promo.maxDiscount != null && discount > promo.maxDiscount!) {
        discount = promo.maxDiscount!;
      }

    } else if (promo.type == PromotionType.fixed) {
      // Fixed amount promo.value is in CENTS (backend sends 100 → $1.00)
      discount = promo.value / 100.0;

      if (promo.maxDiscount != null && discount > promo.maxDiscount!) {
        discount = promo.maxDiscount!;
      }
    }

    // --- Check minimum subtotal requirement ---
    if (promo.minSubtotal != null && subtotal < promo.minSubtotal!) {
      return 0.0;
    }

    // --- Discount cannot exceed subtotal ---
    if (discount > subtotal) discount = subtotal;

    return _roundTo2(discount);
  }


  String _formatDiscountDisplayFromAdapter(PromotionAdapter adapter, double computed) {
    // computed is already the dollar amount that will be applied (rounded)
    if (adapter.type == PromotionType.percentage) {
      // show percent + applied amount
      return '${adapter.value}% off (applied: ${_formatCurrency(computed)})';
    } else {
      // For fixed promotions we display the computed dollar amount — e.g. $1.00 off
      return '${_formatCurrency(computed)} off';
    }
  }



  double _roundTo2(double val) {
    return (val * 100).roundToDouble() / 100.0;
  }


  String _formatCurrency(double amount) {
    // TODO: replace with NumberFormat if you have intl imported
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _friendlyError(Object e) {
    // Customize for production: check types, show localized message
    return e.toString();
  }

  void _clearPromo() {
    setState(() {
      _promoController.clear();
      _promoCode = null;
      _isPromoApplied = false;
      _discountAmount = 0.0;
    });
  }

  // ---------- Order builder & submit ----------

  int _toCents(double amount) => (amount * 100).round();

  OrderModel _buildOrderFromCart() {
    // Replace with actual user/shop/promo values as needed
    final int userId = widget.userId!;
    final int shopId = widget.shopId;
    final int? promoId = null;
    final String status = 'placed';

    final orderItems = _cartItems.map((it) {
      final mods = it['modifiers'];
      final List<OptionGroupModel> optionGroups = <OptionGroupModel>[];
      if (mods is List) {
        for (final m in mods) {
          if (m is Map) {
            final groupId = _parseInt(m['group_id'] ?? m['groupId'], fallback: 0);
            final optionId = _parseInt(m['option_id'] ?? m['optionId'], fallback: 0);
            final groupName = (m['group_name'] ?? m['group'] ?? m['groupName'] ?? '').toString();
            final selectedOption = (m['selected_option'] ?? m['selected'] ?? m['option'] ?? '').toString();
            if (groupId != 0 || optionId != 0 || groupName.isNotEmpty || selectedOption.isNotEmpty) {
              optionGroups.add(OptionGroupModel(
                groupId: groupId,
                optionId: optionId,
                groupName: groupName,
                selectedOption: selectedOption,
              ));
            }
          }
        }
      }

      final price = _parseDouble(it['price']);
      final qty = _parseInt(it['qty']);

      return OrderItemModel(
        id: (it['id'] is int) ? it['id'] as int : null,
        itemid: int.tryParse('${it['id'] ?? it['itemid'] ?? 0}') ?? 0,
        namesnapshot: it['name']?.toString() ?? '',
        unitpriceCents: _toCents(price),
        quantity: qty,
        notes: it['notes']?.toString(),
        optionGroups: optionGroups,
      );
    }).toList();

    final subtotalCents = _toCents(_subtotalLocal);
    final discountCents = _toCents(_discountAmount);
    final totalCents = _toCents(_discountedSubtotal + _tax);

    final order = OrderModel(
      userid: userId,
      shopid: shopId,
      promoid: promoId,
      status: status,
      subtotalcents: subtotalCents,
      discountcents: discountCents,
      totalcents: totalCents,
      placedat: DateTime.now().toIso8601String(),
      orderItems: orderItems,
    );

    return order;
  }

  Future<void> _createOrder() async {
    if (_isPlacingOrder || _cartItems.isEmpty) return;

    setState(() => _isPlacingOrder = true);

    try {
      final order = _buildOrderFromCart();

      // Pass promocode string to service if backend expects it (this example assumes createOrder accepts promocode param).
      final created = await OrderService().createOrder(order, promocode: _promoCode);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order placed — ID: ${created?.id ?? 'unknown'}')),
      );

      // clear cart on success (optional)
      setState(() {
        _cartItems.clear();
        _discountAmount = 0.0;
        _isPromoApplied = false;
        _promoController.clear();
        _promoCode = null;
        _recalculateSubtotalInternal();
      });
    } catch (err, st) {
      debugPrint('createOrder error: $err\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: ${err.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  // ---------- UI ----------

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
          // Order list
          Expanded(
            child: _cartItems.isEmpty
                ? Center(child: Text("Your cart is empty", style: TextStyle(color: _espressoBrown)))
                : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _cartItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _cartItemWidget(_cartItems[index], index),
            ),
          ),

          // Bill / Promo / Checkout area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Promo input row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _promoController,
                            decoration: InputDecoration(
                              hintText: 'Promo code',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _applyPromo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _espressoBrown,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                          child: _isApplying
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                              : const Text('Apply'),
                        ),
                        const SizedBox(width: 8),
                        if (_isPromoApplied)
                          TextButton(
                            onPressed: _clearPromo,
                            child: const Text('Clear'),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Summary rows
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          _summaryRow("Subtotal", _subtotalLocal),
                          const SizedBox(height: 8),
                          if (_isPromoApplied) _summaryRow("Discount", -_discountAmount),
                          if (_isPromoApplied) const SizedBox(height: 8),
                          _summaryRow("Tax (5%)", _tax),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Total", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _espressoBrown)),
                              Text("\$${_total.toStringAsFixed(2)}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _freshMintGreen)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Checkout button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: (_cartItems.isEmpty || _isPlacingOrder) ? null : _createOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _espressoBrown,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        child: _isPlacingOrder
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                            : const Text("Checkout", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartItemWidget(Map<String, dynamic> item, int index) {
    final id = item['id']?.toString() ?? _genId();
    final image = item['image']?.toString() ?? widget.imageUrl;
    final name = item['name']?.toString() ?? 'Item';
    final optionsString = (item['options']?.toString().isNotEmpty == true) ? item['options'].toString() : _optionsText(item['modifiers'] ?? []);
    final price = _parseDouble(item['price']);
    final qty = _parseInt(item['qty']);

    return Dismissible(
      key: Key('$id-$optionsString'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) => _removeItemAt(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(
          children: [
            // Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(image, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.coffee, color: Colors.grey[400])),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _espressoBrown)),
                const SizedBox(height: 4),
                if (optionsString.isNotEmpty) Text(optionsString, style: TextStyle(fontSize: 12, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text("\$${(price * qty).toStringAsFixed(2)}", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _freshMintGreen)),
              ]),
            ),

            const SizedBox(width: 8),

            // Quantity Control
            Container(
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
              child: Column(children: [
                InkWell(
                  onTap: () => _updateQtyAt(index, qty + 1),
                  child: Padding(padding: const EdgeInsets.all(4.0), child: Icon(Icons.add, size: 16, color: _espressoBrown)),
                ),
                Text("$qty", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _espressoBrown)),
                InkWell(
                  onTap: () {
                    if (qty > 1) _updateQtyAt(index, qty - 1);
                  },
                  child: Padding(padding: const EdgeInsets.all(4.0), child: Icon(Icons.remove, size: 16, color: _espressoBrown)),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount) {
    final text = amount < 0 ? '-\$${(-amount).toStringAsFixed(2)}' : '\$${amount.toStringAsFixed(2)}';
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
      Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ]);
  }
}
