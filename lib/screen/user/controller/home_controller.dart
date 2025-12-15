// home_controller.dart
import 'package:flutter/material.dart';

import '../../../core/utils/auth_utils.dart';
import '../../../models/shop.dart';
import '../../../models/user.dart';
import '../../../server/shop_serviec.dart';


class HomeController {
  User? user;
  bool isLoading = true;
  late Future<List<Shop>> shopsFuture;
  int? initialUserId;

  VoidCallback? _onChange;

  void init({int? userId, VoidCallback? onChange}) {
    initialUserId = userId;
    _onChange = onChange;
  }

  /// Call this when you have a valid BuildContext (so AuthUtils can use it).
  /// Example: call from State.initState() via `controller.initPage(context);`
  Future<void> initPage(BuildContext context) async {
    try {
      user = await AuthUtils.checkAuthAndGetUser(context: context, userId: initialUserId ?? 0);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      isLoading = false;
      _notify();
    }
  }

  void loadShops() {
    shopsFuture = ShopService.fetchShops().then((response) => response?.data ?? []);
    _notify();
  }

  Future<List<Shop>> refreshShops() async {
    final data = await ShopService.fetchShops();
    shopsFuture = Future.value(data?.data ?? []);
    _notify();
    return shopsFuture;
  }

  void dispose() {
    _onChange = null;
  }

  void _notify() => _onChange?.call();
}
