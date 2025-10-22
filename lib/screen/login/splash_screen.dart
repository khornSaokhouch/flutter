import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/screen/login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Start fade animation
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Navigate to LoginScreen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
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
      backgroundColor: const Color(0xfff7f0e8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ☕ Coffee image
            ScaleTransition(
              scale: _animation,
              child: Image.asset(
                'assets/images/coffee.png',
                height: 180,
              ),
            ),
            const SizedBox(height: 30),

            // Coffee beans loading indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                7,
                    (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TweenAnimationBuilder(
                    tween: Tween(begin: 0.5, end: 1.0),
                    duration: Duration(milliseconds: 600 + index * 100),
                    builder: (context, double scale, _) {
                      return Transform.scale(
                        scale: scale,
                        child: Image.asset(
                          'assets/images/bean.png', // coffee bean icon
                          height: 20,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
