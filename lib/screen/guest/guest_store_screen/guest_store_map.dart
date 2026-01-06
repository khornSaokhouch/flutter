import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Fixed import for LatLng
import '../../../models/shop.dart';
import 'guest_menu_Items_list_screen.dart';

class GuestStoreMapPage extends StatefulWidget {
  final List<Shop> shops;
  final dynamic initialPosition;

  const GuestStoreMapPage({super.key, required this.shops, this.initialPosition});

  @override
  State<GuestStoreMapPage> createState() => _GuestStoreMapPageState();
}

class _GuestStoreMapPageState extends State<GuestStoreMapPage> with TickerProviderStateMixin {
  late final MapController _mapController;
  late final PageController _pageController;
  int _currentIndex = 0;

  final Color _primaryGreen = const Color(0xFF2E7D32);
  final Color _surfaceWhite = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pageController = PageController(viewportFraction: 0.85);
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    final animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    final shop = widget.shops[index];
    if (shop.latitude != null && shop.longitude != null) {
      _animatedMapMove(LatLng(shop.latitude!, shop.longitude!), 15.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    LatLng startPoint = const LatLng(11.5564, 104.9282);
    if (widget.shops.isNotEmpty && widget.shops[0].latitude != null) {
      startPoint = LatLng(widget.shops[0].latitude!, widget.shops[0].longitude!);
    }

    return Scaffold(
      backgroundColor: _surfaceWhite,
      body: Stack(
        children: [
          // 1. MAP LAYER
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: startPoint,
              initialZoom: 14.0,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.drinkingcoffee.frontend',
              ),
              MarkerLayer(
                markers: widget.shops.asMap().entries.map<Marker>((entry) {
                  int idx = entry.key;
                  Shop shop = entry.value;
                  bool isSelected = _currentIndex == idx;

                  return Marker(
                    point: LatLng(shop.latitude!, shop.longitude!),
                    width: isSelected ? 80 : 60,
                    height: isSelected ? 80 : 60,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => _pageController.animateToPage(idx, 
                        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
                      child: _buildCustomPin(isSelected),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 2. ZOOM CONTROLS
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.4,
            child: Column(
              children: [
                _buildZoomButton(Icons.add, () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                }),
                const SizedBox(height: 12),
                _buildZoomButton(Icons.remove, () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                }),
              ],
            ),
          ),

          // 3. TOP BAR
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 20, right: 20, bottom: 20
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: _primaryGreen, size: 20),
                  ),
                  const Expanded(
                    child: Text(
                      "Find a Store",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          // 4. BOTTOM UI
          Positioned(
            bottom: 20, left: 0, right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 140,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.shops.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      return AnimatedScale(
                        duration: const Duration(milliseconds: 300),
                        scale: _currentIndex == index ? 1.0 : 0.9,
                        child: Opacity(
                          opacity: _currentIndex == index ? 1.0 : 0.7,
                          child: _buildShopCard(widget.shops[index], _currentIndex == index),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ElevatedButton(
                    onPressed: () {
                      final currentShop = widget.shops[_currentIndex];
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => GuestMenuScreen(shopId: currentShop.id)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      minimumSize: const Size(double.infinity, 58),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 5,
                    ),
                    child: const Text(
                      "CONFIRM STORE", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
      ),
      child: IconButton(
        icon: Icon(icon, color: _primaryGreen, size: 22),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCustomPin(bool isSelected) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: 0,
          child: Icon(
            Icons.location_on_rounded, 
            color: isSelected ? _primaryGreen : Colors.grey[400], 
            size: isSelected ? 60 : 50,
          ),
        ),
        Positioned(
          top: isSelected ? 10 : 8,
          child: Container(
            width: isSelected ? 36 : 28,
            height: isSelected ? 36 : 28,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: Image.asset(
                'assets/images/img_1.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                    Icon(Icons.coffee, color: _primaryGreen, size: isSelected ? 20 : 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShopCard(Shop shop, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isActive ? 0.1 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],

      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 75, height: 75, color: Colors.grey[100],
              child: (shop.imageUrl != null && shop.imageUrl!.isNotEmpty)
                ? Image.network(shop.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.store, color: _primaryGreen)) 
                : Icon(Icons.storefront_rounded, color: _primaryGreen, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(shop.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(shop.location ?? "Nearby", style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text("${shop.distanceInKm?.toStringAsFixed(1) ?? '0.0'} km away", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primaryGreen)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
