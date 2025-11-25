  import 'dart:io' show Platform;
import 'dart:ui';
  import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:frontend/screen/user/layout.dart';
  import 'package:google_sign_in/google_sign_in.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:sign_in_with_apple/sign_in_with_apple.dart';

  import '../../core/utils/message_utils.dart';
  import '../../core/utils/utils.dart';
  import '../../server/auth_service.dart';
  import '../core/utils/auth_utils.dart';
  import '../core/widgets/loader_widgets.dart';
// import 'auth/VerifyPhonePage.dart';
  import 'auth/sign_up_screen.dart';

  class LoginBottomSheet extends StatefulWidget {
    const LoginBottomSheet({super.key});

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
          if (userModel.rememberToken != null) {
            await prefs.setString('remember_token', userModel.rememberToken!);
          }
          if (mounted) {
            AuthUtils.navigateByRole(context, user);
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
           } else {
               showMessage(context, 'Backend Google login failed.', color: Colors.red);
           }
        // if (userModel != null && mounted) {
        //   if (userModel.needsPhone == true && userModel.tempToken != null) {
        //     Navigator.pushReplacement(
        //       context,
        //       MaterialPageRoute(
        //         builder: (_) => VerifyPhonePage(tempToken: userModel.tempToken!),
        //       ),
        //     );
        //   } else {
        //     final prefs = await SharedPreferences.getInstance();
        //     if (userModel.token != null) {
        //       await prefs.setString('token', userModel.token!);
        //     }
        //
        //     Navigator.pushReplacement(
        //       context,
        //       MaterialPageRoute(
        //         builder: (_) => Layout(userId: userModel.user!.id!),
        //       ),
        //     );
        //   }
        // } else {
        //   showMessage(context, 'Backend Google login failed.', color: Colors.red);
        // }
      } catch (e) {
        showMessage(context, 'Google Sign-In failed: $e', color: Colors.red);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }

    // ---------------- Apple Login ----------------
    Future<void> _signInWithApple() async {
      if (!(Platform.isIOS || Platform.isMacOS)) return;
      if (!mounted) return;

      setState(() => _isLoading = true);

      try {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: 'com.kheangsenghorng.frontend.service',
            redirectUri: Uri.parse(
              'https://drinking-coffee-8eb88.firebaseapp.com/__/auth/handler',
            ),
          ),
        );

        final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
        );

        final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
        final idToken = await userCredential.user?.getIdToken();
        if (idToken == null) throw Exception("Failed to get Firebase ID token");

        // final phoneNumber = await showDialog<String>(
        //   context: context,
        //   builder: (_) {
        //     String? tempPhone;
        //     return AlertDialog(
        //       title: const Text('Enter your phone number'),
        //       content: TextField(
        //         keyboardType: TextInputType.phone,
        //         decoration: const InputDecoration(hintText: 'Phone number'),
        //         onChanged: (value) => tempPhone = value,
        //       ),
        //       actions: [
        //         TextButton(
        //           onPressed: () => Navigator.pop(context, tempPhone),
        //           child: const Text('Submit'),
        //         ),
        //       ],
        //     );
        //   },
        // );


       // final userModel = await AuthService.appleLogin(idToken, phone: phoneNumber);
        final userModel = await AuthService.appleLogin(idToken);
        var user = userModel?.user;

        if (user != null && mounted) {
          final prefs = await SharedPreferences.getInstance();
          final role = user.role ?? 'user';
          await prefs.setString('role', role);
          if (userModel?.token != null) await prefs.setString('token', userModel!.token!);
          if (userModel?.rememberToken != null) {
            await prefs.setString('remember_token', userModel!.rememberToken!);
          }
          AuthUtils.navigateByRole(context, user);
          showMessage(context, 'Apple login successful!', color: Colors.green);
        } else if (mounted) {
          showMessage(context, 'Apple login failed.', color: Colors.red);
        }
      } catch (e) {
        if (mounted) showMessage(context, 'Apple Sign-In failed: $e', color: Colors.red);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }

    // ---------------- Social Button ----------------
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
                      const Text(
                        'Welcome Back',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
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
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: [AutofillHints.email],
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
                    keyboardType: TextInputType.visiblePassword,
                    autofillHints: [AutofillHints.password],
                  ),
                  const SizedBox(height: 25),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _signInWithEmail(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCC00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black87)
                          : const Text(
                        'LOG IN',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => showMessage(
                          context, 'Forgot Password functionality not yet implemented.', color: Colors.blue),
                      child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFFFFCC00))),
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
            buildFullScreenLoader(_isLoading), // ← now works!
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
      TextInputType keyboardType = TextInputType.text,
      List<String>? autofillHints,
    }) {
      return TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        autofillHints: autofillHints,
        keyboardAppearance: Brightness.light,
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
