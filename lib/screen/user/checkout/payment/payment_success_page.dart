import 'package:flutter/material.dart';
import '../../../../server/local_notification_service.dart';
import '../../layout.dart';

class PaymentSuccessPage extends StatefulWidget {
  final String? orderId;
  final int userId; // ✅ ADDED

  const PaymentSuccessPage({
    super.key,
    this.orderId,
    required this.userId,
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  bool _notificationShown = false;

  @override
  void initState() {
    super.initState();

    // 🔔 Show local notification once when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_notificationShown) {
        _notificationShown = true;
        await LocalNotificationService.showPaymentSuccess();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 96,
              ),

              const SizedBox(height: 24),

              const Text(
                'Payment Successful',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (widget.orderId != null)
                Text(
                  'Order ID: ${widget.orderId}',
                  style: const TextStyle(color: Colors.grey),
                ),

              if (widget.userId != null)
                Text(
                  'User ID: ${widget.userId}',
                  style: const TextStyle(color: Colors.grey),
                ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Layout(userId: widget.userId),
                      ),
                          (_) => false,
                    );
                  },
                  child: const Text(
                    'Go to Home',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
