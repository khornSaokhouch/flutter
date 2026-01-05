import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_endpoints.dart'; // contains ApiConfig
import '../../models/item_model.dart';
import '../../models/shops_models/item_owner_model.dart';
import '../../models/shops_models/shop_item_owner_models.dart';
import '../../response/shops_response/shop_item_response.dart';

/// Simple API exception to throw structured errors
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

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
      // If ApiConfig.authHeaders returns a Future<Map<...>>, await it
      final auth = await ApiConfig.authHeaders(token);
      return auth;
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

    final headers = await _headers(); // token-aware

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      final itemResponse = ItemResponse.fromJson(Map<String, dynamic>.from(jsonBody));
      return itemResponse.data;
    } else {
      // you can throw ApiException instead for consistency
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Update inactive status (0/1) for an ItemOwner
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
      "inactive": inactive,
    });

    final response = await http.patch(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        "Failed to update status: ${response.body}",
      );
    }
  }



  /// Fetch all items for a category using backend's showAllByCategory($categoryId)
  static Future<List<Item>> fetchItemsByCategory(int categoryId) async {
    // NOTE: fixed string quoting and route. Adjust route if your backend uses a different path.
    final url = Uri.parse("${ApiConfig.baseUrl}/shop/items/category/$categoryId");

    final headers = await _headers();

    final resp = await http.get(url, headers: headers);

    if (resp.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(resp.body);
      // expected: { "message": "...", "data": [ ... ] }
      final data = body['data'];
      if (data is List) {
        return data
            .map((e) => Item.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        return [];
      }
    }

    // Common errors from your controller: 404, 400
    if (resp.statusCode == 404 || resp.statusCode == 400) {
      final Map<String, dynamic> err = json.decode(resp.body);
      final message = err['error'] ?? err['message'] ?? 'Unknown error';
      throw ApiException(resp.statusCode, message);
    }

    // other failures
    throw ApiException(resp.statusCode, 'Failed to fetch items');
  }


  static Future<List<ItemOwnerModel>?> createItemOwners(
      List<Map<String, dynamic>> payload) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/shop/item");

    final headers = await _headers();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final body = response.body;
      if (body.isEmpty) return <ItemOwnerModel>[];

      dynamic decoded;
      try {
        decoded = jsonDecode(body);
      } catch (e) {
        // Not JSON — cannot parse
        return <ItemOwnerModel>[];
      }

      // Use the robust parser
      final parsed = parseItemOwners(decoded);
      return parsed;
    } else {
      // throw with useful info
      throw Exception("Error ${response.statusCode}: ${response.body}");
    }
  }


}
