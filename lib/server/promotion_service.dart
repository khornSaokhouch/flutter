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

  // -------------------------------------------------------------
  // CREATE PROMOTION → returns PromotionModel
  // -------------------------------------------------------------
  Future<PromotionModel> createPromotion(
      Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/shops/promotions');

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final res =
    await http.post(uri, headers: headers, body: jsonEncode(payload));

    if (res.statusCode == 201 || res.statusCode == 200) {
      final decoded = jsonDecode(res.body);

      final data = decoded['data'] ?? decoded;

      return PromotionModel.fromJson(data);
    }

    if (res.statusCode == 422) {
      final decoded = jsonDecode(res.body);
      throw Exception(jsonEncode({
        'status': 422,
        'errors': decoded['errors'] ?? decoded,
      }));
    }

    throw Exception(
      'createPromotion failed: ${res.statusCode} ${res.body}',
    );
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
