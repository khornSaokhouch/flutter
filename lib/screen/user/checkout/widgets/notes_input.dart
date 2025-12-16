import 'package:flutter/material.dart';

class NotesWidget extends StatelessWidget {
  final TextEditingController controller;

  const NotesWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(labelText: "Notes"),
    );
  }
}
