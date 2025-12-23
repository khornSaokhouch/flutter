import 'package:flutter/material.dart';
import '../../main.dart';
import '../widgets/style_overlay_banner.dart';

class OverlayBannerController {
  static OverlayEntry? _entry;

  static void show({
    required String title,
    required String body,
  }) {
    if (_entry != null) return;

    // ✅ Wait until UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;

      if (context == null) return;

      final overlay = Overlay.of(context, rootOverlay: true);
      if (overlay == null) return;

      _entry = OverlayEntry(
        builder: (_) => Positioned(
          top: 50,
          left: 16,
          right: 16,
          child: TopBanner(
            title: title,
            body: body,
            onClose: hide,
          ),
        ),
      );

      overlay.insert(_entry!);

      // Auto-hide after 3s
      Future.delayed(const Duration(seconds: 3), hide);
    });
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}
