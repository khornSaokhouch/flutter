// lib/utils/order_mapper.dart


import '../../models/order_model.dart';
import '../../models/shop.dart';

Map<String, dynamic> buildOrderDataMap({
  required OrderModel order,
  Shop? shop,
}) {
  final shopName = shop?.name ?? 'Shop #${order.shopid ?? 'N/A'}';

  final items = order.orderItems.map((item) {
    final imageUrl = item.item?.imageUrl ?? '';
    final optionsText = (item.optionGroups)
        .map((g) => g.selectedOption)
        .where((s) => s.isNotEmpty)
        .join(', ');

    final int lineTotalCents = (item.unitpriceCents) * (item.quantity);

    return {
      'id': item.id,
      'itemid': item.itemid,
      'name': item.namesnapshot,
      'image': imageUrl,
      'qty': item.quantity,
      'unitprice_cents': item.unitpriceCents,
      'unitprice': (item.unitpriceCents) / 100.0,
      'line_total_cents': lineTotalCents,
      'line_total': lineTotalCents / 100.0,
      'options': optionsText,
      'notes': item.notes,
    };
  }).toList();

  return {
    'id': order.id,
    'userid': order.userid,
    'status': order.status,
    'placedat': order.placedat,
    'subtotalcents': order.subtotalcents,
    'discountcents': order.discountcents,
    'totalcents': order.totalcents,
    // convenience dollars
    'subtotal': (order.subtotalcents / 100.0),
    'discount': (order.discountcents / 100.0),
    'total': (order.totalcents / 100.0),
    'shop_id': order.shopid,
    'shop_name': shopName,
    'shop_address': shop?.location,
    'shop_image': shop?.imageUrl,
    'items': items,
    'notes': null, // top-level notes if you have one (set from order if available)
  };
}
