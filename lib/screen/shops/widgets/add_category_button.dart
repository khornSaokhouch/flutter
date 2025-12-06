import 'package:flutter/material.dart';

class AddCategoryButton extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final Color accentColor;

  // Theme Colors
  final Color _espressoBrown = const Color(0xFF4B2C20);

  const AddCategoryButton({
    super.key,
    required this.isOpen,
    required this.onToggle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: (isOpen ? Colors.grey : _espressoBrown).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onToggle,
        icon: Icon(
          isOpen ? Icons.close_rounded : Icons.add_circle_outline_rounded,
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          isOpen ? "Cancel" : "Add New Category",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isOpen ? Colors.grey[600] : _espressoBrown,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}