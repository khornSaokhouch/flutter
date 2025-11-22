import '../Item_OptionGroup.dart';
import '../category_models.dart';
import '../shop.dart';

class ItemOwner {
  final int id;
  final int itemId;
  final int shopId;
  final int categoryId;
  int inactive; // <-- make this mutable
  final String createdAt;
  final String updatedAt;
  final Item item;
  final Category category;
  final Shop shop;

  ItemOwner({
    required this.id,
    required this.itemId,
    required this.shopId,
    required this.categoryId,
    required this.inactive,
    required this.createdAt,
    required this.updatedAt,
    required this.item,
    required this.category,
    required this.shop,
  });

  factory ItemOwner.fromJson(Map<String, dynamic> json) {
    return ItemOwner(
      id: json['id'],
      itemId: json['item_id'],
      shopId: json['shop_id'],
      categoryId: json['category_id'],
      inactive: json['inactive'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      item: Item.fromJson(json['item']),
      category: Category.fromJson(json['category']),
      shop: Shop.fromJson(json['shop']),
    );
  }
}

