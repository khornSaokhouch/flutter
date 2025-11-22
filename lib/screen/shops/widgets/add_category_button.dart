import 'package:flutter/material.dart';

class AddCategoryButton extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final Color accentColor;

  const AddCategoryButton({
    super.key,
    required this.isOpen,
    required this.onToggle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onToggle,
        icon: Icon(isOpen ? Icons.close : Icons.add),
        label: Text(
          isOpen ? "Close" : "Add New Category",
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
