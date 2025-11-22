class ShopItemOptionStatusModel {
  int id;
  int shopId;
  int itemId;
  int itemOptionGroupId;
  int itemOptionId;
  bool status;
  DateTime createdAt;
  DateTime updatedAt;
  Item item;
  OptionGroup optionGroup;
  Option option;

  ShopItemOptionStatusModel({
    required this.id,
    required this.shopId,
    required this.itemId,
    required this.itemOptionGroupId,
    required this.itemOptionId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.item,
    required this.optionGroup,
    required this.option,
  });

  factory ShopItemOptionStatusModel.fromJson(Map<String, dynamic> json) => ShopItemOptionStatusModel(
    id: json['id'],
    shopId: json['shop_id'],
    itemId: json['item_id'],
    itemOptionGroupId: json['item_option_group_id'],
    itemOptionId: json['item_option_id'],
    status: json['status'] == 1,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
    item: Item.fromJson(json['item']),
    optionGroup: OptionGroup.fromJson(json['option_group']),
    option: Option.fromJson(json['option']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'shop_id': shopId,
    'item_id': itemId,
    'item_option_group_id': itemOptionGroupId,
    'item_option_id': itemOptionId,
    'status': status ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'item': item.toJson(),
    'option_group': optionGroup.toJson(),
    'option': option.toJson(),
  };
}

class Item {
  int id;
  int categoryId;
  String name;
  String description;
  double priceCents;
  String imageUrl;
  bool isAvailable;
  DateTime createdAt;
  DateTime updatedAt;

  Item({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.imageUrl,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    id: json['id'],
    categoryId: json['category_id'],
    name: json['name'],
    description: json['description'] ?? '',
    priceCents: double.tryParse(json['price_cents'].toString()) ?? 0.0,
    imageUrl: json['image_url'] ?? '',
    isAvailable: json['is_available'] == 1,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category_id': categoryId,
    'name': name,
    'description': description,
    'price_cents': priceCents,
    'image_url': imageUrl,
    'is_available': isAvailable ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

class OptionGroup {
  int id;
  String name;
  String type;
  bool isRequired;
  DateTime createdAt;
  DateTime updatedAt;
  List<Option> options; // ✅ Added

  OptionGroup({
    required this.id,
    required this.name,
    required this.type,
    required this.isRequired,
    required this.createdAt,
    required this.updatedAt,
    this.options = const [], // default empty list
  });

  factory OptionGroup.fromJson(Map<String, dynamic> json) => OptionGroup(
    id: json['id'],
    name: json['name'],
    type: json['type'],
    isRequired: json['is_required'] == 1,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
    options: [], // options will be filled manually from statuses
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'is_required': isRequired ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'options': options.map((o) => o.toJson()).toList(),
  };
}


class Option {
  int id;
  int itemOptionGroupId;
  String name;
  String icon_url;
  bool isActive;
  String priceAdjustCents;
  DateTime createdAt;
  DateTime updatedAt;

  Option({
    required this.id,
    required this.itemOptionGroupId,
    required this.name,
    required this.icon_url,
    required this.isActive,
    required this.priceAdjustCents,
    required this.createdAt,
    required this.updatedAt,
  });

  double get priceAdjust => double.tryParse(priceAdjustCents) ?? 0.0;

  factory Option.fromJson(Map<String, dynamic> json) => Option(
    id: json['id'],
    itemOptionGroupId: json['item_option_group_id'],
    name: json['name'] ?? '',
    icon_url: json['icon_url'] ?? '',
    isActive: json['is_active'] == 1,
    priceAdjustCents: json['price_adjust_cents']?.toString() ?? '0',
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'item_option_group_id': itemOptionGroupId,
    'name': name,
    'icon_url': icon_url,
    'is_active': isActive ? 1 : 0,
    'price_adjust_cents': priceAdjustCents,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}


