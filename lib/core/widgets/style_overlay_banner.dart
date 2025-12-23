import 'package:flutter/material.dart';

class TopBanner extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onClose;

  const TopBanner({
    super.key,
    required this.title,
    required this.body,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notifications, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: onClose,
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
