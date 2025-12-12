// lib/models/shops_models/shop_item_owner_models.dart
class ItemsResponse {
  final String message;
  final List<ShopItem> data;

  ItemsResponse({
    required this.message,
    required this.data,
  });

  factory ItemsResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    return ItemsResponse(
      message: json['message'] ?? '',
      data: dataList.map((e) => ShopItem.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'data': data.map((e) => e.toJson()).toList(),
  };
}

class ShopItem {
  // This 'id' is the ItemOwner id (the record that links an item to a shop)
  final int id;
  final int shopId;
  final int categoryId;
  final Category category;
  final Item item;
  final int inactive; // 0 == active, 1 == inactive

  ShopItem({
    required this.id,
    required this.shopId,
    required this.categoryId,
    required this.category,
    required this.item,
    required this.inactive,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
    id: _toInt(json['id']),
    shopId: _toInt(json['shop_id']),
    categoryId: _toInt(json['category_id']),
    category: Category.fromJson(Map<String, dynamic>.from(json['category'] ?? {})),
    item: Item.fromJson(Map<String, dynamic>.from(json['item'] ?? {})),
    inactive: _toInt(json['inactive'] ?? 0),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'shop_id': shopId,
    'category_id': categoryId,
    'category': category.toJson(),
    'item': item.toJson(),
    'inactive': inactive,
  };
}

class Category {
  final int id;
  final String name;
  final String? description;
  final int status;
  final String? imageUrl;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: _toInt(json['id']),
    name: (json['name'] ?? '').toString(),
    description: json['description']?.toString(),
    status: _toInt(json['status']),
    imageUrl: json['image_url']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'status': status,
    'image_url': imageUrl,
  };
}

class Item {
  final int id;
  final String name;
  final String? description;
  final double priceCents; // keep as numeric representation of cents/dollars per your convention
  final String imageUrl;
  final int isAvailable;

  Item({
    required this.id,
    required this.name,
    this.description,
    required this.priceCents,
    required this.imageUrl,
    required this.isAvailable,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    final id = _toInt(json['id']);
    final name = (json['name'] ?? '').toString();
    final description = json['description']?.toString();
    // price_cents might be a string like "190.00" or a number; normalize to double
    double parsePriceCents(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      final s = v.toString();
      // attempt parse as double
      final parsed = double.tryParse(s.replaceAll(',', ''));
      return parsed ?? 0.0;
    }

    final priceCents = parsePriceCents(json['price_cents'] ?? json['priceCents'] ?? 0);
    final imageUrl = json['image_url']?.toString() ?? '';
    final isAvailable = _toInt(json['is_available'] ?? json['isAvailable'] ?? 0);

    return Item(
      id: id,
      name: name,
      description: description,
      priceCents: priceCents,
      imageUrl: imageUrl,
      isAvailable: isAvailable,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price_cents': priceCents,
    'image_url': imageUrl,
    'is_available': isAvailable,
  };
}

/// small helper for parsing ints robustly
int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
