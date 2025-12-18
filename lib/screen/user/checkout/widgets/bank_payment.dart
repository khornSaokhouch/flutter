import 'package:flutter/material.dart';

Future<bool> payWithBank(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (_) => const AlertDialog(
      title: Text("Bank Transfer"),
      content: Text("ABA Bank\nAccount: 123-456-789"),
    ),
  );
  return true;
}
