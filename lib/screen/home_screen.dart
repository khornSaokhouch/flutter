import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login/login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const HomeScreen({super.key, required this.userId, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String userName;

  @override
  void initState() {
    super.initState();
    userName = widget.userName;
    _saveUserName();
  }

  /// 🔹 Save user name in SharedPreferences
  Future<void> _saveUserName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', userName);
  }

  /// 🔹 Logout user
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    try {
      final baseUrl = dotenv.env['API_URL'] ?? 'http://10.1.87.110:8000/api';
      final response = await http.post(
        Uri.parse('$baseUrl/firebase-logout'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await prefs.remove('jwt_token');
        await prefs.remove('user_name');
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } else {
        print('Firebase logout failed: ${response.body}');
      }
    } catch (e) {
      print('Error during Firebase logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $userName!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Hello, $userName! You are logged in.',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
