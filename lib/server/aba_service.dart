import 'dart:convert';
import 'package:http/http.dart' as http;

class AbaService {
  static const String baseUrl = "https://yourdomain.com/api";

  static Future<Map<String, dynamic>> requestAof() async {
    final response = await http.post(
      Uri.parse("$baseUrl/aba/aof/request"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "user_id": "USER_123"
      }),
    );

    return jsonDecode(response.body);
  }
}
