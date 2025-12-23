import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:frontend/server/local_notification_service.dart';

import 'firebase_options.dart';
import 'core/utils/splash_screen.dart';

/// 🌍 Global navigator key (used by push notification tap)
final GlobalKey<NavigatorState> navigatorKey =
GlobalKey<NavigatorState>();

/// 🔔 Background push handler (REQUIRED)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔔 Register background handler
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  await LocalNotificationService.init();
  setupTestPushListeners();

  // 🌱 Load env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    throw Exception('Error loading .env file: $e');
  }

  // 💳 Stripe
  Stripe.publishableKey =
  dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
  Stripe.merchantIdentifier =
  dotenv.env['STRIPE_MERCHANT_ID']!;
  await Stripe.instance.applySettings();

  runApp(const MyApp());
}

void setupTestPushListeners() {
  /// 🔔 FOREGROUND
  FirebaseMessaging.onMessage.listen((message) {
    debugPrint('🔔 Foreground push: ${message.notification?.title}');
  });

  /// 📲 TAP NOTIFICATION
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    debugPrint('📲 Notification tapped: ${message.data}');
  });
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ REQUIRED FOR PUSH NAVIGATION
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        primaryColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.white,
          secondary: Colors.black,
        ),
      ),

      home: const SplashScreen(),
    );
  }
}
