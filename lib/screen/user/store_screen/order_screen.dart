import 'dart:convert';
import 'package:flutter/material.dart';

// Adjust these imports to match your project structure:
import '../../../models/order_model.dart';
import '../../../models/promotion_model.dart';
import '../../../server/order_service.dart';
import '../../../server/promotion_service.dart';
import './order_success_screen.dart'; // Make sure this file exists

class PromotionNotFoundException implements Exception {
  final String? message;
  PromotionNotFoundException([this.message]);
  @override
  String toString() => message ?? 'PromotionNotFoundException';
}

class CartScreen extends StatefulWidget {
  final int id;
  final String name;
  final int quantity;
  final double subtotal;
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
  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  // Internal state
  final List<Map<String, dynamic>> _cartItems = [];
  double _subtotalLocal = 0.0;
  bool _isPlacingOrder = false;

  // Inputs
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode(); // <-- added focus node

  // Promo State
  String? _promoCode;
  bool _isPromoApplied = false;
  double _discountAmount = 0.0;
  bool _isApplying = false;

  // Totals
  double get _discountedSubtotal => (_subtotalLocal - _discountAmount).clamp(0.0, double.infinity);
  double get _total => _discountedSubtotal;

  @override
  void initState() {
    super.initState();

    final incomingPrice = (widget.subtotal > 0 && widget.quantity > 0)
        ? (widget.subtotal / widget.quantity)
        : 0.0;

    final incoming = {
      'id': widget.id,
      'name': widget.name,
      'price': incomingPrice,
      'qty': widget.quantity > 0 ? widget.quantity : 1,
      'modifiers': widget.selectedModifiers.isNotEmpty ? widget.selectedModifiers : [],
      'image': widget.imageUrl,
    };

    if (widget.id != 0) {
      _addOrMergeItem(_normalizeItem(incoming));
    }
    _recalculateSubtotal();
  }

  @override
  void dispose() {
    _promoController.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose(); // <-- dispose focus node
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

    return {
      'id': id,
      'name': name,
      'price': price,
      'qty': qty,
      'image': image,
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

  void _addOrMergeItem(Map<String, dynamic> item) {
    final incomingKey = _modifiersKey(item['modifiers']);
    for (int i = 0; i < _cartItems.length; i++) {
      final existing = _cartItems[i];
      if (existing['id'].toString() == item['id'].toString() &&
          _modifiersKey(existing['modifiers']) == incomingKey) {
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


  void _recalculateSubtotalInternal() {
    double sum = 0.0;
    for (final it in _cartItems) {
      final price = _parseDouble(it['price']);
      final qty = _parseInt(it['qty']);
      sum += price * qty;
    }
    _subtotalLocal = sum;
  }

  void _recalculateSubtotal() => setState(_recalculateSubtotalInternal);

  // ---------- Promo logic ----------

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isApplying = true);

    try {
      final promotion = await PromotionService().getPromotionByCode(code);
      if (promotion == null) throw PromotionNotFoundException();

      final adapter = promotion.toAdapter();
      if (adapter.shopId != widget.shopId)
        throw PromotionNotFoundException("Invalid shop.");

      final computed = _computeDiscountForAdapter(adapter, _subtotalLocal);

      if (computed <= 0) {
        _clearPromoUI();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(adapter.message ?? 'Promo not applicable.')));
      } else {
        setState(() {
          _promoCode = adapter.code;
          _isPromoApplied = true;
          _discountAmount = computed;
        });
        if (mounted && Navigator.canPop(context)) Navigator.pop(context); // Close dialog safely
      }
    } catch (e) {
      _clearPromoUI();
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  void _clearPromoUI() {
    setState(() {
      _promoCode = null;
      _isPromoApplied = false;
      _discountAmount = 0.0;
    });
  }

  double _computeDiscountForAdapter(PromotionAdapter promo, double subtotalDollars) {
    final int subtotalCents = (subtotalDollars * 100).round();

    int discountCents = 0;

    switch (promo.type) {
      case PromotionType.percentage:
      // promo.value is percentage (e.g. 15 => 15%)
        final double percent = promo.value;
        discountCents = ((subtotalCents * percent) / 100.0).round();
        break;

      case PromotionType.fixed:
      // promo.value is cents (e.g. 125 => $1.25). Round to int to be safe.
        discountCents = promo.value.round();
        break;

      case PromotionType.unknown:
      default:
        discountCents = 0;
    }

    // clamp
    discountCents = discountCents.clamp(0, subtotalCents);

    return discountCents / 100.0;
  }

  // ---------- Order Logic ----------

  int _toCents(double amount) => (amount * 100).round();

  OrderModel _buildOrderFromCart() {
    final int userId = widget.userId ?? 0;
    final int shopId = widget.shopId;
    final int? promoId = null;
    final String status = 'placed';

    final orderItems = _cartItems.map((it) {
      final mods = it['modifiers'];
      final List<OptionGroupModel> optionGroups = <OptionGroupModel>[];
      if (mods is List) {
        for (final m in mods) {
          if (m is Map) {
            final groupId =
            _parseInt(m['group_id'] ?? m['groupId'], fallback: 0);
            final optionId =
            _parseInt(m['option_id'] ?? m['optionId'], fallback: 0);
            final groupName =
            (m['group_name'] ?? m['group'] ?? m['groupName'] ?? '')
                .toString();
            final selectedOption =
            (m['selected_option'] ?? m['selected'] ?? m['option'] ?? '')
                .toString();
            if (groupId != 0 ||
                optionId != 0 ||
                groupName.isNotEmpty ||
                selectedOption.isNotEmpty) {
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
        notes: _noteController.text, // Added notes from controller
        optionGroups: optionGroups,
      );
    }).toList();

    return OrderModel(
      userid: userId,
      shopid: shopId,
      promoid: promoId,
      status: status,
      subtotalcents: _toCents(_subtotalLocal),
      discountcents: _toCents(_discountAmount),
      totalcents: _toCents(_total),
      placedat: DateTime.now().toIso8601String(),
      orderItems: orderItems,
    );
  }

  Future<void> _createOrder() async {
    if (_isPlacingOrder || _cartItems.isEmpty) return;

    setState(() => _isPlacingOrder = true);

    try {
      final order = _buildOrderFromCart();

      // Create order via your service
      final createdOrder = await OrderService().createOrder(order, promocode: _promoCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order placed successfully!'),
            backgroundColor: _freshMintGreen,
          ),
        );

        // Convert OrderModel to JSON/Map for the Success Screen
        // Ensure your OrderModel has a toJson() method.
        Map<String, dynamic> orderData = createdOrder.toJson();

        // Navigate to OrderSuccessScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(orderData: orderData),
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order failed: $err'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  // ---------- UI Widgets ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Checkout",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      // Wrap the body with GestureDetector so tapping outside TextField closes keyboard
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus(); // <-- dismiss keyboard
        },
        child: _cartItems.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text("Cart is empty", style: TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ),
        )
            : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Order Details Header
                    _buildSectionHeader("Order Details"),
                    const SizedBox(height: 12),

                    // 2. List of Items (Card Style)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: _cartItems
                            .map((item) => _buildDetailItem(item))
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 3. Notes Section
                    const Text("Notes", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _noteController,
                        focusNode: _noteFocusNode, // <-- attach the focus node here
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: "E.g. Less sugar, allergies...",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 4. Order Discount
                    _buildSectionHeader("Order Discount"),
                    const SizedBox(height: 12),
                    _buildClickableTile(
                      icon: Icons.confirmation_number_outlined,
                      title: _isPromoApplied
                          ? "Code: $_promoCode"
                          : "Use Voucher",
                      subtitle: _isPromoApplied
                          ? "Discount Applied"
                          : "Save orders with promos",
                      trailing: _isPromoApplied
                          ? Text("-\$${_discountAmount.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red))
                          : const Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.grey),
                      onTap: () => _showPromoDialog(),
                    ),

                    const SizedBox(height: 24),

                    // 5. Payment Details
                    _buildSectionHeader("Payment Details"),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow("Subtotal", _subtotalLocal),
                          if (_isPromoApplied) ...[
                            const SizedBox(height: 8),
                            _buildSummaryRow("Discount", -_discountAmount, isRed: true),
                          ],
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1)),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Total Payment",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700])),
                              Text("\$${_total.toStringAsFixed(2)}",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: _espressoBrown)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // 6. Place Order Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: (_cartItems.isEmpty || _isPlacingOrder)
                ? null
                : _createOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: _freshMintGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: _isPlacingOrder
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
                : const Text(
              "Place Order",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SUB-WIDGETS
  // =========================================================

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDetailItem(Map<String, dynamic> item) {
    final name = item['name'];
    final qty = item['qty'];
    final basePrice = _parseDouble(item['price']);
    // Filter out null/empty modifiers
    List<dynamic> modifiers = item['modifiers'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              color: Colors.grey[100],
              child: Image.network(
                item['image'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.coffee, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${qty}x $name",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    // Edit icon (visual only)
                    const Icon(Icons.edit_outlined,
                        size: 16, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 8),

                // Base Price Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Base Price",
                        style: TextStyle(fontSize: 13, color: Colors.black87)),
                    Text("\$${basePrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),

                // Modifiers Rows
                ...modifiers.map((mod) {
                  String modName = "";
                  if (mod is Map) {
                    modName = mod['selected_option'] ?? mod['option'] ?? '';
                  }
                  if (modName.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(modName,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subtotal",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    Text("\$${(basePrice * qty).toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200)),
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: trailing,
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isRed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey)),
        Text(
          "${amount < 0 ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}",
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isRed ? Colors.red : Colors.black),
        ),
      ],
    );
  }

  void _showPromoDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter Voucher",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _promoController,
                decoration: InputDecoration(
                  hintText: "Promo Code",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.card_giftcard, color: _freshMintGreen),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      _applyPromo();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _freshMintGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: const Text(
                      "Apply",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
