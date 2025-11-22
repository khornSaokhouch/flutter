import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_endpoints.dart';
import '../models/Item_OptionGroup.dart';
import '../models/item_model.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ItemService {
  // Base URL
  static final String baseUrl = ApiConfig.baseUrl;

  /// Fetch items by shop_id
  static Future<ItemsResponse?> fetchItemsByShop(int shopId) async {
    try {
      final url = Uri.parse('$baseUrl/shops/$shopId/items');

      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ItemsResponse.fromJson(data);
      } else {
        print('❌ Failed (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      print('⚠️ Error fetching items: $e');
      return null;
    }
  }
  static Future<ItemsResponse?> fetchItemsByShopCheckToken(int shopId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print('❌ No token found. User may not be logged in.');
        return null;
      }
      final url = Uri.parse('${ApiConfig.baseUrl}/users/$shopId/items');
      final headers = await ApiConfig.authHeaders(token);

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Success: ${response.body}');
        return ItemsResponse.fromJson(data);
      } else {
        print('❌ Failed (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      print('⚠️ Error fetching items: $e');
      return null;
    }


  }

  /// Fetch a single item with assigned option groups and options
  // static Future<ItemOptionGroup?> fetchItemWithOptions(int itemId) async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString('token');
  //
  //     if (token == null) {
  //       return null;
  //     }
  //
  //     final url = Uri.parse('$baseUrl/users/item-option-groups/$itemId');
  //     final headers = await ApiConfig.authHeaders(token);
  //
  //     final response = await http.get(url, headers: headers);
  //
  //     if (response.statusCode == 200) {
  //       print('✅ Success: ${response.body}');
  //       final decoded = jsonDecode(response.body);
  //
  //       // Sometimes your API wraps the result in { "message": "...", "data": {...} }
  //       final data = decoded['data'] ?? decoded;
  //
  //       if (data == null || data.isEmpty) {
  //
  //         return null;
  //       }
  //
  //       final item = ItemOptionGroup.fromJson(data);
  //       return item;
  //     } else {
  //       return null;
  //     }
  //   } catch (e) {
  //     return null;
  //   }
  // }
  /// Fetch Shop Item Option Status by itemId and shopId
  static Future<List<ShopItemOptionStatusModel>?> fetchItemOptionStatus(
      int itemId, int shopId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print('❌ No token found. User may not be logged in.');
        return null;
      }
      // URL with query parameter
      final url = Uri.parse('$baseUrl/users/shop-item/$itemId/shopId/$shopId');

      final headers = await ApiConfig.authHeaders(token);
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        return data
            .map((json) => ShopItemOptionStatusModel.fromJson(json))
            .toList();
      } else {
        print('❌ Failed (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      print('⚠️ Error fetching option status: $e');
      return null;
    }
  }

  static Future<List<ShopItemOptionStatusModel>?> fetchItemOptionStatusGuest(
      int itemId, int shopId) async {
    try {
        // Make sure this matches your Laravel route
        final url = Uri.parse('$baseUrl/shops/shop-item/$itemId/shopId/$shopId');
        print(url);
        final response = await http.get(url, headers: ApiConfig.headers);
        print('✅ Response: ${response.body}');

        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);

          return data
              .map((json) => ShopItemOptionStatusModel.fromJson(json))
              .toList();
        } else {
          print('❌ Failed (${response.statusCode}): ${response.body}');
          return null;
        }
      } catch (e) {
      print('⚠️ Error fetching option status: $e');
      return null;
    }
  }


}
