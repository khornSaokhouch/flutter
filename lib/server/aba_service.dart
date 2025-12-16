import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_endpoints.dart';


class ABAPaymentService {
  static Future<Map<String, dynamic>> createKHQR({
    required int amount,
    required int orderId,
    required String currency, // KHR or USD
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/aba/aof/request'),
      headers: ApiConfig.headers,
      body: jsonEncode({
        'user_id': orderId,
        'amount': amount,
        'currency': currency,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.body}');
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> generateQR({
    required int orderId,
    required double amount,
    required String currency, // USD or KHR
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/aba/qr/generate'),
      headers: ApiConfig.headers,
      body: jsonEncode({
        'order_id': orderId.toString(),
        'amount': amount,
        'currency': currency,
      }),
    );

    if (response.statusCode != 200) {
      print(response.body);
      throw Exception('Server error: ${response.body}');
    }
    print(response.body);
    return jsonDecode(response.body);


  }

}
