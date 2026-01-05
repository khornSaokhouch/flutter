import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/screen/user/layout.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/utils/message_utils.dart';
import '../../core/utils/utils.dart';
import '../../server/auth_service.dart';
import '../core/utils/auth_utils.dart';
// import 'auth/VerifyPhonePage.dart';
import '../server/push_service.dart';
import 'auth/sign_up_screen.dart';

class LoginBottomSheet extends StatefulWidget {
  const LoginBottomSheet({super.key});

  @override
  State<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);

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

          await PushService.init(
            accessToken: userModel.token!,
            userId: userModel.user!.id!,
          );

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

  Future<void> _signInWithGoogle() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final googleSignIn = (Platform.isIOS || Platform.isMacOS)
          ? GoogleSignIn(
        clientId: dotenv.env['GOOGLE_CLIENT_ID'],
        scopes: const ['email'],
      )
          : GoogleSignIn(scopes: const ['email']);

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (!mounted) return;
        showMessage(
          context,
          'Google Sign-In cancelled.',
          color: Colors.orange,
        );
        return;
      }

      final googleAuth = await googleUser.authentication;
      final googleIdToken = googleAuth.idToken;
      if (googleIdToken == null) {
        if (!mounted) return;
        showMessage(
          context,
          'No idToken from Google (check iOS clientId / Firebase config).',
          color: Colors.red,
        );
        return;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleIdToken,
      );

      final userCredential =
      await _auth.signInWithCredential(credential);

      final firebaseIdToken =
      await userCredential.user?.getIdToken();

      if (firebaseIdToken == null) {
        if (!mounted) return;
        showMessage(
          context,
          'Could not get Firebase ID token.',
          color: Colors.red,
        );
        return;
      }

      final userModel =
      await AuthService.firebaseLogin(firebaseIdToken);

      if (!mounted || userModel == null) {
        showMessage(
          context,
          'Backend Google login failed.',
          color: Colors.red,
        );
        return;
      }

      // 🔔 INIT PUSH (GOOGLE LOGIN)
      final accessToken = userModel.token;
      final userId = userModel.user?.id;

      if (accessToken != null && userId != null) {
        await PushService.init(
          accessToken: accessToken,
          userId: userId,
        );
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => Layout(userId: userId!),
        ),
            (_) => false,
      );
    } catch (e, s) {
      debugPrintStack(stackTrace: s);
      if (mounted) {
        showMessage(
          context,
          'Google Sign-In failed: $e',
          color: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  Future<void> _signInWithApple() async {
    if (!(Platform.isIOS || Platform.isMacOS)) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final clientId = dotenv.env['APPLE_SERVICE_ID'];
      final redirectUri = dotenv.env['APPLE_REDIRECT_URI'];

      if (clientId == null || redirectUri == null) {
        throw Exception('Missing Apple Sign-In web configuration');
      }

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: clientId,
          redirectUri: Uri.parse(redirectUri),
        ),
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      final firebaseIdToken =
      await userCredential.user?.getIdToken();

      if (firebaseIdToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      // Keeps your commented code as requested
      // final phoneNumber = await showDialog<String>(...);
      // final userModel = await AuthService.appleLogin(firebaseIdToken, phone: phoneNumber);

      final userModel =
      await AuthService.appleLogin(firebaseIdToken);

      if (!mounted || userModel?.user == null) {
        showMessage(
          context,
          'Apple login failed.',
          color: Colors.red,
        );
        return;
      }

      final user = userModel!.user!;
      final rememberToken = userModel.rememberToken;
      final accessToken = userModel.token;
      final userId = user.id;

      if (rememberToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('remember_token', rememberToken);
      }

      // 🔔 INIT PUSH (APPLE LOGIN)
      if (accessToken != null && userId != null) {
        await PushService.init(
          accessToken: accessToken,
          userId: userId,
        );
      }

      if (!mounted) return;

      AuthUtils.navigateByRole(context, user);
      showMessage(
        context,
        'Apple login successful!',
        color: Colors.green,
      );
    } catch (e, s) {
      debugPrintStack(stackTrace: s);
      if (mounted) {
        showMessage(
          context,
          'Apple Sign-In failed: $e',
          color: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  // ---------------- Social Button ----------------
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

  // ---------------- Build ----------------
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
                // 1. Drag Handle
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

                // 2. Header (Close button + Title)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to your account',
                          style: TextStyle(
                            color: Colors.grey[600],
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
                        child: const Icon(Icons.close, size: 20, color: Colors.black54),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 3. Email Field
                _buildTextField(
                  controller: _emailController,
                  hint: 'Email or Phone Number',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: [AutofillHints.email],
                ),
                const SizedBox(height: 16),

                // 4. Password Field
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  isLast: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.grey[500],
                      size: 22,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  keyboardType: TextInputType.visiblePassword,
                  autofillHints: [AutofillHints.password],
                ),
                const SizedBox(height: 12),

                // 5. Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => showMessage(
                        context, 'Forgot Password functionality not yet implemented.',
                        color: Colors.blue),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: _freshMintGreen, // Unit Green
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 6. Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _signInWithEmail(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            ),
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
                            'Log In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 30),

                // 7. Social Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[200], thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or continue with',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[200], thickness: 1)),
                  ],
                ),
                const SizedBox(height: 24),

                // 8. Social Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (Platform.isIOS || Platform.isMacOS) ...[
                      _socialButton('assets/images/apple_logo.png', _isLoading ? () {} : _signInWithApple),
                      const SizedBox(width: 24),
                    ],
                    _socialButton('assets/images/google_logo.png', _isLoading ? () {} : _signInWithGoogle),
                  ],
                ),
                const SizedBox(height: 30),

                // 9. Sign Up Footer
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // close login sheet
                      showSignUpBottomSheet(context); // open signup sheet
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
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
          
          // Loader Overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.5),
                // The loader is built via buildFullScreenLoader but added overlay here for safety
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- Styled TextField ----------------
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
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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

// ---------------- Helper to show Bottom Sheet ----------------
void showLoginBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const LoginBottomSheet(),
  );
}

void showSignUpBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const SignUpScreen(),
  );
}
