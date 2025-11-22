import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/routes/fot_nav_routes.dart';
import 'package:frontend/screen/account/account_page.dart';

// Import your screens
import 'package:frontend/screen/auth/login_screen.dart';
import 'package:frontend/core/utils/splash_screen.dart';
import 'package:frontend/screen/user/scan_pay_screen.dart';

// Import your route constants
import 'package:frontend/routes/footer_nav_routes.dart';
import 'package:frontend/screen/user/store_screen/menu_Items_list_screen.dart';
import 'package:frontend/screen/user/store_screen/menu_items_list_screen.dart' hide MenuScreen;

import 'core/widgets/home_app_bar.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    throw Exception('Error loading .env file: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // First screen to show
      home: const SplashScreen(),


      // Define routes for navigation
      // routes: {
      //   FooterNavRoutes.home: (context) => HomeScreen(
      //     userId: ModalRoute.of(context)!.settings.arguments as int,
      //   ),
      //   FooterNavRoutes.menu: (context) => MenuScreen(
      //     userId: ModalRoute.of(context)!.settings.arguments as int, shopId:  ,
      //   ),
      //   FooterNavRoutes.scanPay: (context) => ScanPayScreen(
      //     userId: ModalRoute.of(context)!.settings.arguments as int,
      //   ),
      //   // FooterNavRoutes.history: (context) => HistoryScreen(
      //   //   userId: ModalRoute.of(context)!.settings.arguments as int,
      //   // ),
      //   FooterNavRoutes.account: (context) => AccountPage(
      //     userId: ModalRoute.of(context)!.settings.arguments as int,
      //   ),
      // },
    );
  }
}

