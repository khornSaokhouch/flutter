import 'package:flutter/material.dart';
import 'package:frontend/models/Item_OptionGroup.dart';

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

  // Use typed models as source of truth (no dynamic `item` map)
  List<ShopItemOptionStatusModel> statuses = [];

  // UI state
  final Map<int, int> _selectedOptionForGroup = {};
  final Map<int, Set<int>> _selectedOptionSets = {};
  final Map<int, bool> _groupExpanded = {};

  // ----------------------------
  // Helpers (unchanged)
  // ----------------------------
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

  bool get _itemActive {
    return statuses.isNotEmpty ? statuses.first.status : true;
  }

  void _toggleGroupExpand(int gid) {
    setState(() => _groupExpanded[gid] = !(_groupExpanded[gid] ?? true));
  }

  void _toggleOption(Map<String, dynamic> group, Map<String, dynamic> option) {
    if (!_itemActive) return;
    if (!_isOptionActive(option['is_active'])) return;

    final gid = (group['id'] as num).toInt();
    final oid = (option['id'] as num).toInt();
    final type = (group['type'] ?? 'select').toString();

    setState(() {
      if (type == 'select') {
        final already = _selectedOptionForGroup[gid] == oid;
        final required =
            (group['is_required'] ?? 0).toString() == '1' || _toBool(group['is_required']);
        if (already && !required) {
          _selectedOptionForGroup.remove(gid);
        } else {
          _selectedOptionForGroup[gid] = oid;
        }
      } else {
        final set = _selectedOptionSets.putIfAbsent(gid, () => <int>{});
        if (set.contains(oid)) {
          set.remove(oid);
          if (set.isEmpty) _selectedOptionSets.remove(gid);
        } else {
          set.add(oid);
        }
      }
    });
  }

  // Build groups from statuses (source of truth)
  List<Map<String, dynamic>> _buildGroupsFromStatuses() {
    int _normalizeStatus(dynamic s) {
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
      if (og == null || o == null) continue;

      final gid = og.id;
      final oid = o.id;

      groups.putIfAbsent(gid, () {
        return {
          'id': gid,
          'name': og.name,
          'type': og.type ?? 'select',
          'is_required': og.isRequired ? 1 : 0,
          'options': <Map<String, dynamic>>[],
        };
      });

      final shopStatusInt = _normalizeStatus(s.status);
      final mapped = {
        'id': oid,
        'item_option_group_id': o.itemOptionGroupId,
        'name': o.name,
        'icon': o.icon_url,
        'is_active': shopStatusInt,
        'price_adjust_cents': o.priceAdjustCents ?? '0',
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

      // Persist to backend if you have an endpoint:
      // await ShopItemOptionStatusService.updateOptionStatus(widget.itemId, widget.shopId, oid, newStatus);

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error toggling option active: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update option: $e')));
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  // Show add option sheet & reload after success
  void _showAddOptionSheet() async {
    // Collect existing option IDs (already added)
    final existingOptionIds = statuses.map((s) => s.option.id).toSet();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddOptionSheet(
        onSelect: _toggleOption,
        itemId: widget.itemId,
        shopId: widget.shopId,
        existingOptionIds: existingOptionIds,
      ),
    );

    // If sheet returned true, it means we successfully added an option → reload
    if (ok == true) {
      await _loadData();
    }
  }

  // Load statuses from service
  Future<void> _loadData() async {
    try {
      final loaded = await ShopItemOptionStatusService.getStatuses(
        widget.itemId,
        widget.shopId,
      );

      statuses = List<ShopItemOptionStatusModel>.from(loaded);

      if (mounted) setState(() {});
    } catch (e, st) {
      debugPrint('Failed to load option statuses: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load options: $e')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _buildGroupsFromStatuses();
    final title = statuses.isNotEmpty ? statuses.first.item.name : 'Product';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptionSheet,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData, // optional: pull-to-refresh
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (statuses.isNotEmpty) ...[
              if ((statuses.first.item.imageUrl).isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    statuses.first.item.imageUrl,
                    height: 220,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (c, e, s) => Container(
                      height: 220,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                statuses.first.item.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                statuses.first.item.description,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
            ],

            for (final g in groups) ...[
              InlineOptionGroup(
                group: Map<String, dynamic>.from(g),
                itemActive: statuses.isNotEmpty ? statuses.first.item.isAvailable : true,
                selectedOptionForGroup: _selectedOptionForGroup,
                selectedOptionSets: _selectedOptionSets,
                groupExpanded: _groupExpanded,
                isToggling: _isToggling,
                onToggleGroupExpand: _toggleGroupExpand,
                onToggleOption: _toggleOption,
                onToggleOptionActive: _handleToggleOptionActive,
                toCents: _toCents,
                fmt: _fmt,
                isOptionActive: _isOptionActive,
                toBool: _toBool,
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
