import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/shop.dart'; // Adjust path
import 'guest_menu_Items_list_screen.dart'; // Adjust path

class GuestStoreMapPage extends StatefulWidget {
  final List<Shop> shops;
  final Position? initialPosition;

  const GuestStoreMapPage({super.key, required this.shops, this.initialPosition});

  @override
  State<GuestStoreMapPage> createState() => _GuestStoreMapPageState();
}

class _GuestStoreMapPageState extends State<GuestStoreMapPage> {
  late GoogleMapController mapController;
  Shop? selectedShop;
  Set<Marker> _markers = {};

  final Color _primaryYellow = const Color(0xFFFFC107); // The yellow in the image

  @override
  void initState() {
    super.initState();
    // Default the selected shop to the first one in the list
    if (widget.shops.isNotEmpty) {
      selectedShop = widget.shops.first;
    }
    _buildMarkers();
  }

  void _buildMarkers() {
    setState(() {
      _markers = widget.shops.map((shop) {
        return Marker(
          markerId: MarkerId(shop.id.toString()),
          position: LatLng(shop.latitude ?? 0, shop.longitude ?? 0),
          onTap: () {
            setState(() {
              selectedShop = shop;
            });
          },
        );
      }).toSet();
    });
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
                selectedShop?.latitude ?? widget.initialPosition?.latitude ?? 0,
                selectedShop?.longitude ?? widget.initialPosition?.longitude ?? 0,
              ),
              zoom: 15,
            ),
            onMapCreated: (controller) => mapController = controller,
            markers: _markers,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // 2. CUSTOM TOP BAR
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 16, right: 16, bottom: 10),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel", style: TextStyle(color: _primaryYellow, fontSize: 16)),
                  ),
                  const Text(
                    "SELECT STORE",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Row(
                    children: [
                      Icon(Icons.search, color: _primaryYellow),
                      const SizedBox(width: 15),
                      Icon(Icons.list, color: _primaryYellow),
                    ],
                  )
                ],
              ),
            ),
          ),

          // 3. BOTTOM UI AREA
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // My Location Button
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    if (widget.initialPosition != null) {
                      mapController.animateCamera(CameraUpdate.newLatLng(
                        LatLng(widget.initialPosition!.latitude, widget.initialPosition!.longitude),
                      ));
                    }
                  },
                  child: const Icon(Icons.my_location, color: Colors.black54),
                ),
                const SizedBox(height: 10),

                // SHOP DETAIL CARD
                if (selectedShop != null) _buildShopCard(selectedShop!),

                const SizedBox(height: 15),

                // SELECT STORE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => GuestMenuScreen(shopId: selectedShop!.id)),
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
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 100,
              height: 100,
              color: Colors.grey[200],
              child: shop.imageUrl != null 
                  ? Image.network(shop.imageUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.store),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(5)),
                      child: Text("${shop.distanceInKm?.toStringAsFixed(2)} km", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(shop.location ?? "", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("${shop.openTime} - ${shop.closeTime}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text("View >", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}