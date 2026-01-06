import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/auth_utils.dart';
import '../../core/utils/message_utils.dart';
import '../../core/utils/utils.dart';
import '../../core/widgets/loader_widgets.dart';
import '../../server/auth_service.dart';
import '../user/layout.dart';
//import 'VerifyPhonePage.dart';
import 'sign_up_screen.dart';

class LoginBottomSheet extends StatefulWidget {
  const LoginBottomSheet({super.key});

  @override
  State<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
        await prefs.setString('role', user.role ?? 'customer');
        // ✅ Save the remember_token
        if (userModel.rememberToken != null) {
          await prefs.setString('remember_token', userModel.rememberToken!);
        }
        if (mounted) {
          AuthUtils.navigateByRole(context, user); // 👈 from utils
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
      final googleSignIn = Platform.isIOS || Platform.isMacOS
          ? GoogleSignIn(
        clientId: '1043515983877-7ai2eljhepol58vkep9hgi5gb2244cfb.apps.googleusercontent.com',
        scopes: ['email'],
      )
          : GoogleSignIn(scopes: ['email']);

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        showMessage(context, 'Google Sign-In cancelled.', color: Colors.orange);
        return;
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        showMessage(
          context,
          'No idToken from Google (check iOS clientId / Firebase config).',
          color: Colors.red,
        );
        return;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        showMessage(context, 'Could not get Firebase ID token.', color: Colors.red);
        return;
      }

      final userModel = await AuthService.firebaseLogin(idToken);

      if (userModel != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => Layout(userId: userModel.user!.id!),
            ),
          );
        }
       else {
        showMessage(context, 'Backend Google login failed.', color: Colors.red);
      }
    } catch (e) {
      showMessage(context, 'Google Sign-In failed: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  // 🔹 Apple login (iOS/macOS only)
  Future<void> signInWithApple() async {
    // Only iOS/macOS
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
          clientId: 'com.kheangsenghorng.frontend.service', // Apple Services ID
          redirectUri: Uri.parse(
            'https://drinking-coffee-8eb88.firebaseapp.com/__/auth/handler',
          ),
        ),
      );

      // 🔹 Create Firebase credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // 🔹 Sign in with Firebase
      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      // 🔹 Get ID token for backend
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) throw Exception("Failed to get Firebase ID token");

      // 🔹 Ask user for phone number if needed


      // 🔹 Call backend to complete login
      final userModel = await AuthService.appleLogin(idToken);
      var user = userModel?.user;

      if (user != null && mounted) {
        final prefs = await SharedPreferences.getInstance();

        // 🔹 Ensure role is set even if backend does not return it
        final role = user.role ?? 'user';
        await prefs.setString('role', role);

        // 🔹 Save JWT token and remember_token if available
        if (userModel?.token != null) await prefs.setString('token', userModel!.token!);
        if (userModel?.rememberToken != null) {
          await prefs.setString('remember_token', userModel!.rememberToken!);
        }

        // 🔹 Update user object with default role if missing

        // 🔹 Navigate based on role
        AuthUtils.navigateByRole(context, user);

        showMessage(context, 'Apple login successful!', color: Colors.green);
      } else if (mounted) {
        showMessage(context, 'Apple login failed.', color: Colors.red);
      }
    } catch (e) {
      if (mounted) showMessage(context, 'Apple Sign-In failed', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }




  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);

  // 🔹 Social button helper
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
                color: Colors.black.withValues(alpha: 0.05),
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
                // Logo & heading
                Column(
                  children: [
                    Image.asset(
                      'assets/images/coffee.png',
                      height: 100,
                      errorBuilder: (_, __, ___) => Icon(Icons.coffee,
                          size: 100, color: _espressoBrown),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Sign In",
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "It’s coffee time! Login and let’s get all the coffee in the world!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Login form
                _buildTextField(
                  controller: _emailController,
                  hint: 'Email or Phone Number',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  isLast: true,
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
                const SizedBox(height: 12),
                // Keep me logged in & forgot password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _keepMeLoggedIn,
                          onChanged: (val) =>
                              setState(() => _keepMeLoggedIn = val!),
                          activeColor: _freshMintGreen,
                        ),
                        const Text("Keep me logged in",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text("Forgot password?",
                          style: TextStyle(
                              color: _freshMintGreen,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _freshMintGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: signInWithEmail,
                    child: const Text("LOGIN",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 24),
                // Create new account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: _freshMintGreen,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 5),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const SignUpScreen(),
                        );
                      },
                      child: Text(
                        "Create new account",
                        style: TextStyle(
                          fontSize: 15,
                          color: _espressoBrown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                        child: Divider(color: Colors.grey[200], thickness: 1)),
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
                        child: Divider(color: Colors.grey[200], thickness: 1)),
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
              ],
            ),
          ),
          // Loading indicator
          buildFullScreenLoader(_isLoading, indicatorColor: _freshMintGreen), // ← now works!
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
}
