import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_endpoints.dart';
import '../models/user.dart';


class AuthService {
  // 🔹 Register user
  static Future<UserModel?> register(
      String name, String phone, String password, String passwordConfirmation) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/register-by-phone'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Save token if available
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
        }

        // Return parsed user model
        return UserModel.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // 🔹 Login user
  static Future<UserModel?> login(String login, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login'),
        headers: ApiConfig.headers,
        body: jsonEncode({'login': login, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();

        if (data['token'] != null) {
          await prefs.setString('token', data['token']);
        }

        return UserModel.fromJson(data);
      } else {
        if (kDebugMode) {
          print('❌ Login failed: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      return null;
    }
  }


  // 🔹 Firebase login (Google/Apple sign-in)
  static Future<UserModel?> firebaseLogin(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/firebase-login'),
        headers: ApiConfig.headers,
        body: jsonEncode({'id_token': idToken}),
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();

        if (data['token'] != null) await prefs.setString('token', data['token']);
        if (data['needs_phone'] == true && data['tempToken'] != null) {
          await prefs.setString('tempToken', data['tempToken']);
        }

        return UserModel.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }



  // 🔹 Get current user from /me
  static Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserModel.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // 🔹 Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  /// Register or login user using Firebase ID token
  static Future<UserModel?> registerWithFirebase({
    required String name,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String idToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/sign-up-by-phone'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'id_token': idToken,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Save token to SharedPreferences
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
        }

        return UserModel.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<UserModel?> appleLogin(String idToken, {String? phone}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/firebase/apple-login'),
        headers: ApiConfig.headers,
        body: jsonEncode({'token': idToken, 'phone': phone}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();

        if (data['token'] != null) await prefs.setString('token', data['token']);
        return UserModel.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }



}
