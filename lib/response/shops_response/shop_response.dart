import '../../models/shop.dart';

class ShopResponse {
  final String message;
  final List<Shop> data;

  ShopResponse({
    required this.message,
    required this.data,
  });

  factory ShopResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];

    return ShopResponse(
      message: json['message'] ?? '',
      data: rawData == null
          ? []
          : rawData is List
          ? rawData.map((e) => Shop.fromJson(e)).toList()
          : [Shop.fromJson(rawData)], // ✅ wrap single object
    );
  }
}
