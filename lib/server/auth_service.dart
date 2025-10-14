import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

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
  prefs.setString('token', data['token']);
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



  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: {'email': email, 'password': password},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', data['token']);
      return true;
    }
    return false;
  }
}
