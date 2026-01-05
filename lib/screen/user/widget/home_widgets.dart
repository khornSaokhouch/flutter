// home_widgets.dart
import 'package:flutter/material.dart';

import '../../../models/shop.dart';


/// Banner widget used at top of HomeScreen
Widget BannerWidget() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 20.0),
    child: Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        image: const DecorationImage(
          image: AssetImage("assets/images/banner.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black12, Colors.black54],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Join the Rewards program to enjoy free beverages!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.4,
                shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    ),
  );
}

/// Pickup & Delivery cards row
class PickupDeliveryRow extends StatelessWidget {
  final int userId;
  final VoidCallback onPickupTap;
  final VoidCallback onDeliveryTap;

  const PickupDeliveryRow({required this.userId, required this.onPickupTap, required this.onDeliveryTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Greeting!!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildBigCard(title: "Pickup", imagePath: 'assets/images/pickup.jpg', isActive: true, onTap: onPickupTap)),
            const SizedBox(width: 16),
            Expanded(child: _buildBigCard(title: "Delivery", imagePath: 'assets/images/pickup.jpg', isActive: false, onTap: onDeliveryTap)),
          ],
        ),
      ],
    );
  }
}

Widget _buildBigCard({
  required String title,
  required String imagePath,
  required bool isActive,
  required VoidCallback onTap,
}) {
  return Container(
    height: 140,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 5))]),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Positioned.fill(
            child: isActive ? Image.asset(imagePath, fit: BoxFit.cover) : ColorFiltered(colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation), child: Image.asset(imagePath, fit: BoxFit.cover)),
          ),
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.transparent, Colors.black.withValues(alpha: 0.8)], stops: const [0.0, 0.5, 1.0])))),
          if (!isActive) Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.3))),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Row(
                    children: [
                      Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isActive ? Colors.white : Colors.white70)),
                      if (!isActive) ...[const Spacer(), const Icon(Icons.lock_outline, color: Colors.white70, size: 20)],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Nearby header (title + see all)
class NearbyHeader extends StatelessWidget {
  final VoidCallback onSeeAll;
  const NearbyHeader({required this.onSeeAll, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Nearby Stores', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E))),
        TextButton(onPressed: onSeeAll, child: const Text("See All", style: TextStyle(color: Color(0xFF4A6B5C)))),
      ]),
    );
  }
}

/// Build shop sliver from a FutureBuilder snapshot
Widget buildShopsSliver(BuildContext context, AsyncSnapshot<List<Shop>> snapshot, Widget Function(Shop) itemBuilder) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40.0), child: Center(child: CircularProgressIndicator(color: Color(0xFF1B4D3E)))));
  } else if (snapshot.hasError) {
    return SliverToBoxAdapter(child: Center(child: Text('Error: ${snapshot.error}')));
  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
    return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40.0), child: Center(child: Text('No stores found nearby.'))));
  }

  final shops = snapshot.data!;
  return SliverList(delegate: SliverChildBuilderDelegate((context, index) => itemBuilder(shops[index]), childCount: shops.length));
}

/// Coming soon dialog helper
void showComingSoonDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle), child: const Icon(Icons.rocket_launch_rounded, size: 32, color: Color(0xFF1B4D3E))),
          const SizedBox(height: 20),
          const Text("Coming Soon!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("We are working hard to bring delivery to your location.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4D3E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text("Got it"),
            ),
          ),
        ]),
      ),
    ),
  );
}
