import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/style_overlay_banner.dart';
import '../../server/test/push_test_service.dart';

class PushTestPage extends StatefulWidget {
  const PushTestPage({super.key});

  @override
  State<PushTestPage> createState() => _PushTestPageState();
}

class _PushTestPageState extends State<PushTestPage>
    with TickerProviderStateMixin {
  String lastEvent = 'Waiting for push...';

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  @override
  void initState() {
    super.initState();
    _listenPushEvents();
  }

  void _listenPushEvents() {
    /// 🔔 FOREGROUND PUSH
    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      if (!mounted) return;

      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? '';

      _showTopBanner(title, body);

      setState(() {
        lastEvent = '🔔 Foreground push:\n$title';
      });
    });

    /// 📲 BACKGROUND → TAP NOTIFICATION
    _onMessageOpenedSub =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          if (!mounted) return;

          setState(() {
            lastEvent = '📲 Notification tapped\nData: ${message.data}';
          });
        });
  }

  /// 🔝 SLIDE-DOWN TOP BANNER
  void _showTopBanner(String title, String body) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    late OverlayEntry entry;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final animation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        child: SlideTransition(
          position: animation,
          child: TopBanner(
            title: title,
            body: body,
            onClose: () {
              controller.reverse().then((_) {
                entry.remove();
                controller.dispose();
              });
            },
          ),
        ),
      ),
    );

    overlay.insert(entry);
    controller.forward();

    /// ⏱ AUTO DISMISS
    Future.delayed(const Duration(seconds: 3), () {
      if (!controller.isDismissed) {
        controller.reverse().then((_) {
          entry.remove();
          controller.dispose();
        });
      }
    });
  }

  @override
  void dispose() {
    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Test Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              lastEvent,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  await PushTestService.sendTestPush();
                },
                child: const Text('Send Test Push'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

