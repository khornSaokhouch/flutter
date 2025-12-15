import 'package:flutter/material.dart';

Widget buildInput(
    String label,
    TextEditingController controller,
    String hint,
    ) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

Widget buildPassword(
    String label,
    TextEditingController controller,
    bool obscure,
    VoidCallback toggle,
    ) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: "••••••••",
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

Widget socialButton({
  required String label,
  required VoidCallback onPressed,
  bool dark = false,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: dark ? Colors.black : Colors.white,
        foregroundColor: dark ? Colors.white : Colors.black,
      ),
      onPressed: onPressed,
      child: Text(label),
    ),
  );
}
