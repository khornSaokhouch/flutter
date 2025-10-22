import 'package:flutter/material.dart';

class LoadingSplash {
  /// Shows a full-screen splash/loading dialog
  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (_) => const Scaffold(
        backgroundColor: Color(0xfff7f0e8),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(
                image: AssetImage('assets/images/coffee.png'),
                height: 120,
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Color(0xff4a2c2a)),
            ],
          ),
        ),
      ),
    );
  }

  /// Closes the splash/loading dialog
  static void hide(BuildContext context) {
    Navigator.pop(context);
  }
}
