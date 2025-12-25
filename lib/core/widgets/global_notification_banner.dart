import 'dart:async';
import 'package:flutter/material.dart';

import '../widgets/style_overlay_banner.dart';
import '../../server/notification_service.dart';

class GlobalNotificationBanner extends StatefulWidget {
  final Widget child;

  const GlobalNotificationBanner({super.key, required this.child});

  @override
  State<GlobalNotificationBanner> createState() =>
      _GlobalNotificationBannerState();
}

class _GlobalNotificationBannerState extends State<GlobalNotificationBanner>
    with TickerProviderStateMixin {
  OverlayEntry? _entry;
  AnimationController? _controller;
  Timer? _dismissTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    /// 🔔 Listen once, globally
    NotificationService().init(
      onMessage: (title, body) {
        if (!mounted || _isDisposed) return;
        _showBanner(title, body);
      },
    );
  }

  void _showBanner(String title, String body) {
    if (_entry != null) return;

    final overlay = Overlay.of(context);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final animation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller!,
        curve: Curves.easeOut,
      ),
    );

    _entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: SlideTransition(
          position: animation,
          child: TopBanner(
            title: title,
            body: body,
            onClose: _hideBanner,
          ),
        ),
      ),
    );

    overlay.insert(_entry!);
    _controller!.forward();

    _dismissTimer = Timer(
      const Duration(seconds: 3),
      _hideBanner,
    );
  }

  void _hideBanner() {
    if (_controller == null || _isDisposed) return;

    _dismissTimer?.cancel();
    _dismissTimer = null;

    _controller!.reverse().then((_) {
      if (_isDisposed) return;
      _entry?.remove();
      _entry = null;
      _controller?.dispose();
      _controller = null;
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _dismissTimer?.cancel();
    _entry?.remove();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
