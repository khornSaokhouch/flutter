import 'package:flutter/material.dart';

class LogoLoading extends StatefulWidget {
  final double size;
  final String imagePath;

  const LogoLoading({
    super.key,
    this.size = 50.0, // Default size
    this.imagePath = 'assets/images/img_1.png', // Default image
  });

  @override
  State<LogoLoading> createState() => _LogoLoadingState();
}

class _LogoLoadingState extends State<LogoLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Creates a "Breathing" (Pulsing) animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000), // Speed of pulse
      vsync: this,
    )..repeat(reverse: true); // Repeat back and forth

    _animation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _animation,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Image.asset(
            widget.imagePath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}