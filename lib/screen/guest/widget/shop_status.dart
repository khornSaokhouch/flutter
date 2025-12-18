import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final bool isOpen;
  const StatusBadge({super.key, required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [], // ✅ explicitly no shadow
      ),
      child: Text(
        isOpen ? "Open" : "Closed",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
