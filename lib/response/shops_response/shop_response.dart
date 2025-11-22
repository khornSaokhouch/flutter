
import '../../models/shop.dart';

class ShopResponse {
  final String message;
  final List<Shop> data;

  ShopResponse({
    required this.message,
    required this.data,
  });

  factory ShopResponse.fromJson(Map<String, dynamic> json) {
    return ShopResponse(
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>)
          .map((item) => Shop.fromJson(item))
          .toList(),
    );
  }
}
