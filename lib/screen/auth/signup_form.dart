import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'signup_controller.dart';
import 'signup_helpers.dart';

class SignUpForm extends StatelessWidget {
  const SignUpForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SignUpController(context);

    return Column(
      children: [
        const Text(
          "Create Account",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        buildInput("Username", controller.usernameCtrl, "Enter username"),
        buildInput("Phone", controller.phoneCtrl, "Enter phone"),
        buildPassword("Password", controller.passwordCtrl,
            controller.obscurePassword, () {
              controller.obscurePassword = !controller.obscurePassword;
            }),
        buildPassword("Confirm Password", controller.confirmPasswordCtrl,
            controller.obscureConfirmPassword, () {
              controller.obscureConfirmPassword =
              !controller.obscureConfirmPassword;
            }),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: controller.createAccount,
          child: const Text("REGISTER"),
        ),

        const SizedBox(height: 20),

        socialButton(
          label: "Sign up with Google",
          onPressed: controller.signInWithGoogle,
        ),

        if (Platform.isIOS || Platform.isMacOS)
          socialButton(
            label: "Sign up with Apple",
            onPressed: controller.signInWithApple,
            dark: true,
          ),
      ],
    );
  }
}
