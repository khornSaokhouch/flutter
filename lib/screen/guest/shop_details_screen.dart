import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

// --- Imports ---
import '../../models/shop.dart';
import '../../server/shop_serviec.dart';
import '../user/store_screen/menu_Items_list_screen.dart';
import '../../core/widgets/loading/logo_loading.dart'; // ✅ Imported Custom Loading

class ShopDetailsScreen extends StatefulWidget {
  final int shopId;
  final int? userId;

  const ShopDetailsScreen({super.key, required this.shopId, this.userId});

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  late Future<Shop?> _shopFuture;

  // User location
  Position? _userPosition;
  double? _distanceKm; 
  String? _locationError;

  // --- THEME COLORS ---
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _freshMintGreen = const Color(0xFF4E8D7C); 
  final Color _bgWhite = const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _shopFuture = ShopService.fetchShopById(widget.shopId);

    _determinePosition().then((pos) {
      setState(() {
        _userPosition = pos;
      });
    }).catchError((e) {
      setState(() {
        _locationError = e.toString();
      });
    });
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied.';
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
  }

  Future<void> _openMap(Shop shop) async {
    // Map logic here (kept placeholder as per your previous code)
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _computeDistanceIfPossible(Shop shop) {
    if (_userPosition == null) return;
    if (shop.latitude == null || shop.longitude == null) return;

    final meters = Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      shop.latitude!,
      shop.longitude!,
    );

    final km = meters / 1000.0;

    if (_distanceKm == null || (_distanceKm! - km).abs() > 0.001) {
      setState(() {
        _distanceKm = double.parse(km.toStringAsFixed(2));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWhite,
      body: FutureBuilder<Shop?>(
        future: _shopFuture,
        builder: (context, snapshot) {
          
          // 1. ✅ UPDATED LOADING STATE
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LogoLoading(size: 60)); 
          } 
          
          else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Shop not found.'));
          }

          final shop = snapshot.data!;
          final bool isOpen = shop.status == 1;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _computeDistanceIfPossible(shop);
          });

          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. IMMERSIVE HEADER IMAGE
                  SliverAppBar(
                    expandedHeight: 320.0,
                    pinned: true,
                    stretch: true,
                    backgroundColor: _espressoBrown,
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
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [StretchMode.zoomBackground],
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildHeaderImage(shop.imageUrl),
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
                  ),

                  // 2. MAIN CONTENT BODY
                  SliverToBoxAdapter(
                    child: Container(
                      transform: Matrix4.translationValues(0.0, -30.0, 0.0),
                      decoration: BoxDecoration(
                        color: _bgWhite,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 20, top: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    shop.name,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: _espressoBrown,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildStatusPill(isOpen),

                            const SizedBox(height: 24),

                            // QUICK ACTION BUTTONS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildQuickAction(
                                  icon: Icons.map_outlined,
                                  label: "Map",
                                  onTap: () => _openMap(shop),
                                ),
                                _buildQuickAction(
                                  icon: Icons.call_outlined,
                                  label: "Call",
                                  onTap: () {},
                                ),
                                _buildQuickAction(
                                  icon: Icons.share_outlined,
                                  label: "Share",
                                  onTap: () {},
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                            const Divider(height: 1, color: Color(0xFFEEEEEE)),
                            const SizedBox(height: 24),

                            const Text(
                              "Details",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Location Card
                            _buildDetailTile(
                              icon: Icons.location_on_rounded,
                              title: "Address",
                              subtitle: shop.location ?? "Location not available",
                            ),
                            const SizedBox(height: 16),

                            // Time Card
                            _buildDetailTile(
                              icon: Icons.access_time_filled_rounded,
                              title: "Opening Hours",
                              subtitle: (shop.openTime != null && shop.closeTime != null)
                                  ? "${shop.openTime} - ${shop.closeTime}"
                                  : "Hours not listed",
                            ),

                            const SizedBox(height: 24),

                            if (shop.owner.name.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.grey[300],
                                      backgroundImage: (shop.owner.profileImage != null)
                                          ? NetworkImage(shop.owner.profileImage!)
                                          : null,
                                      child: (shop.owner.profileImage == null)
                                          ? const Icon(Icons.person, color: Colors.grey)
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shop.owner.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          "Store Manager",
                                          style: TextStyle(
                                            color: _freshMintGreen,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.verified, color: Colors.blue, size: 20),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 3. STICKY BOTTOM BAR
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Distance",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            _distanceKm != null
                                ? "${_distanceKm!.toStringAsFixed(2)} km"
                                : (shop.distanceInKm != null ? "${shop.distanceInKm!.toStringAsFixed(2)} km" : "— km"),
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _espressoBrown
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isOpen
                              ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MenuScreen(userId: widget.userId ?? 0, shopId: shop.id,)),
                            );
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _freshMintGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            disabledBackgroundColor: Colors.grey[300],
                          ),
                          child: Text(
                            isOpen ? "Order Now" : "Currently Closed",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildHeaderImage(String? url) {
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderHeader(),
      );
    }
    return _placeholderHeader();
  }

  Widget _placeholderHeader() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.store_mall_directory_rounded, size: 60, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildStatusPill(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen ? _freshMintGreen.withOpacity(0.1) : Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              Icons.circle,
              size: 8,
              color: isOpen ? _freshMintGreen : Colors.red
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? "Open Now" : "Closed",
            style: TextStyle(
              color: isOpen ? _freshMintGreen : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: _espressoBrown, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile({required IconData icon, required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _freshMintGreen.withOpacity(0.1), 
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _freshMintGreen, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}