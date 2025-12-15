
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

// Adjust these imports to match your project structure:
import '../../../models/order_model.dart';
import '../../../models/promotion_model.dart';
import '../../../server/order_service.dart';
import '../../../server/payment_service.dart'; // Should expose StripeService.createPaymentIntent
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
  bool _isPaying = false;

  // Inputs
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();

  // Promo State
  String? _promoCode;
  bool _isPromoApplied = false;
  double _discountAmount = 0.0;
  bool _isApplying = false;

  // Totals
  double get _discountedSubtotal =>
      (_subtotalLocal - _discountAmount).clamp(0.0, double.infinity);
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
    _noteFocusNode.dispose();
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
            final entries = m.entries.toList()
              ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
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
      if (adapter.shopId != widget.shopId) {
        throw PromotionNotFoundException("Invalid shop.");
      }

      final computed = _computeDiscountForAdapter(adapter, _subtotalLocal);

      if (computed <= 0) {
        _clearPromoUI();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(adapter.message ?? 'Promo not applicable.')),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _promoCode = adapter.code;
            _isPromoApplied = true;
            _discountAmount = computed;
          });
          // Close dialog and return success
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(adapter.message ?? 'Promo applied')),
          );
        }
      }
    } on PromotionNotFoundException catch (e) {
      _clearPromoUI();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } catch (e) {
      _clearPromoUI();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
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

  // ---------- Payment (Stripe PaymentSheet) ----------

  Future<bool> _handleStripePayment() async {
    try {
      setState(() => _isPaying = true);

      final resp = await StripeService.createPaymentIntent(
        amount: _toCents(_total),
        currency: 'usd',
      );

      Stripe.publishableKey = resp['publishableKey'];
      await Stripe.instance.applySettings();

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: resp['client_secret'],
          merchantDisplayName: 'Your Shop',
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      return true;
    } catch (_) {
      return false;
    } finally {
      setState(() => _isPaying = false);
    }
  }

  Future<bool> _handleKHQRPayment() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Bank Transfer (KHQR)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text("Scan QR using ABA / Bakong"),
            SizedBox(height: 16),
            SizedBox(
              width: 200,
              height: 200,
              child: ColoredBox(color: Colors.black12),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("I've Paid"),
          ),
        ],
      ),
    ) ??
        false;
  }


  int _toCents(double amount) => (amount * 100).round();

  /// Returns true if payment succeeded, false otherwise.
  Future<bool> _handlePaymentSheetPayment() async {
    setState(() => _isPaying = true);

    try {
      final int amountCents = _toCents(_total);

      // call your backend via PaymentService / StripeService
      final resp = await StripeService.createPaymentIntent(
        amount: amountCents,
        currency: 'usd', // change as needed

      );

      final clientSecret = resp['client_secret'] ?? resp['clientSecret'];
      final publishableKey = resp['publishableKey'] ?? resp['publishable_key'];

      if (publishableKey != null && publishableKey is String && publishableKey.isNotEmpty) {
        Stripe.publishableKey = publishableKey;
        await Stripe.instance.applySettings();
      }

      if (clientSecret == null) {
        throw Exception('Payment intent returned no client_secret.');
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Your Shop',
          // Configure applePay/googlePay if supported on backend
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${e.error.localizedMessage ?? e.error.message}')),
        );
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment error: $e')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  // ---------- Order Logic ----------
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

      // safer id parsing
      final rawId = it['id'];
      final parsedId = (rawId is int) ? rawId : int.tryParse(rawId?.toString() ?? '') ;

      return OrderItemModel(
        id: parsedId,
        itemid: parsedId ?? int.tryParse('${it['itemid'] ?? 0}') ?? 0,
        namesnapshot: it['name']?.toString() ?? '',
        unitpriceCents: _toCents(price),
        quantity: qty,
        notes: _noteController.text,
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

  /// Full flow:
  /// 1) Run Stripe PaymentSheet (client only)
  /// 2) If payment succeeds, create the order on the server
  Future<void> _createOrder() async {
    if (_isPlacingOrder || _cartItems.isEmpty) return;

    setState(() => _isPlacingOrder = true);

    try {
      // 1) Run payment sheet
      final paymentSucceeded = await _handlePaymentSheetPayment();

      if (!paymentSucceeded) {
        // Payment canceled or failed -> do not create order
        setState(() => _isPlacingOrder = false);
        return;
      }

      // 2) Build order now that payment is successful
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

        Map<String, dynamic> orderData = createdOrder.toJson();

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
        onTap: () => FocusScope.of(context).unfocus(),
        child: _cartItems.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: 60, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text("Cart is empty",
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
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
                    const Text("Notes",
                        style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _noteController,
                        focusNode: _noteFocusNode,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: "E.g. Less sugar, allergies...",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        style:
                        const TextStyle(fontWeight: FontWeight.w500),
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
                            _buildSummaryRow(
                                "Discount", -_discountAmount,
                                isRed: true),
                          ],
                          const Padding(
                              padding:
                              EdgeInsets.symmetric(vertical: 16),
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
            onPressed:
            (_cartItems.isEmpty || _isPlacingOrder || _isPaying) ? null : _createOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: _freshMintGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: (_isPlacingOrder || _isPaying)
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
                errorBuilder: (_, __, ___) => const Icon(Icons.coffee, color: Colors.grey),
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
                    const Icon(Icons.edit_outlined, size: 16, color: Colors.green),
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
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),

                // Modifiers Rows
                ...modifiers.map((mod) {
                  String modName = "";
                  if (mod is Map) {
                    modName = (mod['selected_option'] ?? mod['option'] ?? '').toString();
                  }
                  if (modName.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(modName, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subtotal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text("\$${(basePrice * qty).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isRed ? Colors.red : Colors.black),
        ),
      ],
    );
  }

  void _showPromoDialog() async {
    final applied = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: StatefulBuilder(
            // use StatefulBuilder so we can show apply spinner inside dialog without rebuilding whole screen
            builder: (contextDialog, setStateDialog) {
              return Column(
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
                        onPressed: () => Navigator.pop(contextDialog, false),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isApplying
                            ? null
                            : () async {
                          // call _applyPromo and wait for it to pop(dialog, true) on success
                          await _applyPromo();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _freshMintGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: _isApplying
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text("Apply", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              );
            },
          ),
        ),
      ),
    );

    // 'applied' can be true/false/null; we don't strictly need to do more here since _applyPromo already mutates state,
    // but if you want to refresh UI or analytics you can do it here based on 'applied'.
    if (applied == true) {
      _recalculateSubtotal();
    }
  }
}
