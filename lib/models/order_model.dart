class OptionGroupModel {
  final int groupId;
  final int optionId;
  final String groupName;
  final String selectedOption;

  OptionGroupModel({
    required this.groupId,
    required this.optionId,
    required this.groupName,
    required this.selectedOption,
  });

  factory OptionGroupModel.fromJson(Map<String, dynamic> json) => OptionGroupModel(
    groupId: json['group_id'],
    optionId: json['option_id'],
    groupName: json['group_name'] ?? '',
    selectedOption: json['selected_option'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'group_id': groupId,
    'option_id': optionId,
    'group_name': groupName,
    'selected_option': selectedOption,
  };
}

class OrderItemModel {
  final int? id;
  final int itemid;
  final String namesnapshot;
  final int unitpriceCents;
  final int quantity;
  final String? notes;
  final List<OptionGroupModel> optionGroups;

  OrderItemModel({
    this.id,
    required this.itemid,
    required this.namesnapshot,
    required this.unitpriceCents,
    required this.quantity,
    this.notes,
    required this.optionGroups,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
    id: json['id'],
    itemid: json['itemid'],
    namesnapshot: json['namesnapshot'] ?? '',
    unitpriceCents: json['unitprice_cents'],
    quantity: json['quantity'],
    notes: json['notes'],
    optionGroups: (json['option_groups'] as List? ?? []).map((e) => OptionGroupModel.fromJson(e)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'itemid': itemid,
    'namesnapshot': namesnapshot,
    'unitprice_cents': unitpriceCents,
    'quantity': quantity,
    'notes': notes,
    'option_groups': optionGroups.map((e) => e.toJson()).toList(),
  };
}

class OrderModel {
  final int? id;
  final int userid;
  final int? shopid;
  final int? promoid;
  final String status;
  final int subtotalcents;
  final int discountcents;
  final int totalcents;
  final String? placedat;
  final List<OrderItemModel> orderItems;

  OrderModel({
    this.id,
    required this.userid,
    this.shopid,
    this.promoid,
    required this.status,
    required this.subtotalcents,
    required this.discountcents,
    required this.totalcents,
    this.placedat,
    required this.orderItems,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: json['id'],
    userid: json['userid'],
    shopid: json['shopid'],
    promoid: json['promoid'],
    status: json['status'],
    subtotalcents: json['subtotalcents'] ?? 0,
    discountcents: json['discountcents'] ?? 0,   // <-- FIXED
    totalcents: json['totalcents'] ?? 0,
    placedat: json['placedat'],
    orderItems: (json['order_items'] as List? ?? []).map((e) => OrderItemModel.fromJson(e)).toList(),
  );
}
