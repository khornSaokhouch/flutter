import 'package:flutter/material.dart';

/// Simple SnackBar with optional color
void showMessage(BuildContext context, String message, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color ?? Colors.brown, // default color
      duration: const Duration(seconds: 2),
    ),
  );
}

enum SnackBarType { success, error, warning }

/// SnackBar with type-based colors
void showSnackBar(BuildContext context, String message, SnackBarType type) {
  Color bgColor;
  switch (type) {
    case SnackBarType.success:
      bgColor = Colors.green;
      break;
    case SnackBarType.error:
      bgColor = Colors.red;
      break;
    case SnackBarType.warning:
      bgColor = Colors.orange;
      break;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: bgColor,
      duration: const Duration(seconds: 3),
    ),
  );
}
