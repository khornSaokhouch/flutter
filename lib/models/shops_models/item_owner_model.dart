// lib/models/shops_models/item_owner_model.dart
import 'dart:convert';

class ItemOwnerModel {
  final int id;
  final int itemId;
  final int shopId;
  final int categoryId;
  int inactive;
  final String createdAt;
  final String updatedAt;

  ItemOwnerModel({
    required this.id,
    required this.itemId,
    required this.shopId,
    required this.categoryId,
    required this.inactive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItemOwnerModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      if (v is double) return v.toInt();
      return 0;
    }

    String parseString(dynamic v) => v?.toString() ?? '';

    return ItemOwnerModel(
      id: parseInt(json['id']),
      itemId: parseInt(json['item_id']),
      shopId: parseInt(json['shop_id']),
      categoryId: parseInt(json['category_id']),
      inactive: parseInt(json['inactive']),
      createdAt: parseString(json['created_at']),
      updatedAt: parseString(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'item_id': itemId,
    'shop_id': shopId,
    'category_id': categoryId,
    'inactive': inactive,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  @override
  String toString() => 'ItemOwnerModel(id:$id,itemId:$itemId,shopId:$shopId)';
}

/// Robust parser: accepts List, Map with data:List, single object Map, or encoded JSON string.
List<ItemOwnerModel> parseItemOwners(dynamic payload) {
  if (payload == null) return <ItemOwnerModel>[];

  // If it's already a decoded List
  if (payload is List) {
    return payload
        .where((e) => e != null)
        .map((e) => ItemOwnerModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // If it's a Map (either single or wrapper)
  if (payload is Map) {
    final map = Map<String, dynamic>.from(payload);
    if (map.containsKey('data') && map['data'] is List) {
      return (map['data'] as List)
          .where((e) => e != null)
          .map((e) => ItemOwnerModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    // single object
    if (map.containsKey('id')) {
      return [ItemOwnerModel.fromJson(map)];
    }
    // try to find any list-valued entry
    for (final entry in map.entries) {
      if (entry.value is List) {
        try {
          return (entry.value as List)
              .where((e) => e != null)
              .map((e) => ItemOwnerModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        } catch (_) {}
      }
    }
    return <ItemOwnerModel>[];
  }

  // If it's a JSON string
  if (payload is String) {
    try {
      final decoded = jsonDecode(payload);
      return parseItemOwners(decoded);
    } catch (_) {
      return <ItemOwnerModel>[];
    }
  }

  return <ItemOwnerModel>[];
}
