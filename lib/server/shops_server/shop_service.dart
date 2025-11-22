import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_endpoints.dart';
import '../../response/shops_response/shop_response.dart';

class ShopsService {
  /// Fetch shops for the authenticated owner
  static Future<ShopResponse> getShopsByOwner() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // 🔐 No token saved
    if (token == null || token.isEmpty) {
      throw Exception('No auth token found. Please log in again.');
    }

    // ⚠️ Make sure this matches your Laravel route:
    // Route::get('/shops/owner', ...) -> '/shops/owner' (plural)
    final url = Uri.parse('${ApiConfig.baseUrl}/shop/owner');

    final headers = await ApiConfig.authHeaders(token);

    final response = await http.get(url, headers: headers);

    // ✅ Success
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonBody = json.decode(response.body);
      return ShopResponse.fromJson(jsonBody);
    }

    // 🕳️ No shops found (your controller returns 404 with message)
    if (response.statusCode == 404) {
      try {
        final Map<String, dynamic> jsonBody = json.decode(response.body);
        return ShopResponse(
          message: jsonBody['message'] ?? 'No shops found for your account.',
          data: [],
        );
      } catch (_) {
        return ShopResponse(
          message: 'No shops found for your account.',
          data: [],
        );
      }
    }

    // 🔑 Unauthorized
    if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please log in again.');
    }

    // 💥 Other server errors
    throw Exception(
      'Failed to load shops: [${response.statusCode}] ${response.body}',
    );
  }
}
