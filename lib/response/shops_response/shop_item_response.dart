import '../../models/shops_models/shop_item_owner_models.dart';

class ItemResponse {
  final String message;
  final List<ItemOwner> data;

  ItemResponse({
    required this.message,
    required this.data,
  });

  factory ItemResponse.fromJson(Map<String, dynamic> json) {
    return ItemResponse(
      message: json['message'],
      data: (json['data'] as List)
          .map((item) => ItemOwner.fromJson(item))
          .toList(),
    );
  }
}
