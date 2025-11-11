import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../screen/guest/guest_screen.dart';
import '../../screen/user/coffeeAppHome.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _coffeeCupAnimation;
  late Animation<double> _coffeeBeansOpacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _coffeeCupAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _coffeeBeansOpacityAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
          ),
        );

    _controller.forward();

    // 🔹 Ask for location permission and get location before navigation
    // _checkLocationPermission();

    _navigateAfterDelay();
  }

  // ✅ Function to request permission and get location
  Future<void> _checkLocationPermission() async {
    // Request permission using permission_handler
    var status = await Permission.location.request();

    if (status.isGranted) {
      // Permission granted, get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print("📍 User location: ${position.latitude}, ${position.longitude}");

      // Optional: Save location locally
      final prefs = await SharedPreferences.getInstance();
      prefs.setDouble('latitude', position.latitude);
      prefs.setDouble('longitude', position.longitude);
    } else if (status.isDenied) {
      print("⚠️ Location permission denied");
    } else if (status.isPermanentlyDenied) {
      openAppSettings(); // Let user enable it manually
    }
  }

  Future<void> _navigateAfterDelay() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        if (isLoggedIn) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen(userId: 70)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const GuestLayout()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          FadeTransition(
            opacity: _coffeeBeansOpacityAnimation,
            child: Image.asset(
              'assets/images/image_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Main coffee cup
          Center(
            child: SlideTransition(
              position: _coffeeCupAnimation,
              child: Image.asset(
                'assets/images/img_1.png',
                width: 200,
                height: 200,
              ),
            ),
          ),
          // Floating coffee beans
          Positioned(
            top: 50,
            left: 30,
            child: FadeTransition(
              opacity: _coffeeBeansOpacityAnimation,
              child: const Icon(Icons.coffee_rounded,
                  color: Colors.brown, size: 30),
            ),
          ),
          Positioned(
            top: 100,
            right: 50,
            child: FadeTransition(
              opacity: _coffeeBeansOpacityAnimation,
              child: const Icon(Icons.coffee_rounded,
                  color: Colors.brown, size: 25),
            ),
          ),
          Positioned(
            bottom: 250,
            left: 100,
            child: FadeTransition(
              opacity: _coffeeBeansOpacityAnimation,
              child: const Icon(Icons.coffee_rounded,
                  color: Colors.brown, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
