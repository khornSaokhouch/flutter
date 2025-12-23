import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/shop.dart';
import 'guest_menu_Items_list_screen.dart';

class GuestStoreMapPage extends StatefulWidget {
  final List<Shop> shops;
  final Position? initialPosition;

  const GuestStoreMapPage({super.key, required this.shops, this.initialPosition});

  @override
  State<GuestStoreMapPage> createState() => _GuestStoreMapPageState();
}

class _GuestStoreMapPageState extends State<GuestStoreMapPage> {
  late GoogleMapController mapController;
  late PageController _pageController; // Controller for the horizontal scroll
  int _currentIndex = 0;
  Set<Marker> _markers = {};

  final Color _primaryYellow = const Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9); // Shows a preview of next card
    _buildMarkers();
  }

  void _buildMarkers() {
    _markers = widget.shops.map((shop) {
      int index = widget.shops.indexOf(shop);
      return Marker(
        markerId: MarkerId(shop.id.toString()),
        position: LatLng(shop.latitude ?? 0, shop.longitude ?? 0),
        onTap: () {
          // When marker is tapped, scroll the PageView to the correct card
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
      );
    }).toSet();
  }

  // Move the map camera when a user swipes to a new card
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    final shop = widget.shops[index];
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(shop.latitude ?? 0, shop.longitude ?? 0),
          zoom: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. THE MAP
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.shops.isNotEmpty ? widget.shops[0].latitude! : 0,
                widget.shops.isNotEmpty ? widget.shops[0].longitude! : 0,
              ),
              zoom: 15,
            ),
            onMapCreated: (controller) => mapController = controller,
            markers: _markers,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // 2. TOP NAVIGATION BAR (CANCEL / SEARCH / LIST)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  right: 16,
                  bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text("Cancel",
                        style: TextStyle(color: _primaryYellow, fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                  const Text(
                    "SELECT STORE",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                  ),
                  Row(
                    children: [
                      Icon(Icons.search, color: _primaryYellow, size: 28),
                      const SizedBox(width: 15),
                      Icon(Icons.list, color: _primaryYellow, size: 28),
                    ],
                  )
                ],
              ),
            ),
          ),

          // 3. BOTTOM UI (MY LOCATION + HORIZONTAL CARDS + SELECT BUTTON)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location Button (aligned to right)
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: () {
                        if (widget.initialPosition != null) {
                          mapController.animateCamera(CameraUpdate.newLatLng(
                            LatLng(widget.initialPosition!.latitude, widget.initialPosition!.longitude),
                          ));
                        }
                      },
                      child: const Icon(Icons.my_location, color: Colors.black87),
                    ),
                  ),
                ),

                // HORIZONTAL SCROLLING SHOP CARDS
                SizedBox(
                  height: 135, // Adjust height
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.shops.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _buildShopCard(widget.shops[index]),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // SELECT STORE BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        final currentShop = widget.shops[_currentIndex];
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => GuestMenuScreen(shopId: currentShop.id)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryYellow,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: const Text(
                        "SELECT STORE",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
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

  Widget _buildShopCard(Shop shop) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 90,
              height: 90,
              color: Colors.grey[200],
              child: (shop.imageUrl != null && shop.imageUrl!.isNotEmpty)
                  ? Image.network(shop.imageUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.store, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          // Shop Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            shop.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        Text(
                          "${shop.distanceInKm?.toStringAsFixed(2)} km",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            shop.location ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "${shop.openTime} - ${shop.closeTime}",
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const Text(
                      "View >",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}