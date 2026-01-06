import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_endpoints.dart';
import '../../models/item_option_group.dart';
import '../../models/shops_models/shop_create_options.dart';
import '../../models/shops_models/shop_options_model.dart';

class ShopItemOptionStatusService {

  /// Fetch all active option statuses by item + shop (with token)
  static Future<List<ShopItemOptionStatusModel>> getStatuses(
      int itemId, int shopId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse("${ApiConfig.baseUrl}/shop/shop-item-option-status/$itemId/shopId/$shopId");

    try {
      // 🔐 No token saved
      if (token == null || token.isEmpty) {
        throw Exception('No auth token found. Please log in again.');
      }

      final headers = await ApiConfig.authHeaders(token);

      final response = await http.get(url, headers: headers);


      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);

        return jsonList
            .map((json) => ShopItemOptionStatusModel.fromJson(json))
            .toList();
      }
      else if (response.statusCode == 404) {
        return [];
      }
      else {
        throw Exception("Failed: ${response.body}");
      }

    } catch (e) {
      throw Exception("Error fetching statuses: $e");
    }
  }

  static Future<bool> updateStatus(int id, bool status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception("No auth token found");
    }

    final url = Uri.parse("${ApiConfig.baseUrl}/shop/shop-item-option-status/$id");

    final response = await http.patch(
      url,
      headers: await ApiConfig.authHeaders(token),
      body: jsonEncode({
        "status": status,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    }

    throw Exception("Failed to update status: ${response.body}");
  }

  static Future<ShopOptions> getItemDetails(int itemId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception("No auth token found");
      }

      final url = Uri.parse(
          "${ApiConfig.baseUrl}/shop/items/$itemId");

      final response = await http.get(
        url,
        headers: await ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return ShopOptions.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw Exception("Item not found");
      } else {
        throw Exception("Server error: ${response.body}");
      }
    } catch (e) {
      throw Exception("Failed to load item details: $e");
    }
  }

  static Future<ShopOptionCreate> createStatus({
    required int shopId,
    required int itemId,
    required int itemOptionGroupId,
    required int itemOptionId,
    bool status = true,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse(
      "${ApiConfig.baseUrl}/shop/shop-item-option-status",
    );
    if (token == null) {
      throw Exception("No auth token found");
    }


    final headers = await ApiConfig.authHeaders(token);


    final body = {
      "shop_id": shopId,
      "item_id": itemId,
      "item_option_group_id": itemOptionGroupId,
      "item_option_id": itemOptionId,
      "status": status ? 1 : 0,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return ShopOptionCreate.fromJson(jsonDecode(response.body));
    }

    throw Exception("Failed to create status: ${response.body}");
  }


}
