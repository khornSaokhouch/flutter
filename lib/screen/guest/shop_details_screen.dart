// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart'; // Add this to pubspec.yaml if you want map launching working
// import '../../models/shop.dart';
// import '../../server/shop_serviec.dart';

// class ShopDetailsScreen extends StatefulWidget {
//   final int shopId;

//   const ShopDetailsScreen({super.key, required this.shopId});

//   @override
//   State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
// }

// class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
//   late Future<Shop?> _shopFuture;

//   // Theme Colors (Matches your AppTheme)
//   final Color _primaryColor = const Color(0xFF4B2C20); // Espresso Brown
//   final Color _greenColor = const Color(0xFF4E8D7C);   // Fresh Mint

//   @override
//   void initState() {
//     super.initState();
//     _shopFuture = ShopService.fetchShopById(widget.shopId);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: FutureBuilder<Shop?>(
//         future: _shopFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (!snapshot.hasData || snapshot.data == null) {
//             return const Center(child: Text('Shop not found.'));
//           }

//           final shop = snapshot.data!;
//           final bool isOpen = shop.status == 1;

//           return Stack(
//             children: [
//               CustomScrollView(
//                 slivers: [
//                   // 1. Large Collapsing Header Image
//                   SliverAppBar(
//                     expandedHeight: 280.0,
//                     pinned: true,
//                     backgroundColor: _primaryColor,
//                     leading: Container(
//                       margin: const EdgeInsets.all(8),
//                       decoration: const BoxDecoration(
//                         color: Colors.white,
//                         shape: BoxShape.circle,
//                       ),
//                       child: IconButton(
//                         icon: const Icon(Icons.arrow_back, color: Colors.black),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                     ),
//                     flexibleSpace: FlexibleSpaceBar(
//                       background: _buildHeaderImage(shop.imageUrl),
//                     ),
//                   ),

//                   // 2. The Content Body
//                   SliverToBoxAdapter(
//                     child: Container(
//                       transform: Matrix4.translationValues(0.0, -24.0, 0.0), // Overlap effect
//                       decoration: const BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.only(
//                           topLeft: Radius.circular(30),
//                           topRight: Radius.circular(30),
//                         ),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(24.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // Drag Handle (Visual cue)
//                             Center(
//                               child: Container(
//                                 width: 40,
//                                 height: 5,
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey[300],
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 20),

//                             // Shop Name & Status Badge
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Expanded(
//                                   child: Text(
//                                     shop.name,
//                                     style: TextStyle(
//                                       fontSize: 26,
//                                       fontWeight: FontWeight.bold,
//                                       color: _primaryColor,
//                                       height: 1.1,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 _buildStatusBadge(isOpen),
//                               ],
//                             ),
                            
//                             const SizedBox(height: 24),
//                             const Divider(height: 1),
//                             const SizedBox(height: 24),

//                             // Location Section
//                             const Text(
//                               "Location",
//                               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                             ),
//                             const SizedBox(height: 12),
//                             Row(
//                               children: [
//                                 Container(
//                                   padding: const EdgeInsets.all(10),
//                                   decoration: BoxDecoration(
//                                     color: Colors.orange.shade50,
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Icon(Icons.location_on, color: Colors.orange.shade800),
//                                 ),
//                                 const SizedBox(width: 16),
//                                 Expanded(
//                                   child: Text(
//                                     shop.location ?? "Address not available",
//                                     style: const TextStyle(fontSize: 15, color: Colors.black87),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 12),
//                             // Map Button
//                             if (shop.googleMapUrl != null)
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: OutlinedButton.icon(
//                                   onPressed: () {
//                                     // Open Map Logic
//                                     _launchMap(shop.googleMapUrl!);
//                                   },
//                                   icon: const Icon(Icons.map_outlined, size: 18),
//                                   label: const Text("Open in Google Maps"),
//                                   style: OutlinedButton.styleFrom(
//                                     foregroundColor: Colors.black,
//                                     side: BorderSide(color: Colors.grey.shade300),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                   ),
//                                 ),
//                               ),

//                             const SizedBox(height: 24),

//                             // Time Section
//                             const Text(
//                               "Opening Hours",
//                               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                             ),
//                             const SizedBox(height: 12),
//                             _buildInfoRow(
//                               Icons.access_time_filled,
//                               Colors.blue.shade50,
//                               Colors.blue.shade700,
//                               "Schedule",
//                               (shop.openTime != null && shop.closeTime != null)
//                                   ? "${shop.openTime} - ${shop.closeTime}"
//                                   : "Hours not listed",
//                             ),

//                             const SizedBox(height: 24),

//                             // Owner Section (Optional)
//                             if (shop.owner.name.isNotEmpty) ...[
//                               const Text(
//                                 "Store Manager",
//                                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                               ),
//                               const SizedBox(height: 12),
//                               ListTile(
//                                 contentPadding: EdgeInsets.zero,
//                                 leading: CircleAvatar(
//                                   radius: 24,
//                                   backgroundColor: Colors.grey[200],
//                                   backgroundImage: (shop.owner.profileImage != null)
//                                       ? NetworkImage(shop.owner.profileImage!)
//                                       : null,
//                                   child: (shop.owner.profileImage == null)
//                                       ? const Icon(Icons.person, color: Colors.grey)
//                                       : null,
//                                 ),
//                                 title: Text(
//                                   shop.owner.name,
//                                   style: const TextStyle(fontWeight: FontWeight.w600),
//                                 ),
//                                 subtitle: const Text("Verified Owner"),
//                               ),
//                             ],
                            
//                             // Extra padding for bottom button space
//                             const SizedBox(height: 80),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               // 3. Sticky Bottom Button
//               Positioned(
//                 bottom: 0,
//                 left: 0,
//                 right: 0,
//                 child: Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         blurRadius: 10,
//                         offset: const Offset(0, -5),
//                       ),
//                     ],
//                   ),
//                   child: ElevatedButton(
//                     onPressed: isOpen 
//                       ? () {
//                           // Navigate to Menu or Order Screen
//                         }
//                       : null, // Disable if closed
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _primaryColor,
//                       disabledBackgroundColor: Colors.grey[300],
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       elevation: 0,
//                     ),
//                     child: Text(
//                       isOpen ? "View Menu & Order" : "Store is Closed",
//                       style: TextStyle(
//                         fontSize: 18, 
//                         fontWeight: FontWeight.bold,
//                         color: isOpen ? Colors.white : Colors.grey[600],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   // --- Helper Widgets ---

//   Widget _buildHeaderImage(String? url) {
//     if (url != null && url.isNotEmpty) {
//       return Image.network(
//         url,
//         fit: BoxFit.cover,
//         errorBuilder: (_, __, ___) => _placeholderHeader(),
//       );
//     }
//     return _placeholderHeader();
//   }

//   Widget _placeholderHeader() {
//     return Container(
//       color: Colors.grey[200],
//       child: Center(
//         child: Icon(Icons.store_mall_directory_rounded, size: 60, color: Colors.grey[400]),
//       ),
//     );
//   }

//   Widget _buildStatusBadge(bool isOpen) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: isOpen ? _greenColor.withOpacity(0.1) : Colors.red.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: isOpen ? _greenColor.withOpacity(0.5) : Colors.red.withOpacity(0.5),
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.circle,
//             size: 8,
//             color: isOpen ? _greenColor : Colors.red,
//           ),
//           const SizedBox(width: 6),
//           Text(
//             isOpen ? "OPEN" : "CLOSED",
//             style: TextStyle(
//               color: isOpen ? _primaryColor : Colors.red,
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//               letterSpacing: 0.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoRow(IconData icon, Color bgColor, Color iconColor, String title, String content) {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: bgColor,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Icon(icon, color: iconColor),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 content,
//                 style: const TextStyle(
//                   fontSize: 15,
//                   color: Colors.black87,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

// //   Future<void> _launchMap(String url) async {
// //     final uri = Uri.parse(url);
// //     if (await canLaunchUrl(uri)) {
// //       await launchUrl(uri);
// //     } else {
// //       // Handle error
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Could not open map.')),
// //       );
// //     }
// //   }
// // }