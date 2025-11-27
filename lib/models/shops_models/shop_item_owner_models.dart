import '../Item_OptionGroup.dart';
import '../category_models.dart';
import '../shop.dart';

class ItemOwner {
  final int id;
  final int itemId;
  final int shopId;
  final int categoryId;
  int inactive;
  final String createdAt;
  final String updatedAt;
  final Item? item;
  final Category? category;
  final Shop? shop;

  ItemOwner({
    required this.id,
    required this.itemId,
    required this.shopId,
    required this.categoryId,
    required this.inactive,
    required this.createdAt,
    required this.updatedAt,
    this.item,
    this.category,
    this.shop,
  });

  factory ItemOwner.fromJson(Map<String, dynamic> json) {
    return ItemOwner(
      id: json['id'],
      itemId: json['item_id'],
      shopId: json['shop_id'],
      categoryId: json['category_id'],
      inactive: json['inactive'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      item: json['item'] != null ? Item.fromJson(json['item']) : null,
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      shop: json['shop'] != null ? Shop.fromJson(json['shop']) : null,
    );
  }
}
