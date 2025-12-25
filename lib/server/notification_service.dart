// lib/server/notification_service.dart
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

typedef NotificationCallback = void Function(String title, String body);

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();

  factory NotificationService() => _instance;
  NotificationService._internal();

  StreamSubscription<RemoteMessage>? _sub;
  NotificationCallback? _callback;

  void init({required NotificationCallback onMessage}) {
    _callback = onMessage;

    _sub ??= FirebaseMessaging.onMessage.listen((message) {   
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? '';
      _callback?.call(title, body);
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
