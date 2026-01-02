// lib/core/utils/auth_utils.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user.dart';
import '../../screen/shops/screens/shops_home_page.dart';
import '../../screen/user/layout.dart';
import '../../server/user_service.dart';
import '../../screen/auth/login_screen.dart';

class AuthUtils {
  /// Check token, fetch user, or navigate to login if invalid.
  static Future<User?> checkAuthAndGetUser({
    required BuildContext context,
    required int userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      _goToLogin(context);
      return null;
    }

    final userModel = await UserService.getUserById(userId, token: token);
    if (userModel?.user == null) {
      _goToLogin(context);
      return null;
    }

    return userModel!.user;
  }

  static void _goToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
  /// Navigate to the correct layout based on user role.
  ///
  static Future<void> navigateByRole(BuildContext context, dynamic user) async {
    final prefs = await SharedPreferences.getInstance();

    // Save user info for later
    await prefs.setString('user_name', user.name ?? '');
    await prefs.setString('role', user.role ?? 'customer');
    if (user.id != null) await prefs.setInt('user_id', user.id!);
    // Navigate by role
    final userIdString = user.id?.toString() ?? '';

    if (user.role == 'owner') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ShopsHomePage(userId: userIdString),
        ),
            (route) => false, // remove all previous routes
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => Layout(userId: user.id!),
        ),
            (route) => false, // remove all previous routes
      );
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (_) => const PushTestPage()),
      // );

    }

  }

}
