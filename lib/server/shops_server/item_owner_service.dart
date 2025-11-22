import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


import '../../config/api_endpoints.dart';
import '../../models/shops_models/shop_item_owner_models.dart';
import '../../response/shops_response/shop_item_response.dart';

class ItemOwnerService {
  /// Load token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token"); // adjust key if needed
  }

  /// Build headers (auth if token exists)
  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();

    if (token != null && token.isNotEmpty) {
      return ApiConfig.authHeaders(token);
    }

    return ApiConfig.headers;
  }

  /// Fetch items by shop_id and category_id
  static Future<List<ItemOwner>> fetchItemsByShopAndCategory({
    required int shopId,
    required int categoryId,
  }) async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/shop/items?shop_id=$shopId&category_id=$categoryId",
    );

    final headers = await _headers();  // 🔥 now token-aware

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final itemResponse = ItemResponse.fromJson(jsonBody);

      return itemResponse.data;
    } else {
      throw Exception("Failed to load items: ${response.body}");
    }
  }
  /// 🔥 Update inactive status (0/1) for an ItemOwner
  /// 🔥 Update inactive status (0/1) for an ItemOwner
  static Future<void> updateStatus({
    required int id,
    required int inactive, // 1 = active, 0 = inactive
  }) async {
    // 👇 adjust path to match your Laravel route
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/shop/items/$id/status",
    );

    final headers = await _headers();

    final body = jsonEncode({
      "inactive": inactive, // Laravel validates 'inactive' as boolean
    });

    final response = await http.patch(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      // You can inspect response.body if needed
      throw Exception(
        "Failed to update status: ${response.statusCode} ${response.body}",
      );
    }

    // We don't parse ItemOwner here – we just trust backend succeeded.
  }
}

