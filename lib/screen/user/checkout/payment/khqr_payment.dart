
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../models/aba_qr_response.dart';
import '../../../../server/aba_aof_screen.dart';

class AbaPaymentScreen extends StatefulWidget {
  final double amount;
  final int? orderId;

  final int? userId;

  const AbaPaymentScreen({
    super.key,
    required this.amount,
    this.orderId,
    this.userId
  });

  @override
  State<AbaPaymentScreen> createState() => _AbaPaymentScreenState();
}

class _AbaPaymentScreenState extends State<AbaPaymentScreen> {
  AbaQrResponse? qr;
  bool loading = true;

  bool _autoOpened = false;


  @override
  void initState() {
    super.initState();
    _generateQr();
  }

  Future<void> _generateQr() async {
    try {
      qr = await AbaAofService.generateQr(
        amount: widget.amount,
        orderId: widget.orderId,
        userId:widget.userId,
      );
      debugPrint(qr?.deeplink);
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate ABA QR')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }

      // ✅ AUTO OPEN ABA (only once)
      if (!_autoOpened && qr?.deeplink != null) {
        _autoOpened = true;

        // Small delay lets UI finish building
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _openAbaApp();
          }
        });
      }
    }
  }


  /// 🔐 Strip `data:image/png;base64,` if present
  Uint8List _decodeBase64Image(String data) {
    final cleanBase64 =
    data.contains(',') ? data.split(',').last : data;
    return base64Decode(cleanBase64);
  }

  Future<void> _openAbaApp() async {
    final deeplink = qr?.deeplink;
    if (deeplink == null) return;

    // Check if ABA app is installed
    final abaSchemeUri = Uri.parse('abamobilebank://');
    final isInstalled = await canLaunchUrl(abaSchemeUri);

    if (isInstalled) {
      final uri = Uri.parse(Uri.encodeFull(deeplink));
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // Future<void> _openAbaStore() async {
  //   final bool isIOS =
  //       Theme.of(context).platform == TargetPlatform.iOS;
  //
  //   final Uri storeUri = isIOS
  //       ? Uri.parse(
  //     'https://apps.apple.com/kh/app/aba-mobile/id968860649',
  //   )
  //       : Uri.parse(
  //     'https://play.google.com/store/apps/details?id=com.paygo24.ibank',
  //   );
  //
  //   await launchUrl(
  //     storeUri,
  //     mode: LaunchMode.externalApplication,
  //   );
  // }




  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (qr == null) {
      return const Scaffold(
        body: Center(child: Text('Unable to load ABA QR')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay with ABA'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (qr!.qrImage != null)
                  Image.memory(
                    _decodeBase64Image(qr!.qrImage!),
                    width: 260,
                    fit: BoxFit.contain,
                  ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _openAbaApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0072CE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Open ABA Pay App',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Transaction ID:\n${qr!.tranId}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

