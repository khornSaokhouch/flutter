import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../config/api_endpoints.dart';

class PushService {
  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  /// ✅ Call AFTER login (when you have accessToken + userId)
  static Future<void> init({
    required String accessToken,
    required int userId,
  }) async {
    // 🔔 Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 📱 Get FCM token
    final fcmToken = await _messaging.getToken();
    if (fcmToken != null) {
      await _sendTokenToServer(
        fcmToken: fcmToken,
        accessToken: accessToken,
        userId: userId,
      );
    }

    // 🔁 Token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _sendTokenToServer(
        fcmToken: newToken,
        accessToken: accessToken,
        userId: userId,
      );
    });

    // 📩 Foreground notification
    FirebaseMessaging.onMessage.listen((message) {
    });

    // 📲 App opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  static Future<void> _sendTokenToServer({
    required String fcmToken,
    required String accessToken,
    required int userId,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/push/register');

    final response = await http.post(
      url,
      headers: await ApiConfig.authHeaders(accessToken),
      body: jsonEncode({
        'user_id': userId,
        'device_token': fcmToken,
        'platform': Platform.isIOS ? 'ios' : 'android',
      }),
    );

    if (response.statusCode != 200) {
    } else {
    }
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;

    if (data['type'] == 'payment') {

      // navigatorKey.currentState
      //     ?.pushNamed('/orders/$orderId');
    }
  }
}
