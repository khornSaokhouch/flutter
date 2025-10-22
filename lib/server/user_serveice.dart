import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserService {
  static final String baseUrl = dotenv.env['API_URL'] ?? 'http://192.168.110.6:8000/api';

  /// 🔹 Register user
  static Future<Map<String, dynamic>> register({
    required String name,
    String? email,
    String? phone,
    required String password,
    required String passwordConfirmation,
    String role = 'customer',
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users'));

      request.fields['name'] = name;
      if (email != null) request.fields['email'] = email;
      if (phone != null) request.fields['phone'] = phone;
      request.fields['password'] = password;
      request.fields['password_confirmation'] = passwordConfirmation;
      request.fields['role'] = role;

      // If you want to attach profile image, uncomment below
      // request.files.add(await http.MultipartFile.fromPath('profile_image', 'path_to_image'));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 🔹 Login user
  static Future<bool> login({required String email, required String password}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
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

  /// 🔹 Logout
  static Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/firebase-logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await prefs.remove('jwt_token');
        return true;
      } else {
        print('Logout failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during logout: $e');
      return false;
    }
  }

  /// 🔹 Get all users (admin)
  static Future<List<dynamic>?> getUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['users'];
      } else {
        print('Get users failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting users: $e');
      return null;
    }
  }

  /// 🔹 Update user
  static Future<Map<String, dynamic>> updateUser(
      int id, {
        String? name,
        String? email,
        String? phone,
        String? password,
        String? passwordConfirmation,
      }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return {'error': 'No token found'};

      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/$id?_method=PUT'));
      request.headers['Authorization'] = 'Bearer $token';

      if (name != null) request.fields['name'] = name;
      if (email != null) request.fields['email'] = email;
      if (phone != null) request.fields['phone'] = phone;
      if (password != null) request.fields['password'] = password;
      if (passwordConfirmation != null) request.fields['password_confirmation'] = passwordConfirmation;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return jsonDecode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 🔹 Delete user (admin)
  static Future<bool> deleteUser(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/users/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  /// 🔹 Get phone number by user ID
  static Future<String?> getPhoneNumber(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/phone/$id'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['phone'];
      } else {
        print('Get phone failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting phone: $e');
      return null;
    }
  }
}
