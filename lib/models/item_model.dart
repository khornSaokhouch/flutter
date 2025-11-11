import 'dart:convert';

/// ✅ Root Response
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
      data: dataList.map((e) => ShopItem.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'data': data.map((e) => e.toJson()).toList(),
  };
}

/// ✅ ShopItem = Item inside a shop/category
class ShopItem {
  final int shopId;
  final int categoryId;
  final Category category;
  final Item item;

  ShopItem({
    required this.shopId,
    required this.categoryId,
    required this.category,
    required this.item,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
    shopId: json['shop_id'] ?? 0,
    categoryId: json['category_id'] ?? 0,
    category: Category.fromJson(json['category'] ?? {}),
    item: Item.fromJson(json['item'] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    'shop_id': shopId,
    'category_id': categoryId,
    'category': category.toJson(),
    'item': item.toJson(),
  };
}

/// ✅ Category model
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
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    description: json['description'],
    status: json['status'] ?? 0,
    imageUrl: json['image_url'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'status': status,
  };
}

/// ✅ Item model
class Item {
  final int id;
  final String name;
  final String? description;
  final int priceCents;
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

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    description: json['description'],
    priceCents: json['price_cents'] ?? 0,
    imageUrl: json['image_url'] ?? '',
    isAvailable: json['is_available'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price_cents': priceCents,
    'image_url': imageUrl,
    'is_available': isAvailable,
  };
}
