import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_endpoints.dart';
import '../models/shop.dart';


class ShopService {
  // Fetch all shops (public or admin depending on token)
  static Future<ShopsResponse?> fetchShops({String? token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/shops');

    final headers = token != null
        ? await ApiConfig.authHeaders(token)
        : ApiConfig.headers;

    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ShopsResponse.fromJson(jsonData);
      } else {

        return null;
      }
    } catch (e) {

      return null;
    }
  }
  static Future<Shop?> fetchShopById(int shopId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shops/$shopId');

    try {
      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final shopData = jsonData['data'];
        return Shop.fromJson(shopData);
      } else {
        return null;
      }
    } catch (e) {

      return null;
    }
  }
  static Future<List<Shop>> fetchShopNearly({
    required double latitude,
    required double longitude,
    double radius = 10,
  }) async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/shops/nearby?latitude=$latitude&longitude=$longitude&radius=$radius",
    );

    final response = await http.get(url, headers: ApiConfig.headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final shopsResponse = ShopsResponse.fromJson(data);
      return shopsResponse.data;
    } else {
      throw Exception("Failed to load nearby shops");
    }
  }

  static Future<Shop?> updateShop(int shopId, Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shops/$shopId');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      // Handle not being logged in
      return null;
    }

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final shopData = jsonData['data'];
        return Shop.fromJson(shopData);
      } else {
        // Handle error
        return null;
      }
    } catch (e) {
      // Handle exception
      return null;
    }
  }


}
