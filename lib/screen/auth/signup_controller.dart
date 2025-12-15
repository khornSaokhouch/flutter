import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/utils/utils.dart';
import '../../models/user.dart';
import '../../server/auth_service.dart';
import '../user/layout.dart';

class SignUpController extends ChangeNotifier {
  final BuildContext context;

  SignUpController(this.context);

  final usernameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  final _googleSignIn = GoogleSignIn();
  final _auth = FirebaseAuth.instance;

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }

  Future<void> createAccount() async {
    final username = usernameCtrl.text.trim();
    final phone = formatPhoneNumber(phoneCtrl.text);
    final password = passwordCtrl.text.trim();
    final confirmPassword = confirmPasswordCtrl.text.trim();

    if (username.isEmpty || phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _snack("Please fill all fields");
      return;
    }
    if (!doPasswordsMatch(password, confirmPassword)) {
      _snack("Passwords do not match");
      return;
    }
    if (!isPasswordValid(password)) {
      _snack("Password must be at least 8 characters");
      return;
    }

    _setLoading(true);
    try {
      final userModel = await AuthService.register(
        username,
        phone,
        password,
        confirmPassword,
      );

      if (userModel?.user != null) {
        _snack("Sign up successful");
        _goToLayout(userModel!);
      } else {
        _snack(userModel?.message ?? "Registration failed");
      }
    } catch (e) {
      _snack(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
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

      if (idToken == null) return;

      final userModel = await AuthService.firebaseLogin(idToken);
      if (userModel?.user != null) {
        _goToLayout(userModel!);
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithApple() async {
    if (!(Platform.isIOS || Platform.isMacOS)) return;
    _setLoading(true);
    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
      );

      final credential = OAuthProvider("apple.com").credential(
        idToken: apple.identityToken,
        accessToken: apple.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) return;

      final userModel = await AuthService.firebaseLogin(idToken);
      if (userModel?.user != null) {
        _goToLayout(userModel!);
      }
    } finally {
      _setLoading(false);
    }
  }

  void _goToLayout(UserModel userModel) {
    final int? id = userModel.user?.id;

    if (id == null) {
      _snack("User ID missing in response");
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => Layout(userId: id), // ✅ now int, not int?
      ),
          (_) => false,
    );
  }


  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
