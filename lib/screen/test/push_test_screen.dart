import 'package:flutter/material.dart';
import 'package:frontend/server/test/push_test_service.dart';


class PushTestScreen extends StatelessWidget {
  const PushTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Payment Push'),
        centerTitle: true,
      ),
      body: Center(
        child: SizedBox(
          width: 220,
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
              try {
                await PushTestService.sendPaymentPush(408);
                debugPrint('✅ Push sent');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Push sent successfully'),
                  ),
                );
              } catch (e) {
                debugPrint('❌ Error: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error sending push: $e'),
                  ),
                );
              }
            },
            child: const Text('Test Payment Push'),
          ),
        ),
      ),
    );
  }
}
