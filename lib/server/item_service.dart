import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/api_endpoints.dart';
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
}
