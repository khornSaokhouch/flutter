import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; 

class LocationPickerPage extends StatefulWidget {
  final LatLng initialCenter;

  const LocationPickerPage({super.key, required this.initialCenter});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late MapController _mapController;
  late LatLng _currentCenter;
  final Color _primaryGreen = const Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentCenter = widget.initialCenter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Shop Location", 
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. THE MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 16.0,
              onPositionChanged: (position, hasGesture) {
                _currentCenter = position.center!;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.drinkingcoffee.frontend',
              ),
            ],
          ),

          // 2. FIXED CENTER PIN (The user moves the map under this pin)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40), // Adjust so tip points to center
              child: Icon(Icons.location_on_rounded, color: _primaryGreen, size: 50),
            ),
          ),

          // 3. CONFIRM BUTTON
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _currentCenter),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("CONFIRM THIS LOCATION", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ),

          // 4. ZOOM CONTROLS
          Positioned(
            right: 20,
            top: 20,
            child: Column(
              children: [
                _buildMapAction(Icons.add, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
                const SizedBox(height: 10),
                _buildMapAction(Icons.remove, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMapAction(IconData icon, VoidCallback tap) {
    return FloatingActionButton(
      heroTag: icon.toString(),
      mini: true,
      backgroundColor: Colors.white,
      onPressed: tap,
      child: Icon(icon, color: _primaryGreen),
    );
  }
}