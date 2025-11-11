import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/screen/user/layout.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/utils/message_utils.dart';
import '../../core/utils/utils.dart';
import '../../server/auth_service.dart';

import 'auth/VerifyPhonePage.dart';
import 'auth/sign_up_screen.dart';


class LoginBottomSheet extends StatefulWidget {
  const LoginBottomSheet({super.key, });

  @override
  State<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------- Email Login ----------------
  Future<void> _signInWithEmail(String login, String password) async {
    if (login.isEmpty || password.isEmpty) {
      showMessage(context, 'Enter email/phone and password', color: Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final loginInput = login.contains('@')
          ? login.trim()            // It's an email, don't format
          : formatPhoneNumber(login.trim()); // It's a phone number, format it
      final userModel = await AuthService.login(loginInput, password.trim());

      if (userModel?.user != null) {
        final user = userModel!.user!;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', user.name ?? '');

        if (mounted) {
          Navigator.pop(context); // Close bottom sheet
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


  // ---------------- Google Login ----------------
  Future<void> _signInWithGoogle() async {
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
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Layout(userId: userModel.user!.id!)),
            );
          }
        } else if (mounted) {
          showMessage(context, 'Google Sign-In failed: No user model returned.', color: Colors.red);
        }
      }
    } catch (e) {
      showMessage(context, 'Google Sign-In failed: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------- Apple Login ----------------
  Future<void> _signInWithApple() async {
    if (!(Platform.isIOS || Platform.isMacOS)) {
      showMessage(context, 'Apple Sign-In is only available on iOS/macOS', color: Colors.orange);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final oAuthProvider = OAuthProvider("apple.com");
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        final userModel = await AuthService.firebaseLogin(idToken);
        final user = userModel?.user;
        if (user != null && mounted) {
          final prefs = await SharedPreferences.getInstance();
          if (userModel?.token != null) await prefs.setString('token', userModel!.token!);

          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => Layout(userId: user.id!)),
          );
        } else if (mounted) {
          showMessage(context, 'Apple Sign-In failed: No user model returned.', color: Colors.red);
        }
      }
    } catch (e) {
      showMessage(context, 'Apple Sign-In failed: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------- Social Button Widget ----------------
  Widget _socialButton(String iconPath, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(iconPath, height: 28, width: 28),
        ),
      ),
    );
  }

  // ---------------- Build ----------------
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 25,
        left: 25,
        right: 25,
        bottom: MediaQuery.of(context).viewInsets.bottom + 25,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Welcome Back',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text(
                  'Sign in to continue',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 25),

                // Email Field
                _buildTextField(
                  controller: _emailController,
                  hint: 'Email or Phone',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 15),

                // Password Field
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 25),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                      _signInWithEmail(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCC00),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black87)
                        : const Text(
                      'LOG IN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                ),
                const SizedBox(height: 15),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => showMessage(
                        context, 'Forgot Password functionality not yet implemented.',
                        color: Colors.blue),
                    child: const Text('Forgot Password?',
                        style: TextStyle(color: Color(0xFFFFCC00))),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Or', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 15),

                // Social Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (Platform.isIOS || Platform.isMacOS)
                      _socialButton('assets/images/apple_logo.png', _isLoading ? () {} : _signInWithApple),
                    if (Platform.isIOS || Platform.isMacOS) const SizedBox(width: 20),
                    _socialButton('assets/images/google_logo.png', _isLoading ? () {} : _signInWithGoogle),
                  ],
                ),
                const SizedBox(height: 25),

                // Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don’t have an account? ', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                      child: const Text('Sign Up',
                          style: TextStyle(fontSize: 14, color: Color(0xFFFFCC00), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
          // Full-screen loader
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- TextField Builder ----------------
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ---------------- Show Bottom Sheet ----------------
void showLoginBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) => const LoginBottomSheet(),
  );
}
