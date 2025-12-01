class ShopOptionCreate {
  int? id;
  int? shopId;
  int? itemId;
  int? itemOptionGroupId;
  int? itemOptionId;
  bool? status;       // <-- change to bool
  String? createdAt;
  String? updatedAt;

  ShopOptionCreate({
    this.id,
    this.shopId,
    this.itemId,
    this.itemOptionGroupId,
    this.itemOptionId,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  ShopOptionCreate.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    shopId = json['shop_id'];
    itemId = json['item_id'];
    itemOptionGroupId = json['item_option_group_id'];
    itemOptionId = json['item_option_id'];

    // Convert 0/1 or true/false safely
    final s = json['status'];
    if (s is int) {
      status = s == 1;
    } else if (s is bool) {
      status = s;
    } else {
      status = false;
    }

    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['shop_id'] = shopId;
    data['item_id'] = itemId;
    data['item_option_group_id'] = itemOptionGroupId;
    data['item_option_id'] = itemOptionId;

    // Convert bool → int for API
    data['status'] = status == true ? 1 : 0;

    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
