import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_endpoints.dart';
import '../../models/shops_models/shop_categories_models.dart';

class CategoryShopController {
  String? token;

  CategoryShopController({this.token});

  /// Load token from SharedPreferences if not provided
  Future<void> _loadTokenIfNeeded() async {
    if (token == null || token!.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token'); // stored during login
    }
  }

  Future<Map<String, String>> _headers() async {
    await _loadTokenIfNeeded();

    if (token != null && token!.isNotEmpty) {
      return await ApiConfig.authHeaders(token!);
    }
    return ApiConfig.headers;
  }

  /// GET /shops/{shopId}/categories
  Future<List<CategoryModel>> fetchCategoriesByShop(int shopId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shop/categories/shop/$shopId');

    final response = await http.get(url, headers: await _headers());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CategoryModel.fromJson(e)).toList();
    } else {
      throw Exception(
          'Failed to load categories: ${response.statusCode} — ${response.body}');
    }
  }

  /// POST /shops/{shopId}/categories
  Future<CategoryModel> attachCategoryToShop({
    required int shopId,
    required int categoryId,
    int status = 1,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shop/categories/$shopId');

    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode({
        'category_id': categoryId,
        'status': status,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return CategoryModel.fromJson(data['category']);
    } else {
      throw Exception(
          'Failed to attach category: ${response.statusCode} — ${response.body}');
    }
  }

  /// PUT /shops/{shopId}/categories/{categoryId}
  Future<void> updateCategoryStatusForShop({
    required int shopId,
    required int categoryId,
    required bool status,
  }) async {
    final url =
    Uri.parse('${ApiConfig.baseUrl}/shop/categories/$categoryId/shop/$shopId');

    final response = await http.patch(
      url,
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );


    if (response.statusCode != 200) {
      throw Exception(
          'Failed to update status: ${response.statusCode} — ${response.body}');
    }
  }

  /// DELETE /shops/{shopId}/categories/{categoryId}
  Future<void> detachCategoryFromShop({
    required int shopId,
    required int categoryId,
  }) async {
    final url =
    Uri.parse('${ApiConfig.baseUrl}/shops/$shopId/categories/$categoryId');

    final response = await http.delete(url, headers: await _headers());

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to detach category: ${response.statusCode} — ${response.body}');
    }
  }

  // shop_category_server.dart (or wherever CategoryShopController is)

  Future<List<CategoryModel>> fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('${ApiConfig.baseUrl}/shop/categories');

    // Choose headers (auth vs non-auth)
    Map<String, String> headers;
    if (token != null && token.isNotEmpty) {
      headers = await ApiConfig.authHeaders(token);
    } else {
      headers = ApiConfig.headers;
    }

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final body = json.decode(response.body);

      // Expecting: { "message": "...", "data": [ ...categories... ] }
      final List<dynamic> data = body['data'] ?? [];

      return data
          .map(
            (jsonItem) =>
            CategoryModel.fromJson(jsonItem as Map<String, dynamic>),
      )
          .toList();
    } else {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }
  }
}
