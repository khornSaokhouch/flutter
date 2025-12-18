import 'package:flutter/material.dart';

class ShopHeaderImage extends StatelessWidget {
  final String? imageUrl;

  const ShopHeaderImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320.0,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF4B2C20),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          // Add Favorite Icon logic here if needed
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            else
              _placeholder(),
            
            // Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black26, Colors.transparent],
                  stops: [0.0, 0.3],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.store_mall_directory_rounded, size: 60, color: Colors.grey[400]),
      ),
    );
  }
}