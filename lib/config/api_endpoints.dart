import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Load base URL from your .env file
  static final String baseUrl = dotenv.env['API_URL'] ?? 'http://10.1.87.110:8000/api';

  // Common headers for requests
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
  };

  // Auth header with token (for authenticated requests)
  static Future<Map<String, String>> authHeaders(String token) async {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
