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

        return null;
      }
    } catch (e) {
      return null;
    }
  }
  static Future<ItemsResponse?> fetchItemsByShopCheckToken(int shopId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return null;
      }
      final url = Uri.parse('${ApiConfig.baseUrl}/users/$shopId/items');
      final headers = await ApiConfig.authHeaders(token);

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ItemsResponse.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }


  }

  /// Fetch Shop Item Option Status by itemId and shopId
  // For guests (no auth)
  static Future<List<ShopItemOptionStatusModel>?> fetchItemOptionStatusGuest(
      int itemId, int shopId) async {
    try {
      final url = Uri.parse('$baseUrl/shops/shop-item/$itemId/shopId/$shopId');
      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);

      return _parseStatusesFromDecoded(decoded, response.body);
    } catch (e) {
      return null;
    }
  }

// For authenticated users
  static Future<List<ShopItemOptionStatusModel>?> fetchItemOptionStatus(
      int itemId, int shopId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return null;
      }

      final url = Uri.parse('$baseUrl/users/shop-item/$itemId/shopId/$shopId');
      final headers = await ApiConfig.authHeaders(token);
      final response = await http.get(url, headers: headers);

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);

      return _parseStatusesFromDecoded(decoded, response.body);
    } catch (e) {
      return null;
    }
  }

// Shared parser helper
  static List<ShopItemOptionStatusModel>? _parseStatusesFromDecoded(dynamic decoded, String rawBody) {
    try {
      // Case A: top-level list
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((json) => ShopItemOptionStatusModel.fromJson(json))
            .toList();
      }

      // Case B: Laravel wrapper { "data": [...] } or { "data": {...} }
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        final data = decoded['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((json) => ShopItemOptionStatusModel.fromJson(json))
              .toList();
        } else if (data is Map<String, dynamic>) {
          return [ShopItemOptionStatusModel.fromJson(data)];
        }
      }

      // Case C: top-level map keyed by id ({"1": {...}, "2": {...}})
      if (decoded is Map<String, dynamic>) {
        // If every value is a Map => treat as map-of-objects
        final values = decoded.values.toList();
        final allValsAreMap = values.isNotEmpty && values.every((v) => v is Map<String, dynamic>);
        if (allValsAreMap) {
          final List<ShopItemOptionStatusModel> out = [];
          for (final v in values) {
            try {
              out.add(ShopItemOptionStatusModel.fromJson(v as Map<String, dynamic>));
            } catch (e) {
              // Skip unparsable entries but log for debugging
            }
          }
          return out;
        }

        // Case D: top-level single object (not wrapped)
        return [ShopItemOptionStatusModel.fromJson(decoded)];
      }

      // Unexpected shape
      return <ShopItemOptionStatusModel>[];
    } catch (e) {
      return null;
    }
  }



}
