import 'package:flutter/material.dart';
import 'package:frontend/models/item_option_group.dart';

import '../../../server/shops_server/shop_option_service.dart';
import '../widgets/add_option_sheet.dart';
import '../widgets/inline_option_group.dart';

class ShopProductDetailPage extends StatefulWidget {
  final int itemId;
  final int shopId;

  const ShopProductDetailPage({
    super.key,
    required this.itemId,
    required this.shopId,
  });

  @override
  State<ShopProductDetailPage> createState() => _ShopProductDetailPageState();
}

class _ShopProductDetailPageState extends State<ShopProductDetailPage> {
  bool _isToggling = false;
  bool _isLoading = true;

  List<ShopItemOptionStatusModel> statuses = [];

  // UI state
  final Map<int, bool> _groupExpanded = {};

  // Theme Colors (Kept your original green)
  final Color _primaryGreen = const Color(0xFF4E8D7C);
  final Color _bgWhite = const Color(0xFFFFFFFF);
  final Color _espressoBrown = const Color(0xFF4B2C20); // From reference for text contrast

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- Helpers ---
  int _toCents(dynamic priceStr) {
    if (priceStr == null) return 0;
    final s = priceStr.toString();
    if (s.contains('.')) {
      final d = double.tryParse(s) ?? 0.0;
      return (d * 100).round();
    }
    final n = int.tryParse(s);
    return n ?? 0;
  }

  String _fmt(int cents) => "\$${(cents / 100).toStringAsFixed(2)}";

  bool _toBool(dynamic v) {
    if (v == null) return true;
    if (v is bool) return v;
    if (v is int) return v == 1;
    final s = v.toString().toLowerCase();
    if (["1", "true", "yes", "on"].contains(s)) return true;
    if (["0", "false", "no", "off"].contains(s)) return false;
    return true;
  }

  bool _isOptionActive(dynamic v) => _toBool(v);


  void _toggleGroupExpand(int gid) {
    setState(() => _groupExpanded[gid] = !(_groupExpanded[gid] ?? true));
  }

  List<Map<String, dynamic>> _buildGroupsFromStatuses() {
    int normalizeStatus(dynamic s) {
      if (s == null) return 0;
      if (s is bool) return s ? 1 : 0;
      if (s is num) return s == 1 ? 1 : 0;
      final str = s.toString().toLowerCase();
      if (str == '1' || str == 'true' || str == 'yes' || str == 'on') return 1;
      return 0;
    }

    final Map<int, Map<String, dynamic>> groups = {};

    for (final s in statuses) {
      final og = s.optionGroup;
      final o = s.option;

      final gid = og.id;
      final oid = o.id;

      groups.putIfAbsent(gid, () {
        return {
          'id': gid,
          'name': og.name,
          'type': og.type,
          'is_required': og.isRequired ? 1 : 0,
          'options': <Map<String, dynamic>>[],
        };
      });

      final shopStatusInt = normalizeStatus(s.status);
      final mapped = {
        'id': oid,
        'item_option_group_id': o.itemOptionGroupId,
        'name': o.name,
        'icon': o.icon_url,
        'is_active': shopStatusInt,
        'price_adjust_cents': o.priceAdjustCents,
        'icon_url': o.icon_url,
        'status_id': s.id,
      };

      final opts = groups[gid]!['options'] as List;
      if (!opts.any((x) => (x['id'] as num).toInt() == oid)) {
        opts.add(mapped);
      }
    }

    final result = groups.values.map((g) {
      final opts = (g['options'] as List).cast<Map<String, dynamic>>();
      opts.sort((a, b) => (a['id'] as num).compareTo(b['id'] as num));
      return g;
    }).toList();

    result.sort((a, b) => (a['id'] as num).compareTo(b['id'] as num));
    return result;
  }

  Future<void> _handleToggleOptionActive(Map<String, dynamic> option, bool newStatus) async {
    setState(() => _isToggling = true);
    try {
      final oid = (option['id'] as num).toInt();
      for (final s in statuses) {
        if (s.option.id == oid) {
          s.option.isActive = newStatus;
          s.status = newStatus;
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error toggling option active: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  void _showAddOptionSheet() async {
    final existingOptionIds = statuses.map((s) => s.option.id).toSet();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddOptionSheet(
        onSelect: (_, __) {},
        itemId: widget.itemId,
        shopId: widget.shopId,
        existingOptionIds: existingOptionIds,
      ),
    );
    if (ok == true) await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final loaded = await ShopItemOptionStatusService.getStatuses(widget.itemId, widget.shopId);
      statuses = List<ShopItemOptionStatusModel>.from(loaded);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Failed to load options: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load options: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _buildGroupsFromStatuses();
    
    final hasData = statuses.isNotEmpty;
    final itemName = hasData ? statuses.first.item.name : '...';
    final itemDesc = hasData ? statuses.first.item.description : '';
    final imageUrl = hasData ? statuses.first.item.imageUrl : '';
    final isItemAvailable = hasData ? statuses.first.item.isAvailable : false;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bgWhite,
        body: Center(child: CircularProgressIndicator(color: _primaryGreen)),
      );
    }

    return Scaffold(
      backgroundColor: _bgWhite,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. IMMERSIVE HEADER IMAGE
              SliverAppBar(
                expandedHeight: 300.0,
                pinned: true,
                stretch: true,
                backgroundColor: _espressoBrown,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      (imageUrl.isNotEmpty)
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: Icon(Icons.image, color: Colors.grey[400])),
                            )
                          : Container(color: Colors.grey[200], child: Icon(Icons.image, color: Colors.grey[400])),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black26, Colors.transparent, Colors.black12],
                            stops: [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. PRODUCT INFO (Curved Container)
              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0.0, -30.0, 0.0),
                  decoration: BoxDecoration(
                    color: _bgWhite,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            width: 40, height: 4,
                            margin: const EdgeInsets.only(bottom: 20, top: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        
                        // Title
                        Text(
                        itemName,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _espressoBrown,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // // Description under name
                      if (itemDesc.isNotEmpty)
                        Text(
                          itemDesc,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),

                      const SizedBox(height: 12),
                        
                        // Availability Pill
                        _buildStatusPill(isItemAvailable),
                        
                        const SizedBox(height: 12),
                   
                        const SizedBox(height: 24),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 24),

                        const Text(
                          "Options & Modifiers",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. OPTION GROUPS
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final g = groups[index];
                    return Container(
                      color: _bgWhite, // Continues the white bg
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: InlineOptionGroup(
                          group: Map<String, dynamic>.from(g),
                          itemActive: isItemAvailable,
                          groupExpanded: _groupExpanded,
                          isToggling: _isToggling,
                          onToggleGroupExpand: _toggleGroupExpand,
                          onToggleOptionActive: _handleToggleOptionActive,
                          toCents: _toCents,
                          fmt: _fmt,
                          isOptionActive: _isOptionActive,
                          toBool: _toBool,
                        ),
                      ),
                    );
                  },
                  childCount: groups.length,
                ),
              ),

              // Padding for Bottom Bar
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),

          // 4. STICKY BOTTOM BAR
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -5)),
                ],
              ),
              child: Row(
                children: [
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Total Groups", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        "${groups.length}",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _espressoBrown),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showAddOptionSheet,
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: const Text("Add Option", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable ? _primaryGreen.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: isAvailable ? _primaryGreen : Colors.red),
          const SizedBox(width: 6),
          Text(
            isAvailable ? "Available" : "Unavailable",
            style: TextStyle(
              color: isAvailable ? _primaryGreen : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}