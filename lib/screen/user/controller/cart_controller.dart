import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../models/order_model.dart';
import '../../../models/promotion_model.dart';
import '../../../server/order_service.dart';
import '../../../server/payment_service.dart';
import '../../../server/promotion_service.dart';

class PromotionNotFoundException implements Exception {
  final String? message;
  PromotionNotFoundException([this.message]);
  @override
  String toString() => message ?? 'PromotionNotFoundException';
}

enum PaymentMethod {
  stripe,
  khqr,
}

class CartController extends ChangeNotifier {
  // ================= THEME =================

  final Color freshMintGreen = const Color(0xFF4E8D7C);
  final Color espressoBrown = const Color(0xFF4B2C20);
  final Color bgGrey = const Color(0xFFF9FAFB);

  // ================= CART =================

  final List<Map<String, dynamic>> cartItems = [];
  double subtotalLocal = 0.0;

  // ================= STATE =================

  bool isPlacingOrder = false;
  bool isPaying = false;



  // ================= INPUTS =================

  final TextEditingController promoController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final FocusNode noteFocusNode = FocusNode();

  // ================= PROMO =================

  String? promoCode;
  bool isPromoApplied = false;
  double discountAmount = 0.0;
  bool isApplying = false;

  // ================= TOTALS =================

  double get total =>
      (subtotalLocal - discountAmount).clamp(0.0, double.infinity);

  // ================= HELPERS =================

  String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

  int _toCents(double v) => (v * 100).round();

  double _parseDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  int _parseInt(dynamic v, {int fallback = 1}) =>
      v is int ? v : int.tryParse('$v') ?? fallback;

  // ================= ITEM NORMALIZATION =================




  Map<String, dynamic> normalizeItem(
      Map<String, dynamic> raw, {
        String fallbackImage = '',
      }) {
    final id = raw['id']?.toString() ?? _genId();
    final name = raw['name']?.toString() ?? 'Item';
    final price = _parseDouble(raw['price']);
    final qty = _parseInt(raw['qty'], fallback: 1);
    final image = raw['image']?.toString() ?? fallbackImage;
    final modifiers =
    (raw['modifiers'] is List) ? List.from(raw['modifiers']) : <dynamic>[];

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
        return jsonEncode(
          mods.map((m) {
            if (m is Map) {
              final entries = m.entries.toList()
                ..sort((a, b) =>
                    a.key.toString().compareTo(b.key.toString()));
              return Map.fromEntries(entries);
            }
            return m;
          }).toList(),
        );
      }
      return jsonEncode(mods);
    } catch (_) {
      return mods.toString();
    }
  }

  void addOrMergeItem(Map<String, dynamic> item) {
    final incomingKey = _modifiersKey(item['modifiers']);

    for (int i = 0; i < cartItems.length; i++) {
      final existing = cartItems[i];
      if (existing['id'].toString() == item['id'].toString() &&
          _modifiersKey(existing['modifiers']) == incomingKey) {
        existing['qty'] =
            _parseInt(existing['qty']) + _parseInt(item['qty']);
        recalculateSubtotal();
        return;
      }
    }

    cartItems.add(item);
    recalculateSubtotal();
  }

  // ================= CART TOTAL =================

  void recalculateSubtotal() {
    subtotalLocal = 0;
    for (final it in cartItems) {
      subtotalLocal += _parseDouble(it['price']) * _parseInt(it['qty']);
    }
    notifyListeners();
  }

  void clearCart() {
    cartItems.clear();
    subtotalLocal = 0;
    discountAmount = 0;
    promoCode = null;
    isPromoApplied = false;
    notifyListeners();
  }

  // ================= PROMO =================

  Future<void> applyPromo(int shopId, BuildContext context) async {
    final code = promoController.text.trim();
    if (code.isEmpty) return;

    isApplying = true;
    notifyListeners();

    try {
      final promotion =
      await PromotionService().getPromotionByCode(code);
      if (promotion == null) throw PromotionNotFoundException();

      final adapter = promotion.toAdapter();
      if (adapter.shopId != shopId) {
        throw PromotionNotFoundException('Invalid shop');
      }

      final subtotalCents = _toCents(subtotalLocal);
      int discountCents = 0;

      if (adapter.type == PromotionType.percentage) {
        discountCents =
            ((subtotalCents * adapter.value) / 100).round();
      } else if (adapter.type == PromotionType.fixed) {
        discountCents = adapter.value.round();
      }

      discountCents = discountCents.clamp(0, subtotalCents);

      promoCode = adapter.code;
      discountAmount = discountCents / 100;
      isPromoApplied = true;

      notifyListeners();

      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      isApplying = false;
      notifyListeners();
    }
  }

  // ================= PAYMENT =================

  Future<void> _pay({
    required BuildContext context,
    required int orderId,
    required int userId,
  }) async {
    isPaying = true;
    notifyListeners();

    try {
      final resp = await StripeService.createPaymentIntent(
        amount: _toCents(total),
        currency: 'usd',
        userId: userId,
        orderId: orderId,
      );

      // Accept BOTH key styles safely
      final clientSecret =
          resp['client_secret'] ?? resp['clientSecret'];

      if (clientSecret == null || clientSecret is! String) {
        throw Exception('Stripe client_secret missing');
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Your Shop',
        ),
      );

      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.error.localizedMessage ?? 'Payment cancelled',
            ),
          ),
        );
      }
      rethrow;
    } finally {
      isPaying = false;
      notifyListeners();
    }
  }

// ================= PAYMENT METHOD =================


  void setPaymentMethod(PaymentMethod method) {
    var selectedPayment = method;
    notifyListeners();
  }


  // ================= ORDER =================

  OrderModel buildOrderFromCart({
    required int shopId,
    int? userId,
  }) {
    return OrderModel(
      userid: userId ?? 0,
      shopid: shopId,
      status: 'pending',
      subtotalcents: _toCents(subtotalLocal),
      discountcents: _toCents(discountAmount),
      totalcents: _toCents(total),
      placedat: DateTime.now().toIso8601String(),
      orderItems: cartItems.map((it) {
        final rawId = it['id'];
        final int itemId = rawId is int
            ? rawId
            : int.tryParse(rawId.toString()) ?? 0;

        return OrderItemModel(
          itemid: itemId,
          namesnapshot: it['name']?.toString() ?? '',
          unitpriceCents: _toCents(it['price']),
          quantity: _parseInt(it['qty']),
          notes: noteController.text,
          optionGroups: const [],
        );
      }).toList(),
    );
  }


  Future<OrderModel> createOrder({
    required BuildContext context,
    required int shopId,
    int? userId,
  }) async {
    if (isPlacingOrder || cartItems.isEmpty) {
      throw Exception('Order already in progress');
    }

    isPlacingOrder = true;
    notifyListeners();

    try {
      // 1) Create order
      final order =
      buildOrderFromCart(shopId: shopId, userId: userId);
      final created =
      await OrderService().createOrder(order, promocode: promoCode);

      // 2) Pay with Stripe (linked to orderId)
      await _pay(context: context, userId: userId!, orderId: created.id!);

      return created;
    } finally {
      isPlacingOrder = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    promoController.dispose();
    noteController.dispose();
    noteFocusNode.dispose();
    super.dispose();
  }
}
