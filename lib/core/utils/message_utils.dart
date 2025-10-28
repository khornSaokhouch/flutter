
import 'package:flutter/material.dart';

/// Show a SnackBar with a message
void showMessage(BuildContext context, String message, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color ?? Colors.brown, // default color
      duration: const Duration(seconds: 2),
    ),
  );
}