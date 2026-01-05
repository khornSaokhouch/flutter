import 'package:flutter/material.dart';
import 'login_bottom_sheet.dart';

void showLoginBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const LoginBottomSheet(),
  );
}
