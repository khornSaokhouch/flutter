import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../server/order_service.dart';
import '../user/store_screen/order_detail_screen.dart'; // ✅ Imported your detail screen

class AllOrdersScreen extends StatefulWidget {
  final int userId;

  const AllOrdersScreen({required this.userId, super.key});

  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  // UI state
  bool _isLoading = true;
  String? _error;
  List<OrderModel> _orders = [];

  // Filter State
  String _searchQuery = '';
  List<String> _selectedStatuses = [];

  final _currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await OrderService.fetchAllOrders(userid: widget.userId);
      // Sort by latest first
      orders.sort((a, b) {
        final dA = DateTime.tryParse(a.placedat ?? '') ?? DateTime(0);
        final dB = DateTime.tryParse(b.placedat ?? '') ?? DateTime(0);
        return dB.compareTo(dA);
      });
      setState(() {
        _orders = orders;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ Updated Filter Logic: Searches ID, Shop ID, and ITEM NAMES
  List<OrderModel> get _filteredOrders {
    final q = _searchQuery.toLowerCase().trim();

    return _orders.where((o) {
      // 1. Search Filter
      final matchesId = o.id?.toString().contains(q) ?? false;
      final matchesShop = o.shopid?.toString().contains(q) ?? false;
      
      // Check if ANY item in the order matches the search name
      final matchesItemName = o.orderItems.any((item) => 
          item.namesnapshot.toLowerCase().contains(q)
      );

      final matchesSearch = q.isEmpty || matchesId || matchesShop || matchesItemName;

      // 2. Status Filter
      final matchesStatus = _selectedStatuses.isEmpty ||
          _selectedStatuses.contains(o.status.toLowerCase());

      return matchesSearch && matchesStatus;
    }).toList();
  }

  // --- Formatters ---
  String _formatMoney(int cents) {
    return _currencyFormatter.format(cents / 100.0);
  }

  String _formatPlacedAt(String? placedAtRaw) {
    if (placedAtRaw == null || placedAtRaw.trim().isEmpty) return '—';
    try {
      DateTime? dt = DateTime.tryParse(placedAtRaw);
      if (dt == null) return placedAtRaw;
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dt.toLocal());
    } catch (_) {
      return placedAtRaw;
    }
  }

  // --- Filter Bottom Sheet ---
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Filter Orders", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _espressoBrown)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(height: 30),
                  const Text("Order Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: ['placed', 'preparing', 'ready', 'completed', 'cancelled'].map((status) {
                      final isSelected = _selectedStatuses.contains(status);
                      return ChoiceChip(
                        label: Text(status[0].toUpperCase() + status.substring(1)),
                        selected: isSelected,
                        selectedColor: _freshMintGreen.withValues(alpha: 0.2),
                        backgroundColor: Colors.grey[100],
                        labelStyle: TextStyle(
                          color: isSelected ? _freshMintGreen : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              _selectedStatuses.add(status);
                            } else {
                              _selectedStatuses.remove(status);
                            }
                          });
                          this.setState(() {}); // Update main screen
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _freshMintGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Apply Filters", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() => _selectedStatuses.clear());
                        setModalState(() {});
                      },
                      child: const Text("Clear Filters", style: TextStyle(color: Colors.grey)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "ORDER HISTORY",
          style: TextStyle(
            color: _espressoBrown,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            fontSize: 16,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[100], height: 1),
        ),
      ),
      body: Column(
        children: [
          // 1. Search & Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _bgGrey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: "Search order #, shop, or item...",
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _showFilterSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: _selectedStatuses.isNotEmpty
                          ? _freshMintGreen
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _selectedStatuses.isNotEmpty ? _freshMintGreen : Colors.grey.shade300
                      ),
                    ),
                    child: Icon(
                        Icons.tune_rounded,
                        color: _selectedStatuses.isNotEmpty ? Colors.white : Colors.grey[600]
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Content
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isLoading) {
                  return Center(child: CircularProgressIndicator(color: _freshMintGreen));
                }

                if (_error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Failed to load orders', style: TextStyle(fontSize: 16, color: _espressoBrown, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadOrders,
                          style: ElevatedButton.styleFrom(backgroundColor: _freshMintGreen),
                          child: const Text('Retry'),
                        )
                      ],
                    ),
                  );
                }

                final list = _filteredOrders;

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _bgGrey,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.receipt_long_rounded, size: 60, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 24),
                        Text("No orders found", style: TextStyle(color: _espressoBrown, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text("Try adjusting your search or filters", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: _freshMintGreen,
                  onRefresh: _loadOrders,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, idx) {
                      return _buildOrderCard(list[idx]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildOrderCard(OrderModel order) {
    // 1. Define Status Logic
    final bool isCompleted = order.status.toLowerCase() == "completed";
    final bool isCancelled = order.status.toLowerCase() == "cancelled";

    Color statusColor = Colors.orange;
    Color statusBg = Colors.orange.withValues(alpha: 0.1);
    IconData statusIcon = Icons.access_time_rounded;

    if (isCompleted) {
      statusColor = _freshMintGreen;
      statusBg = _freshMintGreen.withValues(alpha: 0.1);
      statusIcon = Icons.check_circle_rounded;
    } else if (isCancelled) {
      statusColor = Colors.red;
      statusBg = Colors.red.withValues(alpha: 0.1);
      statusIcon = Icons.cancel_rounded;
    }

    // 2. Prepare Data for Display
    final orderId = order.id != null ? '#${order.id}' : '#--';

    // Use shop model when available (fall back to id)
    final shop = order.shop;
    final shopName = shop?.name ?? (order.shopid != null ? 'Shop #${order.shopid}' : 'Unknown Shop');

    // Show summary of items
    final itemsSummary = order.orderItems.isNotEmpty
        ? order.orderItems.map((i) => "${i.quantity}x ${i.namesnapshot}").join(", ")
        : "No items";

    final dateStr = _formatPlacedAt(order.placedat);
    final String priceStr = _formatMoney(order.totalcents);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Build safe orderDataMap for details screen
            final orderDataMap = {
              'id': order.id,
              'userid': order.userid,
              'status': order.status,
              'placedat': order.placedat,
              'subtotalcents': order.subtotalcents,
              'discountcents': order.discountcents,
              'totalcents': order.totalcents,
              'subtotal': (order.subtotalcents / 100.0),
              'discount': (order.discountcents / 100.0),
              'total': (order.totalcents / 100.0),
              'shop_id': order.shopid,
              'shop_name': shopName,
              'shop_address': shop?.location,
              'shop_image': shop?.imageUrl,
              'items': order.orderItems.map((item) {
                final imageUrl = item.item?.imageUrl ?? '';
                final optionsText = (item.optionGroups.isNotEmpty)
                    ? item.optionGroups
                    .map((g) => g.selectedOption)
                    .where((s) => s.isNotEmpty)
                    .join(', ')
                    : '';
                return {
                  'id': item.id,
                  'itemid': item.itemid,
                  'name': item.namesnapshot,
                  'image': imageUrl,
                  'qty': item.quantity,
                  'unitprice_cents': item.unitpriceCents,
                  'unitprice': item.unitpriceCents / 100.0,
                  'line_total_cents': item.unitpriceCents * item.quantity,
                  'line_total': (item.unitpriceCents * item.quantity) / 100.0,
                  'options': optionsText,
                  'notes': item.notes,
                };
              }).toList(),
            };

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(orderData: orderDataMap),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Shop Name & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        shopName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _espressoBrown),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            order.status.toUpperCase(),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Middle: Order Items Summary
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: _bgGrey, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.receipt_long_rounded, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            itemsSummary,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Bottom: Date & Price & Reorder
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        const SizedBox(height: 2),
                        Text(priceStr, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _freshMintGreen)),
                      ],
                    ),

                    if (isCompleted)
                      OutlinedButton.icon(
                        onPressed: () {
                          // Implement Reorder Logic here
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text("Reorder"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _espressoBrown,
                          side: BorderSide(color: _espressoBrown.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      )
                    else
                      Text(
                        dateStr,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}