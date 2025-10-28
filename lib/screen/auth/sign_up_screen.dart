import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io' show Platform;

import '../user/layout.dart';
import 'login_screen.dart';
import 'verifyPhoneNumber.dart';
import '../../../server/auth_service.dart';
import '../../core/utils/utils.dart';

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
  String? _verificationId;

  // 🔹 Send OTP
  Future<void> sendOtp(String phoneNumber) async {
    setState(() => _isLoading = true);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: formatPhoneNumber(phoneNumber),
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Verification failed: ${e.message}')));
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('✅ OTP sent successfully')));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PhoneAuthPage(
                phoneNumber: phoneNumber,
                verificationId: verificationId,
                name: usernameCtrl.text,
                password: passwordCtrl.text,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error sending OTP: $e')));
    }
  }

  // 🔹 Google Sign-In
  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        final userModel = await AuthService.firebaseLogin(idToken);

        if (userModel != null && userModel.user != null) {
          final user = userModel.user!;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Google Sign-Up Successful")),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => Layout(userId: user.id!), // ✅ pass user ID safely
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User data not found after login.")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Google Sign-In failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔹 Apple Sign-In
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

      if (idToken != null) {
        await AuthService.firebaseLogin(idToken);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Apple Sign-Up Successful")));
        }
      }
    } catch (e) {
      debugPrint("⚠️ Apple Sign-In error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Apple Sign-In failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/coffee.png',
                        height: 100,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.coffee, size: 100, color: Color(0xff4a2c2a)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff4a2c2a),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Join our coffee community today!",
                        style: TextStyle(color: Color(0xff6f4e37)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 🔹 Form section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildInput("Username", usernameCtrl, "Enter username"),
                      const SizedBox(height: 16),
                      buildInput("Phone number", phoneCtrl, "Enter phone number",
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      buildPassword("Password", passwordCtrl, _obscurePassword, () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      }),
                      const SizedBox(height: 16),
                      buildPassword("Confirm Password", confirmPasswordCtrl,
                          _obscureConfirmPassword, () {
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                          }),
                      const SizedBox(height: 20),

                      // 🔹 Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff5d4037),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                          onPressed: () {
                            final username = usernameCtrl.text.trim();
                            final phone = phoneCtrl.text.trim();
                            final password = passwordCtrl.text.trim();
                            final confirmPassword = confirmPasswordCtrl.text.trim();

                            if (username.isEmpty ||
                                phone.isEmpty ||
                                password.isEmpty ||
                                confirmPassword.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please fill all fields")));
                              return;
                            }

                            if (!doPasswordsMatch(password, confirmPassword)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Passwords do not match")));
                              return;
                            }

                            if (!isPasswordValid(password)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text(
                                      "Password must be at least 8 characters with uppercase, lowercase, number & symbol")));
                              return;
                            }

                            sendOtp(phone);
                          },
                          child: const Text(
                            "REGISTER",
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      Row(
                        children: const [
                          Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text("OR"),
                          ),
                          Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 🔹 Google Button
                      socialButton(
                        iconWidget: Image.asset(
                          'assets/images/google.png',
                          height: 24,
                          errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.red),
                        ),
                        label: "Sign up with Google",
                        backgroundColor: Colors.white,
                        textColor: Colors.black87,
                        onPressed: signInWithGoogle,
                      ),

                      const SizedBox(height: 12),

                      // 🔹 Apple Button (only on iOS/macOS)
                      if (Platform.isIOS || Platform.isMacOS)
                        socialButton(
                          iconWidget: Image.asset(
                            'assets/images/apple.png',
                            height: 24,
                            errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.red),
                          ),
                          label: "Sign up with Apple",
                          backgroundColor: Colors.black,
                          textColor: Colors.white,
                          onPressed: signInWithApple,
                        ),

                      const SizedBox(height: 20),

                      // 🔹 Already have account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account?",
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                              );
                            },
                            child: const Text(
                              "Sign In",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xff9e7e6b),
                              ),
                            ),
                          ),
                        ],
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
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // 🔹 Helpers
  Widget buildInput(String label, TextEditingController controller, String hint,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            const TextStyle(color: Color(0xff6f4e37), fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget buildPassword(String label, TextEditingController controller,
      bool obscure, VoidCallback toggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            const TextStyle(color: Color(0xff6f4e37), fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: "••••••••",
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey),
              onPressed: toggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  // 🔹 Social Button Widget
  Widget socialButton({
    Widget? iconWidget,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        icon: iconWidget ?? const SizedBox.shrink(),
        label: Text(
          label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
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
}
