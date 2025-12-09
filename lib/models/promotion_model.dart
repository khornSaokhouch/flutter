import 'package:frontend/models/shop.dart';

enum PromotionType { percentage, fixed, unknown }

class PromotionModel {
  final int id;
  final int shopid;
  final String code;
  final String type; // raw type from API (e.g. "percentage" or "fixed")
  final num value; // raw numeric value from API
  final String? startsat; // raw string from API (nullable)
  final String? endsat; // raw string from API (nullable)
  final int? isactive; // 1 or 0 typically
  final int? usagelimit;
  final String? createdAt;
  final String? updatedAt;
  final ShopsResponse? shop;

  PromotionModel({
    required this.id,
    required this.shopid,
    required this.code,
    required this.type,
    required this.value,
    this.startsat,
    this.endsat,
    this.isactive,
    this.usagelimit,
    this.createdAt,
    this.updatedAt,
    this.shop,
  });

  /// Robust factory that tolerates string/num and missing fields.
  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v, [int fallback = 0]) {
      if (v == null) return fallback;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? fallback;
    }

    num parseNum(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v;
      return num.tryParse(v.toString()) ?? 0;
    }

    return PromotionModel(
      id: parseInt(json['id']),
      shopid: parseInt(json['shopid']),
      code: (json['code'] ?? '').toString(),
      type: (json['type'] ?? '').toString().toLowerCase(),
      value: parseNum(json['value']),
      startsat: json['startsat']?.toString(),
      endsat: json['endsat']?.toString(),
      isactive: json.containsKey('isactive') ? parseInt(json['isactive']) : null,
      usagelimit: json.containsKey('usagelimit') ? parseInt(json['usagelimit']) : null,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      shop: json['shop'] != null ? ShopsResponse.fromJson(Map<String, dynamic>.from(json['shop'])) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopid': shopid,
      'code': code,
      'type': type,
      'value': value,
      'startsat': startsat,
      'endsat': endsat,
      'isactive': isactive,
      'usagelimit': usagelimit,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'shop': shop?.toJson(),
    };
  }

  // ---- Convenience getters & adapters used by UI/business logic ----

  /// Interprets the raw string type into a typed enum used by cart logic.
  PromotionType get promotionType {
    final t = type.toLowerCase();
    if (t.contains('percent') || t.contains('%') || t == 'percentage') return PromotionType.percentage;
    if (t.contains('fix') || t == 'fixed' || t == 'amount') return PromotionType.fixed;
    return PromotionType.unknown;
  }

  /// Value as double (safe)
  double get valueDouble => value is num ? (value as num).toDouble() : double.tryParse(value.toString()) ?? 0.0;

  /// The promotion expiry as UTC DateTime if endsat is parseable, else null.
  DateTime? get expiresAt {
    if (endsat == null) return null;
    try {
      return DateTime.parse(endsat!).toUtc();
    } catch (_) {
      return null;
    }
  }

  /// The promotion start time as UTC DateTime if startsat is parseable, else null.
  DateTime? get startsAt {
    if (startsat == null) return null;
    try {
      return DateTime.parse(startsat!).toUtc();
    } catch (_) {
      return null;
    }
  }

  /// Is this active according to the API field (tolerant).
  bool get isActive {
    if (isactive == null) return true; // default to true if backend omitted
    return isactive == 1;
  }

  /// Helpful boolean check for expiration against now (UTC).
  bool get isExpired {
    final e = expiresAt;
    if (e == null) return false;
    return !e.isAfter(DateTime.now().toUtc());
  }

  /// Minimal adapter used by `_computeDiscountForPromotion` from cart code:
  /// - type: PromotionType
  /// - value: double
  /// - expiresAt / startsAt / isActive: passed through
  /// - minSubtotal / maxDiscount: not present in API — return null
  PromotionAdapter toAdapter() {
    return PromotionAdapter(
      code: code,
      type: promotionType,
      value: valueDouble,
      isActive: isActive,
      startsAt: startsAt,
      endsAt: expiresAt,
      shopId: shopid,
      minSubtotal: null,
      maxDiscount: null,
      message: null,
    );
  }
}

/// Small adapter the cart code can use (keeps cart-side logic decoupled).
class PromotionAdapter {
  final String code;
  final PromotionType type;
  final double value;
  final bool? isActive;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int shopId;            // ← added for clean shop checking
  final double? maxDiscount;
  final double? minSubtotal;
  final String? message;

  PromotionAdapter({
    required this.code,
    required this.type,
    required this.value,
    required this.shopId,      // required!
    this.isActive,
    this.startsAt,
    this.endsAt,
    this.maxDiscount,
    this.minSubtotal,
    this.message,
  });
}

