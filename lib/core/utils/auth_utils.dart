// lib/core/utils/auth_utils.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user.dart';
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
}
