import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_endpoints.dart';
import '../models/payment_model.dart'; // contains ApiConfig

class StripeService {
  // ===== GET TOKEN FROM PREFS =====
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // Helper to build headers (ensures JSON headers)
  static Future<Map<String, String>> _buildHeaders() async {
    final token = await _getToken();
    final baseHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // add other default headers from ApiConfig if needed
    };

    if (token != null && token.isNotEmpty) {
      // adjust according to your backend auth scheme
      baseHeaders.addAll({'Authorization': 'Bearer $token'});
    } else {
      // if ApiConfig.headers contains more defaults, merge them here
      baseHeaders.addAll(ApiConfig.headers);
    }

    return baseHeaders;
  }

  // ---------------- CREATE PAYMENT INTENT ----------------
  static Future<Map<String, dynamic>> createPaymentIntent({
    required int amount,
    required String currency,
   int? userId,
   int? orderId,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/stripe/payment-intent");
    final headers = await _buildHeaders();
    final body = jsonEncode({
      "amount_cents": amount,
      "currency": currency,
      "userid": userId,
      "orderid": orderId,
    });

    final client = http.Client();
    try {
      // Use a low-level Request so we can inspect redirect responses.
      final request = http.Request('POST', url)
        ..headers.addAll(headers)
        ..body = body;

      // Do NOT automatically follow redirects: let us inspect them.
      final streamed = await client.send(request); // follows redirects by default
      final resp = await http.Response.fromStream(streamed);

      // Debug: full response for troubleshooting (remove in prod)
      // print('StripeService.createPaymentIntent -> status: ${resp.statusCode}, body: ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }

      // Special handling for redirects (302/301)
      if (resp.statusCode == 302 || resp.statusCode == 301) {
        // Try to read Location header from the streamed response object
        final location = streamed.headers['location'] ?? streamed.headers['Location'];
        throw Exception('Server returned redirect (${resp.statusCode}) to ${location ?? 'unknown'}. Response body: ${resp.body}');
      }

      // If the server returns HTML or other non-json, include it in the error message
      String responsePreview = resp.body;
      if (responsePreview.length > 1000) {
        responsePreview = responsePreview.substring(0, 1000) + '...';
      }

      throw Exception('Failed to create payment intent: ${resp.statusCode} - $responsePreview');
    } finally {
      client.close();
    }
  }

  // ---------------- CREATE CHECKOUT SESSION ----------------
  static Future<Map<String, dynamic>> createCheckoutSession({
    required int amount,
    required String currency,
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/users/stripe/checkout-session");
    final headers = await _buildHeaders();
    final body = jsonEncode({"amount": amount, "currency": currency});

    final client = http.Client();
    try {
      final request = http.Request('POST', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamed = await client.send(request);
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }

      if (resp.statusCode == 302 || resp.statusCode == 301) {
        final location = streamed.headers['location'] ?? streamed.headers['Location'];
        throw Exception('Server returned redirect (${resp.statusCode}) to ${location ?? 'unknown'}. Response body: ${resp.body}');
      }

      throw Exception('Failed to create checkout session: ${resp.statusCode} - ${resp.body}');
    } finally {
      client.close();
    }
  }

  static Future<List<PaymentModel>> getPaymentsByUser(int userId) async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/users/payments/user/$userId",
    );

    final headers = await _buildHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to load payments');
    }

    final decoded = jsonDecode(response.body);
    final List list = decoded['data'];

    return list.map((e) => PaymentModel.fromJson(e)).toList();
  }

// ---------------- STRIPE WEBHOOK (Server Only) ----------------
// Flutter NEVER calls webhook.
}
