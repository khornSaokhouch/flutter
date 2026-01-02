import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_endpoints.dart';
import '../models/aba_qr_response.dart';

class AbaAofService {
  static Future<Map<String, dynamic>> requestAofQr() async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/aba/aof/request-qr',
    );

    final response = await http.post(
      url,
      headers: ApiConfig.headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to request ABA AOF QR: ${response.statusCode} ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<AbaQrResponse> generateQr({
    required double amount,
    int? orderId,
    int? userId,
    String currency = 'USD',
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/aba/qr'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Add Authorization header if needed
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },

      body: jsonEncode({
        'amount': amount,
        'order_id': orderId,
        'user_id':userId,
        'currency': currency,
      }),
    );


    if (response.statusCode != 200) {
      throw Exception('Failed to generate ABA QR');
    }

    return AbaQrResponse.fromJson(jsonDecode(response.body));
  }

  // ---------------------------
  // Check Payment Status
  // ---------------------------
  static Future<String> checkPaymentStatus({
    required String tranId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/payments/aba/status')
        .replace(queryParameters: {
      'tran_id': tranId,
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to check status');
    }

    final data = jsonDecode(response.body);
    return data['status']; // initiated | pending | paid | failed
  }
}
