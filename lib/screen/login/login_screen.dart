import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:frontend/screen/home_screen.dart';
import 'package:frontend/screen/register_screen.dart';
import '../../server/auth_service.dart';
import '../user/layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  // Email Login
  Future<void> signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userModel = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (userModel != null && userModel.user != null) {
        // ✅ Print user info
        print('✅ Email login successful!');
        print('Name: ${userModel.user!.name}');
        print('Email: ${userModel.user!.email}');
        print('ID: ${userModel.user!.id}');

        // Navigate to HomeScreen
        if (userModel != null && userModel.user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', userModel.user!.name ?? '');

          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(builder: (_) => const HomeScreen()),
          // );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Check credentials.')),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Email login failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  // Google Login
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

        if (userModel != null && userModel.user != null) {
          final user = userModel.user!;
          print('Name: ${user.name}');
          print('Email: ${user.email}');
          print('ID: ${user.id}');

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => Layout(
                // userId: user.id!,
                // userName: user.name ?? 'Guest',
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  // Apple Login
  Future<void> signInWithApple() async {
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
        final user = await AuthService.firebaseLogin(idToken);
        if (user !=null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(userId: user.user!.id! , userName: '',)),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple Sign-In failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
                // ☕️ Top Icon
                Center(
                  child: Column(
                    children: [
                      Image.asset('assets/images/coffee.png', height: 100),
                      const SizedBox(height: 16),
                      const Text(
                        "Sign in",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff4a2c2a),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "It’s coffee time! Login and let’s get all the coffee in the world!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xff6f4e37),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Username",
                          style: TextStyle(
                              color: Color(0xff2a8a6f),
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Enter your email or phone number',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) =>
                        v == null || v.isEmpty ? 'Enter your email' : null,
                      ),
                      const SizedBox(height: 20),
                      const Text("Password",
                          style: TextStyle(
                              color: Color(0xff2a8a6f),
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _obscureText = !_obscureText),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) =>
                        v == null || v.isEmpty ? 'Enter your password' : null,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Checkbox(value: true, onChanged: (_) {}),
                          const Text("Keep me logged in"),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff4a2c2a),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: signInWithEmail,
                          child: const Text(
                            "LOGIN",
                            style: TextStyle(
                                fontSize: 16, color: Colors.white, letterSpacing: 1.2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text("Forgot password?",
                              style: TextStyle(color: Color(0xff2a8a6f))),
                          SizedBox(width: 4),
                          Text("Reset here",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff4a2c2a))),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Create Account Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xff4a2c2a)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignUpScreen()),
                            );
                          },
                          child: const Text(
                            "CREATE NEW ACCOUNT",
                            style: TextStyle(color: Color(0xff4a2c2a)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // OR Divider
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

                      // Google Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: Image.asset('assets/images/google.png', height: 24),
                          label: const Text("Sign in with Google"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Colors.grey),
                            ),
                          ),
                          onPressed: signInWithGoogle,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Apple Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.apple, size: 24, color: Colors.white),
                          label: const Text("Sign in with Apple"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: signInWithApple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
