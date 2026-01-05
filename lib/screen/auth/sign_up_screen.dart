// lib/screens/auth/signup_screen.dart
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/utils/utils.dart';
import '../../models/user.dart';
import '../../server/auth_service.dart';

import '../user/layout.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final usernameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);

  // Create account (calls AuthService.register)
  Future<void> createAccount() async {
    final username = usernameCtrl.text.trim();
    final phone = formatPhoneNumber(phoneCtrl.text); // ✅ Add +855 here
    final password = passwordCtrl.text.trim();
    final confirmPassword = confirmPasswordCtrl.text.trim();

    if (username.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (!doPasswordsMatch(password, confirmPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    if (!isPasswordValid(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Password must be at least 8 characters with uppercase, lowercase, number & symbol",
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userModel = await AuthService.register(
        username,
        phone, // ✅ Already formatted with +855
        password,
        confirmPassword,
      );

      if (userModel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registration failed: no response from server')),
        );
        return;
      }

      if (userModel.user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sign up successful")),
          );
          _navigateToLayout(userModel);
        }
      } else {
        final msg =
            userModel.message ?? 'Registration succeeded but no user returned';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Google Sign-In (keeps existing behaviour, then call server)
  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // user canceled
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not retrieve idToken from Firebase')),
        );
        return;
      }

      // Call backend to exchange firebase idToken for your user+token (optional)
      try {
        final userModel = await AuthService.firebaseLogin(idToken);
        if (userModel != null && userModel.user != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Google Sign-In Successful")),
            );
            _navigateToLayout(userModel);
          }
        } else {
          // Backend didn't return a user - still allow app to continue or show message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text("Logged in with Google but server did not return user data.")),
          );
        }
      } on NoSuchMethodError {
        // AuthService.firebaseLogin is not implemented; proceed without backend exchange
        // You may want to create a user record on your backend; for now just show success.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Google Sign-In successful (no backend exchange).")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backend login failed: ${e.toString()}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Apple Sign-In
  Future<void> signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not retrieve idToken from Firebase')),
        );
        return;
      }

      try {
        final userModel = await AuthService.firebaseLogin(idToken);
        if (userModel != null && userModel.user != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Apple Sign-In Successful")));
            _navigateToLayout(userModel);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text("Logged in with Apple but server did not return user data.")),
          );
        }
      } on NoSuchMethodError {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Apple Sign-In successful (no backend exchange).")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backend login failed: ${e.toString()}')),
        );
      }
    } catch (e) {
      debugPrint("⚠️ Apple Sign-In error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple Sign-In failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Navigate to app layout; uses user.user!.id from backend model
  void _navigateToLayout(UserModel userModel) {
    if (!mounted) return;
    final idRaw = userModel.user?.id;
    if (idRaw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID missing in response')),
      );
      return;
    }

    // Support id as int or String
    final userId = idRaw;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => Layout(userId: userId)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 12,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Join our coffee community!',
                          style: TextStyle(
                            color: Color(0xff6f4e37),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 20, color: Colors.black54),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildTextField(
                  controller: usernameCtrl,
                  hint: 'Username',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: phoneCtrl,
                  hint: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: passwordCtrl,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey[500],
                      size: 22,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: confirmPasswordCtrl,
                  hint: 'Confirm Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  isLast: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey[500],
                      size: 22,
                    ),
                    onPressed: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : createAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _freshMintGreen, // Unit Green
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                        child:
                            Divider(color: Colors.grey[200], thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or continue with',
                        style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                        child:
                            Divider(color: Colors.grey[200], thickness: 1)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (Platform.isIOS || Platform.isMacOS) ...[
                      _socialButton('assets/images/apple_logo.png',
                          _isLoading ? () {} : signInWithApple),
                      const SizedBox(width: 24),
                    ],
                    _socialButton('assets/images/google_logo.png',
                        _isLoading ? () {} : signInWithGoogle),
                  ],
                ),
                const SizedBox(height: 30),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const LoginScreen(),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 15),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                              color: _espressoBrown,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<String>? autofillHints,
    bool isLast = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      autofillHints: autofillHints,
      cursorColor: _freshMintGreen,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[500], size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[50], // Very light grey bg
        contentPadding:
            const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _freshMintGreen, width: 1.5),
        ),
      ),
    );
  }

  Widget _socialButton(String iconPath, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(iconPath, height: 26, width: 26),
          ),
        ),
      ),
    );
  }
}
