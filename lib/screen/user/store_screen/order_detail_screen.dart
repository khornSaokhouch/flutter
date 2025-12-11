import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderDetailScreen({super.key, required this.orderData});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> with SingleTickerProviderStateMixin {
  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- 1. DATA EXTRACTION ---
    final int id = widget.orderData['id'] ?? 0;
    
    // 👇 HERE IS THE SHOP ID / NAME LOGIC
    final int shopId = widget.orderData['shopid'] ?? 0; 
    // If your API returns 'shop_name', use it. Otherwise, fallback to 'Store #ID'
    final String shopName = widget.orderData['shop_name'] ?? 'Store #$shopId'; 

    final double subtotal = (widget.orderData['subtotalcents'] ?? 0) / 100.0;
    final double total = (widget.orderData['totalcents'] ?? 0) / 100.0;
    final List<dynamic> items = widget.orderData['items'] ?? widget.orderData['orderItems'] ?? []; // Handle both keys
    
    final String rawStatus = (widget.orderData['status'] ?? 'placed').toString().toLowerCase();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _freshMintGreen, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              "ORDER DETAILS",
              style: TextStyle(color: _espressoBrown, fontWeight: FontWeight.w800, fontSize: 16),
            ),
            // 👇 Displaying Shop Name in Header
            Text(
              "Pick up at $shopName",
              style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Status Header
                _buildStatusHeader(rawStatus),

                const SizedBox(height: 30),
                Container(height: 8, color: _bgGrey),

                // Details List
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Details", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _bgGrey,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200)
                            ),
                            child: Text("#$id", style: TextStyle(fontWeight: FontWeight.bold, color: _espressoBrown)),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 👇 Showing Shop Name & ID Row
                      _buildInfoRow("Order #", "P-${id.toString().padLeft(5, '0')}"),
                      const SizedBox(height: 8),
                      _buildInfoRow("Store", shopName), 
                      // If you want to show ID explicitly below name:
                      // const SizedBox(height: 8),
                      // _buildInfoRow("Store ID", "#$shopId"), 

                      const SizedBox(height: 24),

                      // Items
                      ...items.map((item) => _buildItemRow(item)).toList(),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(thickness: 1, height: 1),
                      ),

                      // Totals
                      _buildPriceRow("Subtotal", subtotal),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total", style: TextStyle(color: _espressoBrown, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text("\$${total.toStringAsFixed(2)}", style: TextStyle(color: _freshMintGreen, fontSize: 22, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () => _showTrackingSheet(context, rawStatus),
            style: ElevatedButton.styleFrom(
              backgroundColor: _freshMintGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 4,
              shadowColor: _freshMintGreen.withOpacity(0.4),
            ),
            child: const Text("Track Order Status", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: _espressoBrown, fontSize: 15)),
      ],
    );
  }

  // ... (Keep existing _buildStatusHeader, _buildItemRow, _buildPriceRow, _showTrackingSheet) ...
  // Paste the rest of the widgets from the previous response here to keep the code complete.
  
  Widget _buildStatusHeader(String status) {
    String displayStatus = "Order Placed";
    String displayMsg = "Waiting for store confirmation";

    if (status == 'preparing') {
      displayStatus = "Preparing";
      displayMsg = "We are making your drink";
    } else if (status == 'ready') {
      displayStatus = "Ready for Pickup";
      displayMsg = "Head to the counter!";
    } else if (status == 'completed') {
      displayStatus = "Completed";
      displayMsg = "Enjoy your drink!";
    } else if (status == 'cancelled') {
      displayStatus = "Cancelled";
      displayMsg = "This order was cancelled";
    }

    return GestureDetector(
      onTap: () => _showTrackingSheet(context, status),
      child: Column(
        children: [
          Hero(
            tag: 'status_icon',
            child: Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                color: Colors.transparent, 
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _freshMintGreen.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(
                    'assets/images/img_1.png', 
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(displayStatus, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _espressoBrown)),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios, size: 14, color: _freshMintGreen),
            ],
          ),
          const SizedBox(height: 8),
          Text(displayMsg, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildItemRow(dynamic item) {
    String name = item['name'] ?? 'Item';
    String options = item['options'] ?? '';
    double price = (item['price'] is int) ? item['price'] / 100.0 : (item['price'] ?? 0.0);
    int qty = item['qty'] ?? 1;
    String imgUrl = item['image'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${qty}x  ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _espressoBrown)),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imgUrl.isNotEmpty 
                ? Image.network(imgUrl, fit: BoxFit.cover) 
                : Icon(Icons.coffee, color: Colors.grey[400], size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _espressoBrown)),
                if(options.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 2), child: Text(options, style: TextStyle(color: Colors.grey[500], fontSize: 12))),
              ],
            ),
          ),
          Text("\$${(price * qty).toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isTotal ? _espressoBrown : Colors.grey[800], fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, fontSize: isTotal ? 18 : 15)),
        Text("\$${amount.toStringAsFixed(2)}", style: TextStyle(color: isTotal ? _espressoBrown : Colors.grey[800], fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, fontSize: isTotal ? 18 : 15)),
      ],
    );
  }

  void _showTrackingSheet(BuildContext context, String currentStatus) {
    int activeStep = 0;
    if (currentStatus == 'preparing') activeStep = 1;
    if (currentStatus == 'ready') activeStep = 2;
    if (currentStatus == 'completed') activeStep = 3;
    if (currentStatus == 'cancelled') activeStep = -1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const SizedBox(width: 24), Text("TRACKING ORDER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _espressoBrown, letterSpacing: 1.0)), InkWell(onTap: () => Navigator.pop(context), child: CircleAvatar(backgroundColor: Colors.grey[100], radius: 15, child: const Icon(Icons.close, size: 18, color: Colors.grey)))]),
              const SizedBox(height: 30),
              if (currentStatus == 'cancelled')
                 Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.cancel, color: Colors.red), const SizedBox(width: 12), const Expanded(child: Text("This order has been cancelled.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)))]))
              else
                Column(children: [
                  _buildTimelineStep(title: "Order Received", subtitle: "Waiting for store confirmation", stepIndex: 0, currentStep: activeStep, isLast: false),
                  _buildTimelineStep(title: "Order Confirmed", subtitle: "Store is preparing your order", stepIndex: 1, currentStep: activeStep, isLast: false),
                  _buildTimelineStep(title: "Order Ready", subtitle: "Your order is ready to pickup", stepIndex: 2, currentStep: activeStep, isLast: true),
                ]),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineStep({required String title, required String subtitle, required int stepIndex, required int currentStep, required bool isLast}) {
    final bool isCompleted = currentStep >= stepIndex;
    final bool isActive = currentStep == stepIndex;
    return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Column(children: [AnimatedContainer(duration: const Duration(milliseconds: 300), width: 28, height: 28, decoration: BoxDecoration(color: isCompleted ? _freshMintGreen : Colors.white, shape: BoxShape.circle, border: isCompleted ? null : Border.all(color: Colors.grey[300]!, width: 2), boxShadow: isActive ? [BoxShadow(color: _freshMintGreen.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))] : []), child: isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : null), if (!isLast) Expanded(child: Container(width: 4, color: isCompleted ? _freshMintGreen : Colors.grey[200], margin: const EdgeInsets.symmetric(vertical: 4)))]), const SizedBox(width: 16), Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 32.0, top: 2), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isCompleted ? _espressoBrown : Colors.black)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500]))]))) ]));
  }
}