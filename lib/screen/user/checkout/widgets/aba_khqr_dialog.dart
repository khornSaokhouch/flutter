import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ABAKHQRDialog extends StatelessWidget {
  final String? qrImageBase64;
  final String? deeplink;
  final String currency;

  const ABAKHQRDialog({
    super.key,
    required this.qrImageBase64,
    required this.deeplink,
    required this.currency, required int orderId,
  });

  @override
  Widget build(BuildContext context) {
    final Uint8List? imageBytes = qrImageBase64 != null
        ? base64Decode(qrImageBase64!.split(',').last)
        : null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Small QR icon
            const Icon(Icons.qr_code, size: 28),

            const SizedBox(height: 12),

            /// Title
            const Text(
              'Pay with ABA',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 20),

            /// KHQR Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: imageBytes != null
                  ? Image.memory(
                imageBytes,
                width: 230,
              )
                  : const SizedBox(
                height: 230,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

            const SizedBox(height: 16),

            /// Currency
            Text(
              'Currency: $currency',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 24),

            /// Open ABA App
            if (deeplink != null)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final uri = Uri.parse(deeplink!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: const Text(
                    'Open ABA Mobile',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            /// Cancel
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
