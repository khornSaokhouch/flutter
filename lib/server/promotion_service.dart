// lib/services/promotion_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_endpoints.dart';
import '../models/promotion_model.dart'; // <-- import your model

class PromotionService {

  final String baseUrl = ApiConfig.baseUrl;

  // -------------------------------------------------------------
  // GET PROMOTION BY CODE → returns PromotionModel
  // -------------------------------------------------------------
  Future<PromotionModel> getPromotionByCode(String code) async {
    final uri = Uri.parse('$baseUrl/shop/promotions')
        .replace(queryParameters: {'code': code});


    final headers = await _defaultHeaders();
    final res = await http.get(uri, headers: headers);

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);

      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'] ?? decoded;

        if (data is Map<String, dynamic>) {
          return PromotionModel.fromJson(data);
        }
      }

      throw Exception('Unexpected promotion response: ${res.body}');
    }

    if (res.statusCode == 404) {
      throw Exception('Promotion not found for code: $code');
    }

    throw Exception(
      'getPromotionByCode failed: ${res.statusCode} ${res.body}',
    );
  }

  Future<List<PromotionModel>> getPromotionByShopId(int id, ) async {
    final uri = Uri.parse('$baseUrl/shop/promotions/shops')
        .replace(queryParameters: {'shopid': id.toString()});

    final headers = await _defaultHeaders();
    final res = await http.get(uri, headers: headers);

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);

      if (decoded is List) {
        return decoded
            .map((item) => PromotionModel.fromJson(item))
            .toList();
      }

      throw Exception('Unexpected format: expected a list.');
    }

    throw Exception(
      'getPromotionByShopId failed: ${res.statusCode} ${res.body}',
    );
  }


  // -------------------------------------------------------------
  // CREATE PROMOTION → returns PromotionModel
  // -------------------------------------------------------------
  /// Preferred: send a PromotionModel and get a PromotionModel back
  Future<PromotionModel> createPromotion(PromotionModel promotion) async {
    final uri = Uri.parse('$baseUrl/shop/promotions'); // confirm endpoint
    final headers = await _defaultHeaders();

    // normalize type for backend
    final rawType = (promotion.type ?? '').toLowerCase();
    final backendType = (rawType == 'fixed' || rawType == 'fixedamount' || rawType == 'fixed_amount')
        ? 'fixedamount'
        : 'percent';

    final payload = <String, dynamic>{
      'shopid': promotion.shopid,
      'code': promotion.code,
      'type': backendType,
      'value': promotion.value.toInt(), // Laravel expects integer
      'startsat': promotion.startsat,
      'endsat': promotion.endsat,
      'isactive': promotion.isactive == 1, // boolean
      'usagelimit': promotion.usagelimit,
    };

    // useful debug log while developing
    // ignore: avoid_print

    final res = await http.post(uri, headers: headers, body: jsonEncode(payload));

    if (res.statusCode == 201 || res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final data = decoded['data'] ?? decoded;
      if (data is Map<String, dynamic>) return PromotionModel.fromJson(data);
      throw Exception('Unexpected response format: ${res.body}');
    }

    if (res.statusCode == 422) {
      final decoded = jsonDecode(res.body);
      throw Exception(jsonEncode({'status': 422, 'errors': decoded['errors'] ?? decoded}));
    }
    throw Exception('createPromotion failed: ${res.statusCode} ${res.body}');

  }

  Future<PromotionModel> updatePromotion(int id, PromotionModel promotion) async {
    final uri = Uri.parse('$baseUrl/shop/promotions/$id'); // match your API URL structure
    final headers = await _defaultHeaders();
    // ensure content type
    headers['Content-Type'] = 'application/json';

    final body = jsonEncode(promotion.toJson());

    final res = await http.put(uri, headers: headers, body: body);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = jsonDecode(res.body);

      // If Laravel returns { "data": { ... } }
      if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
        return PromotionModel.fromJson(decoded['data']);
      }

      // Or if backend returns the object directly
      if (decoded is Map<String, dynamic>) {
        return PromotionModel.fromJson(decoded);
      }

      throw Exception('Unexpected response format: ${res.body}');
    }

    if (res.statusCode == 404) {
      throw Exception('Promotion not found: $id');
    }

    // forward server error + body for debugging
    throw Exception('updatePromotion failed: ${res.statusCode} ${res.body}');
  }

  Future<void> deletePromotion(int id) async {
    final uri = Uri.parse('$baseUrl/shop/promotions/$id');
    final headers = await _defaultHeaders();
    final res = await http.delete(uri, headers: headers);

    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }

    if (res.statusCode == 404) {
      throw Exception('Promotion not found: $id');
    }

    throw Exception('deletePromotion failed: ${res.statusCode} ${res.body}');
  }



  // -------------------------------------------------------------
  // DEFAULT HEADERS
  // -------------------------------------------------------------
  Future<Map<String, String>> _defaultHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

}
