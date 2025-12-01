// models/shop_options.dart
class ShopOptions {
  int? id;
  int? categoryId;
  String? name;
  String? description;
  double? priceCents; // parsed from "200.00"
  String? imageUrl;
  bool? isAvailable; // parsed from 0/1
  DateTime? createdAt;
  DateTime? updatedAt;
  List<OptionGroup>? optionGroups;

  ShopOptions({
    this.id,
    this.categoryId,
    this.name,
    this.description,
    this.priceCents,
    this.imageUrl,
    this.isAvailable,
    this.createdAt,
    this.updatedAt,
    this.optionGroups,
  });

  factory ShopOptions.fromJson(Map<String, dynamic> json) {
    double? parsePrice(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    bool? parseBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().toLowerCase();
      if (s == '1' || s == 'true') return true;
      if (s == '0' || s == 'false') return false;
      return null;
    }

    DateTime? parseDate(String? s) =>
        s == null ? null : DateTime.tryParse(s);

    return ShopOptions(
      id: json['id'] is int ? json['id'] as int : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      categoryId: json['category_id'] is int ? json['category_id'] as int : (json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      priceCents: parsePrice(json['price_cents']),
      imageUrl: json['image_url']?.toString(),
      isAvailable: parseBool(json['is_available']),
      createdAt: parseDate(json['created_at']?.toString()),
      updatedAt: parseDate(json['updated_at']?.toString()),
      optionGroups: (json['optionGroups'] as List<dynamic>?)
          ?.map((e) => OptionGroup.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    String? priceToString(double? p) => p == null ? null : p.toStringAsFixed(2);

    int? boolToInt(bool? b) => b == null ? null : (b ? 1 : 0);

    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price_cents': priceToString(priceCents),
      'image_url': imageUrl,
      'is_available': boolToInt(isAvailable),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (optionGroups != null)
        'optionGroups': optionGroups!.map((g) => g.toJson()).toList(),
    };
  }
}

class OptionGroup {
  int? id;
  String? name;
  String? type;
  bool? isRequired;
  DateTime? createdAt;
  DateTime? updatedAt;
  Pivot? pivot;
  List<OptionItem>? options;

  OptionGroup({
    this.id,
    this.name,
    this.type,
    this.isRequired,
    this.createdAt,
    this.updatedAt,
    this.pivot,
    this.options,
  });

  factory OptionGroup.fromJson(Map<String, dynamic> json) {
    bool? parseBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().toLowerCase();
      if (s == '1' || s == 'true') return true;
      if (s == '0' || s == 'false') return false;
      return null;
    }

    DateTime? parseDate(String? s) =>
        s == null ? null : DateTime.tryParse(s);

    return OptionGroup(
      id: json['id'] is int ? json['id'] as int : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      name: json['name']?.toString(),
      type: json['type']?.toString(),
      isRequired: parseBool(json['is_required']),
      createdAt: parseDate(json['created_at']?.toString()),
      updatedAt: parseDate(json['updated_at']?.toString()),
      pivot: json['pivot'] != null ? Pivot.fromJson(Map<String, dynamic>.from(json['pivot'] as Map)) : null,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => OptionItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    int? boolToInt(bool? b) => b == null ? null : (b ? 1 : 0);

    return {
      'id': id,
      'name': name,
      'type': type,
      'is_required': boolToInt(isRequired),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (pivot != null) 'pivot': pivot!.toJson(),
      if (options != null) 'options': options!.map((o) => o.toJson()).toList(),
    };
  }
}

class Pivot {
  int? itemId;
  int? itemOptionGroupId;
  DateTime? createdAt;
  DateTime? updatedAt;

  Pivot({
    this.itemId,
    this.itemOptionGroupId,
    this.createdAt,
    this.updatedAt,
  });

  factory Pivot.fromJson(Map<String, dynamic> json) => Pivot(
    itemId: json['item_id'] is int ? json['item_id'] as int : (json['item_id'] != null ? int.tryParse(json['item_id'].toString()) : null),
    itemOptionGroupId: json['item_option_group_id'] is int ? json['item_option_group_id'] as int : (json['item_option_group_id'] != null ? int.tryParse(json['item_option_group_id'].toString()) : null),
    createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'].toString()),
    updatedAt: json['updated_at'] == null ? null : DateTime.tryParse(json['updated_at'].toString()),
  );

  Map<String, dynamic> toJson() => {
    'item_id': itemId,
    'item_option_group_id': itemOptionGroupId,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

class OptionItem {
  int? id;
  int? itemOptionGroupId;
  String? name;
  String? icon;
  bool? isActive;
  double? priceAdjustCents;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? iconUrl;

  OptionItem({
    this.id,
    this.itemOptionGroupId,
    this.name,
    this.icon,
    this.isActive,
    this.priceAdjustCents,
    this.createdAt,
    this.updatedAt,
    this.iconUrl,
  });

  factory OptionItem.fromJson(Map<String, dynamic> json) {
    double? parsePrice(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    bool? parseBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().toLowerCase();
      if (s == '1' || s == 'true') return true;
      if (s == '0' || s == 'false') return false;
      return null;
    }

    DateTime? parseDate(String? s) =>
        s == null ? null : DateTime.tryParse(s);

    return OptionItem(
      id: json['id'] is int ? json['id'] as int : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      itemOptionGroupId: json['item_option_group_id'] is int ? json['item_option_group_id'] as int : (json['item_option_group_id'] != null ? int.tryParse(json['item_option_group_id'].toString()) : null),
      name: json['name']?.toString(),
      icon: json['icon']?.toString(),
      isActive: parseBool(json['is_active']),
      priceAdjustCents: parsePrice(json['price_adjust_cents']),
      createdAt: parseDate(json['created_at']?.toString()),
      updatedAt: parseDate(json['updated_at']?.toString()),
      iconUrl: json['icon_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'item_option_group_id': itemOptionGroupId,
    'name': name,
    'icon': icon,
    'is_active': isActive == null ? null : (isActive! ? 1 : 0),
    'price_adjust_cents':
    priceAdjustCents == null ? null : priceAdjustCents!.toStringAsFixed(2),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'icon_url': iconUrl,
  };
}
