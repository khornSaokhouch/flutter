import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await _notifications.initialize(settings);
  }

  static Future<void> showPaymentSuccess() async {
    await _notifications.show(
      0,
      'Payment Successful',
      'Your ABA payment was successful',
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          'payment_channel',
          'Payments',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
