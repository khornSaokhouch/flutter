import 'package:flutter/material.dart';

class NotesInput extends StatelessWidget {
  const NotesInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const TextField(
        maxLines: 2,
        decoration: InputDecoration(
          hintText: "E.g. Less sugar, allergies...",
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }
}
