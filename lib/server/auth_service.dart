import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  // static const String baseUrl = 'http://192.168.18.83:8000/api'; // Replace with your server IP
  static  String baseUrl = dotenv.env['API_URL'] ?? 'default_url';
  // final String apiKey = dotenv.env['API_KEY'] ?? 'default_key';

  // 🔹 Register user
  static Future<bool> register(
      String name, String email, String password, String passwordConfirmation) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
        }
        return true;
      } else {
        print('Register failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during register: $e');
      return false;
    }
  }

  // 🔹 Login user
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        return true;
      } else {
        print('Login failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during login: $e');
      return false;
    }
  }

  // 🔹 Send Firebase token to Laravel backend
  static Future<bool> firebaseLogin(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/firebase-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );
      print(response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        return true;
      } else {
        print('Firebase login failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during Firebase login: $e');
      return false;
    }
  }
}
