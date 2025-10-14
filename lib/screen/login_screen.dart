import 'package:flutter/material.dart';
import 'package:frontend/server/auth_service.dart';
import 'home_screen.dart';
import 'register_screen.dart'; // <-- Create this screen if you haven’t yet

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> _login() async {
    bool success = await AuthService.login(
      emailController.text,
      passwordController.text,
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Successful!")),
      );

      // Navigate to Home after short delay
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Failed!")),
      );
    }
  }

  void _loginWithGoogle() {
    // TODO: Implement Google Sign-In logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Google Login Coming Soon")),
    );
  }

  void _loginWithApple() {
    // TODO: Implement Apple Sign-In logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Apple Login Coming Soon")),
    );
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text("Login"),
            ),
            const SizedBox(height: 20),
            const Text("Or continue with"),
            const SizedBox(height: 10),

            // Google Login Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Colors.grey),
              ),
              onPressed: _loginWithGoogle,
              icon:Icon(Icons.arrow_back),
              label: const Text("Continue with Google"),
            ),

            const SizedBox(height: 10),

            // Apple Login Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _loginWithApple,
              icon: const Icon(Icons.apple),
              label: const Text("Continue with Apple"),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: _goToRegister,
              child: const Text("Don't have an account? Register here"),
            ),
          ],
        ),
      ),
    );
  }
}
