
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../models/aba_qr_response.dart';
import '../../../../server/aba_aof_screen.dart';
import '../../../../server/local_notification_service.dart';
import 'payment_failed_page.dart';
import 'payment_success_page.dart';

class AbaPaymentScreen extends StatefulWidget {
  final double amount;
  final int? orderId;
  final int? userId;

  const AbaPaymentScreen({
    super.key,
    required this.amount,
    this.orderId,
    this.userId,
  });

  @override
  State<AbaPaymentScreen> createState() => _AbaPaymentScreenState();
}

class _AbaPaymentScreenState extends State<AbaPaymentScreen> {
  AbaQrResponse? qr;
  bool loading = true;
  bool _autoOpened = false;
  bool _finished = false; // ✅ prevent duplicate finish

  Timer? _statusTimer;
  StreamSubscription<RemoteMessage>? _pushSub;

  String paymentStatus = 'initiated';

  @override
  void initState() {
    super.initState();
    _generateQr();
    _listenToPush();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _pushSub?.cancel();
    super.dispose();
  }

  // =========================
  // Generate ABA QR
  // =========================
  Future<void> _generateQr() async {
    try {
      qr = await AbaAofService.generateQr(
        amount: widget.amount,
        orderId: widget.orderId,
        userId: widget.userId,
      );

      _startStatusPolling();
    } catch (e) {
      debugPrint('QR ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate ABA QR')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);

      if (!_autoOpened && qr?.deeplink != null) {
        _autoOpened = true;
        Future.delayed(const Duration(milliseconds: 300), _openAbaApp);
      }
    }
  }

  // =========================
  // Poll payment status
  // =========================
  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (qr?.tranId == null || _finished) return;

      try {
        final status =
        await AbaAofService.checkPaymentStatus(tranId: qr!.tranId);

        if (mounted && status != paymentStatus) {
          setState(() => paymentStatus = status);
        }

        if (status == 'paid' || status == 'failed') {
          _onPaymentFinished(status);
        }
      } catch (e) {
        debugPrint('STATUS ERROR: $e');
      }
    });
  }

  // =========================
  // Listen push → update UI
  // =========================
  void _listenToPush() {
    _pushSub = FirebaseMessaging.onMessage.listen((message) {
      if (_finished) return;

      final data = message.data;

      if (data['type'] == 'payment' &&
          data['tran_id'] == qr?.tranId) {
        final status = data['status'];

        if (status == 'paid' || status == 'failed') {
          _onPaymentFinished(status);
        }
      }
    });
  }

  // =========================
  // Finish payment (SAFE)
  // =========================
  Future<void> _onPaymentFinished(String status) async {
    if (!mounted || _finished) return;
    _finished = true;

    _statusTimer?.cancel();

    // ✅ Local notification ONLY on iOS Simulator
    if (status == 'paid' && Platform.isIOS && !Platform.isMacOS) {
      await LocalNotificationService.showPaymentSuccess();
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessPage(
          orderId: qr?.tranId,
          userId: widget.userId ?? 0,
        ),
      ),
    );
  }

  // =========================
  // Open ABA App
  // =========================
  Future<void> _openAbaApp() async {
    final deeplink = qr?.deeplink;
    if (deeplink == null) return;

    final abaSchemeUri = Uri.parse('abamobilebank://');
    if (await canLaunchUrl(abaSchemeUri)) {
      await launchUrl(
        Uri.parse(Uri.encodeFull(deeplink)),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // =========================
  // Decode QR image
  // =========================
  Uint8List _decodeBase64Image(String data) {
    final clean = data.contains(',') ? data.split(',').last : data;
    return base64Decode(clean);
  }

  // =========================
  // UI
  // =========================
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Image.memory(
                _decodeBase64Image(qr!.qrImage!),
                width: 260,
              ),

              const SizedBox(height: 24),

              Text(
                'Status: $paymentStatus',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                  paymentStatus == 'paid' ? null : _openAbaApp,
                  child: const Text('Open ABA Pay App'),
                ),
              ),

              const SizedBox(height: 16),

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
    );
  }
}

