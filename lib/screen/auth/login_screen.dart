import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/message_utils.dart';
import '../../core/utils/utils.dart';
import '../../server/auth_service.dart';
import '../user/layout.dart';
import 'VerifyPhonePage.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _keepMeLoggedIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🔹 Email login
  Future<void> signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showMessage(context, 'Enter email/phone and password', color: Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final loginInput = formatPhoneNumber(_emailController.text.trim());
      final userModel = await AuthService.login(loginInput, _passwordController.text.trim());

      if (userModel?.user != null) {
        final user = userModel!.user!;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', user.name ?? '');

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => Layout(userId: user.id!)),
          );
        }
        showMessage(context, 'Login successful!', color: Colors.green);
      } else {
        showMessage(context, 'Invalid credentials.', color: Colors.red);
      }
    } catch (e) {
      showMessage(context, 'Error: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔹 Google login
  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        final userModel = await AuthService.firebaseLogin(idToken);

        if (userModel != null && mounted) {
          if (userModel.needsPhone == true && userModel.tempToken != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => VerifyPhonePage(tempToken: userModel.tempToken!)),
            );
          } else {
            final prefs = await SharedPreferences.getInstance();
            if (userModel.token != null) await prefs.setString('token', userModel.token!);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Layout(userId: userModel.user!.id!)),
            );
          }
        }
      }
    } catch (e) {
      showMessage(context, 'Google Sign-In failed: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔹 Apple login (iOS/macOS only)
  Future<void> signInWithApple() async {
    if (!(Platform.isIOS || Platform.isMacOS)) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // 🔹 Request Apple credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.kheangsenghorng.frontend.service', // Must match Apple Services ID
          redirectUri: Uri.parse(
            'https://drinking-coffee-8eb88.firebaseapp.com/__/auth/handler', // Must match Services ID Redirect URI
          ),
        ),
      );

      // 🔹 Create Firebase credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // 🔹 Sign in with Firebase
      final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      // 🔹 Get ID token for backend
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        throw Exception("Failed to get Firebase ID token");
      }

      // 🔹 Ask user for phone number
      final phoneNumber = await showDialog<String>(
        context: context,
        builder: (_) {
          String? tempPhone;
          return AlertDialog(
            title: const Text('Enter your phone number'),
            content: TextField(
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'Phone number'),
              onChanged: (value) => tempPhone = value,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, tempPhone),
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );

      // 🔹 Call backend to complete login
      final userModel = await AuthService.appleLogin(idToken, phone: phoneNumber);
      final user = userModel?.user;

      if (user != null && mounted) {
        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        if (userModel?.token != null) await prefs.setString('token', userModel!.token!);

        // Navigate to main layout
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Layout(userId: user.id!)),
        );
      } else if (mounted) {
        showMessage(context, 'Apple login failed.', color: Colors.red);
      }
    } catch (e) {
      if (mounted) showMessage(context, 'Apple Sign-In failed: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  // 🔹 Social button helper
  Widget socialButton({
    required Widget iconWidget,
    required String label,
    required VoidCallback onPressed,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black87,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        icon: iconWidget,
        label: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.grey),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f0e8),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            child: Column(
              children: [
                // Logo & heading
                Column(
                  children: [
                    Image.asset(
                      'assets/images/coffee.png',
                      height: 100,
                      errorBuilder: (_, __, ___) => const Icon(Icons.coffee, size: 100, color: Color(0xff4a2c2a)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Sign In",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xff4a2c2a)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "It’s coffee time! Login and let’s get all the coffee in the world!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xff6f4e37), fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Login form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      // Email/phone
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email or Phone',
                          prefixIcon: const Icon(Icons.person),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Password
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Keep me logged in
                      Row(
                        children: [
                          Checkbox(
                            value: _keepMeLoggedIn,
                            onChanged: (val) => setState(() => _keepMeLoggedIn = val!),
                            activeColor: const Color(0xff5d4037),
                          ),
                          const Text("Keep me logged in", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff5d4037),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          onPressed: signInWithEmail,
                          child: const Text("LOGIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {},
                        child: const Text("Forgot password?", style: TextStyle(color: Color(0xff9e7e6b), fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                        child: const Text("Create new account", style: TextStyle(fontSize: 16, color: Color(0xff5d4037), fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: const [
                          Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("OR")),
                          Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      socialButton(
                        iconWidget: Image.asset('assets/images/google.png', height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.red)),
                        label: "Sign in with Google",
                        onPressed: signInWithGoogle,
                      ),
                      const SizedBox(height: 12),
                      if (Platform.isIOS || Platform.isMacOS)
                        socialButton(
                          iconWidget: Image.asset('assets/images/apple.png', height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.red)),
                          label: "Sign in with Apple",
                          onPressed: signInWithApple,
                          backgroundColor: Colors.black,
                          textColor: Colors.white,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
