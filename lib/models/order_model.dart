// models_order.dart

import 'package:frontend/models/shop.dart'; // <- uses your Shop model

/// ----------------------
/// Utils for parsing
/// ----------------------
int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) {
    if (v.contains('.')) {
      final d = double.tryParse(v.replaceAll(',', ''));
      return d == null ? 0 : d.toInt();
    }
    return int.tryParse(v.replaceAll(',', '')) ?? 0;
  }
  return 0;
}

String _parseString(dynamic v) => v?.toString() ?? '';

/// Parse price-like values into integer cents.
///
/// Handles forms like:
///  - int (already cents) -> returns as-is
///  - double -> treat as dollars -> cents (round)
///  - "250.00" -> dollars -> 25000
///  - "25000" -> ambiguous -> treated as cents
int parsePriceToCents(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return (v * 100).round();
  if (v is String) {
    final s = v.replaceAll(',', '').trim();
    if (s.isEmpty) return 0;
    // contains decimal -> treat as dollars
    if (s.contains('.')) {
      final d = double.tryParse(s);
      return d == null ? 0 : (d * 100).round();
    }
    // no decimal -> heuristic:
    // if length > 3 treat as cents (e.g. "25000" -> 25000)
    // else treat as dollars (e.g. "250" -> 25000)
    final numeric = int.tryParse(s);
    if (numeric == null) return 0;
    if (s.length > 3) return numeric; // assume cents
    return numeric * 100; // assume dollars
  }
  return 0;
}

/// ----------------------
/// ItemModel (nested item)
/// ----------------------
class ItemModel {
  final int id;
  final int? categoryId;
  final String name;
  final String? description;
  final int priceCents;
  final String? imageUrl;
  final bool? isAvailable;

  ItemModel({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.priceCents,
    this.imageUrl,
    this.isAvailable,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: _parseInt(json['id']),
      categoryId: json['category_id'] == null ? null : _parseInt(json['category_id'] ?? json['categoryId']),
      name: _parseString(json['name']),
      description: json['description'] == null ? null : _parseString(json['description']),
      priceCents: parsePriceToCents(json['price_cents'] ?? json['priceCents'] ?? json['price']),
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? json['image'],
      isAvailable: json['is_available'] == null ? null : (_parseInt(json['is_available']) == 1),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category_id': categoryId,
    'name': name,
    'description': description,
    'price_cents': priceCents,
    'image_url': imageUrl,
    'is_available': isAvailable == null ? null : (isAvailable! ? 1 : 0),
  };

  @override
  String toString() {
    return 'ItemModel(id: $id, name: $name, price: ${priceCents / 100.0})';
  }
}

/// ----------------------
/// OptionGroupModel
/// ----------------------
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

  factory OptionGroupModel.fromJson(Map<String, dynamic> json) {
    return OptionGroupModel(
      groupId: _parseInt(json['group_id'] ?? json['groupId']),
      optionId: _parseInt(json['option_id'] ?? json['optionId']),
      groupName: _parseString(json['group_name'] ?? json['groupName']),
      selectedOption: _parseString(json['selected_option'] ?? json['selectedOption']),
    );
  }

  Map<String, dynamic> toJson() => {
    'group_id': groupId,
    'option_id': optionId,
    'group_name': groupName,
    'selected_option': selectedOption,
  };

  @override
  String toString() {
    return '$groupName: $selectedOption';
  }
}

/// ----------------------
/// OrderItemModel
/// ----------------------
class OrderItemModel {
  final int? id;
  final int? orderid;
  final int itemid;
  final String namesnapshot;
  final int unitpriceCents;
  final int quantity;
  final String? notes;
  final List<OptionGroupModel> optionGroups;
  final ItemModel? item; // nested item (optional)
  final Shop? shop; // nested shop (optional) - uses your Shop model

  OrderItemModel({
    this.id,
    this.orderid,
    required this.itemid,
    required this.namesnapshot,
    required this.unitpriceCents,
    required this.quantity,
    this.notes,
    required this.optionGroups,
    this.item,
    this.shop,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final optionGroupsList = (json['option_groups'] ?? json['optionGroups']) as List<dynamic>?;
    final nestedItemJson = json['item'] as Map<String, dynamic>?;

    // Try to find shop payload at several possible locations:
    final shopJson = (json['shop'] as Map<String, dynamic>?) ??
        (json['store'] as Map<String, dynamic>?) ??
        (nestedItemJson != null ? (nestedItemJson['shop'] as Map<String, dynamic>?) : null);

    return OrderItemModel(
      id: json['id'] == null ? null : _parseInt(json['id']),
      orderid: json['orderid'] == null ? null : _parseInt(json['orderid']),
      itemid: _parseInt(json['itemid'] ?? json['itemId'] ?? (nestedItemJson != null ? nestedItemJson['id'] : null)),
      namesnapshot: _parseString(json['namesnapshot'] ?? json['nameSnapshot'] ?? json['name'] ?? (nestedItemJson != null ? nestedItemJson['name'] : '')),
      unitpriceCents: _parseInt(json['unitprice_cents'] ?? json['unitpriceCents'] ?? json['unit_price'] ?? json['price_cents'] ?? json['priceCents'] ?? json['price'] ?? (nestedItemJson != null ? nestedItemJson['price_cents'] ?? nestedItemJson['price'] : null)),
      quantity: _parseInt(json['quantity'] ?? json['qty'] ?? 1),
      notes: json['notes']?.toString(),
      optionGroups: (optionGroupsList ?? []).map((e) => OptionGroupModel.fromJson(e as Map<String, dynamic>)).toList(),
      item: nestedItemJson == null ? null : ItemModel.fromJson(nestedItemJson),
      shop: shopJson == null ? null : Shop.fromJson(shopJson),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderid': orderid,
    'itemid': itemid,
    'namesnapshot': namesnapshot,
    'unitprice_cents': unitpriceCents,
    'quantity': quantity,
    'notes': notes,
    'option_groups': optionGroups.map((e) => e.toJson()).toList(),
    'item': item?.toJson(),
    'shop': shop == null ? null : {
      'id': shop!.id,
      'name': shop!.name,
      'location': shop!.location,
      'open_time': shop!.openTime,
      'close_time': shop!.closeTime,
      'image_url': shop!.imageUrl,
    },
  };

  factory OrderItemModel.fromItem(
      dynamic item, {
        int quantity = 1,
        String? notes,
        List<OptionGroupModel> optionGroups = const [],
      }) {
    // If item is a Map (JSON), try to extract common fields; otherwise assume it's a typed Item.
    final int id = (item is Map<String, dynamic>) ? _parseInt(item['id'] ?? item['itemid']) : (item.id is int ? item.id as int : _parseInt(item.id));

    final String name = (item is Map<String, dynamic>) ? _parseString(item['name'] ?? item['namesnapshot'] ?? item['nameSnapshot']) : _parseString(item.name);

    final dynamic rawPrice = (item is Map<String, dynamic>) ? (item['price_cents'] ?? item['price'] ?? item['priceCents']) : (item.priceCents ?? item.price ?? item.priceCents);

    final int cents = parsePriceToCents(rawPrice);

    return OrderItemModel(
      id: null,
      orderid: null,
      itemid: id,
      namesnapshot: name,
      unitpriceCents: cents,
      quantity: quantity,
      notes: notes,
      optionGroups: optionGroups,
      item: (item is Map<String, dynamic>) ? ItemModel.fromJson(item) : null,
      shop: null,
    );
  }

  @override
  String toString() {
    return 'OrderItem(itemid: $itemid, name: $namesnapshot, unitPrice: ${unitpriceCents / 100.0}, qty: $quantity, shop: ${shop?.name})';
  }
}

/// ----------------------
/// OrderModel
/// ----------------------
class OrderModel {
  int? id;
  int userid;
  int? shopid;
  int? promoid;
  String status;
  int subtotalcents;
  int discountcents;
  int totalcents;
  String? placedat;
  List<OrderItemModel> orderItems;
  Shop? shop; // optional top-level shop parsed using your Shop model

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
    this.shop,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['order_items'] ?? json['orderItems']) as List<dynamic>?;
    final shopJson = (json['shop'] as Map<String, dynamic>?) ?? (json['store'] as Map<String, dynamic>?);

    return OrderModel(
      id: json['id'] == null ? null : _parseInt(json['id']),
      userid: _parseInt(json['userid'] ?? json['userId']),
      shopid: json['shopid'] == null ? null : _parseInt(json['shopid']),
      promoid: json['promoid'] == null ? null : _parseInt(json['promoid']),
      status: _parseString(json['status']),
      subtotalcents: _parseInt(json['subtotalcents'] ?? json['subtotal_cents']),
      discountcents: _parseInt(json['discountcents'] ?? json['discount_cents']),
      totalcents: _parseInt(json['totalcents'] ?? json['total_cents']),
      placedat: json['placedat'] ?? json['placed_at'],
      orderItems: (itemsList ?? []).map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>)).toList(),
      shop: shopJson == null ? null : Shop.fromJson(shopJson),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userid': userid,
    'shopid': shopid,
    'promoid': promoid,
    'status': status,
    'subtotalcents': subtotalcents,
    'discountcents': discountcents,
    'totalcents': totalcents,
    'placedat': placedat,
    'order_items': orderItems.map((e) => e.toJson()).toList(),
    'shop': shop == null
        ? null
        : {
      'id': shop!.id,
      'name': shop!.name,
      'location': shop!.location,
      'open_time': shop!.openTime,
      'close_time': shop!.closeTime,
      'image_url': shop!.imageUrl,
    },
  };

  /// Convenience: add an OrderItemModel directly
  void addItem(OrderItemModel item) {
    orderItems.add(item);
    recalculateTotals();
  }

  /// Convenience: create an OrderItemModel from a Map or typed item and add it
  void addItemFromItem(
      dynamic item, {
        int quantity = 1,
        String? notes,
        List<OptionGroupModel> optionGroups = const [],
      }) {
    final orderItem = OrderItemModel.fromItem(
      item,
      quantity: quantity,
      notes: notes,
      optionGroups: optionGroups,
    );
    addItem(orderItem);
  }

  /// Recompute subtotal and total (simple sum of unitprice * qty).
  /// Does NOT apply promotions — you can extend this later.
  void recalculateTotals() {
    int subtotal = 0;
    for (final it in orderItems) {
      subtotal += it.unitpriceCents * it.quantity;
    }
    subtotalcents = subtotal;
    totalcents = subtotal - discountcents;
    if (totalcents < 0) totalcents = 0;
  }

  @override
  String toString() {
    return 'OrderModel(id: $id, userId: $userid, total: ${totalcents / 100.0}, items: ${orderItems.length}, shop: ${shop?.name})';
  }
}
