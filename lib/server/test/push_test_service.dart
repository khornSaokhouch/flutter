import 'package:http/http.dart' as http;

import '../../config/api_endpoints.dart';


class PushTestService {
  static Future<void> sendTestPush() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/push/test');

    final response = await http.post(
      url,
      headers: ApiConfig.headers,
    );

    if (response.statusCode == 200) {

    } else {
    }
  }

  static Future<void> sendPaymentPush(int orderId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/test/payment-push/$orderId');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        // 'Authorization': 'Bearer YOUR_TOKEN', // if protected
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Push test failed: ${response.body}');
    }
  }
}
