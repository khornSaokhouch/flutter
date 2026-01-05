import 'package:flutter/material.dart';
import '../../../server/shops_server/shop_option_service.dart';

class InlineOptionGroup extends StatelessWidget {
  final Map<String, dynamic> group;
  final bool itemActive;
  final Map<int, bool> groupExpanded;
  final bool isToggling;
  final void Function(int gid) onToggleGroupExpand;
  final Future<void> Function(Map<String, dynamic> option, bool newStatus)? onToggleOptionActive;

  final int Function(dynamic) toCents;
  final String Function(int) fmt;
  final bool Function(dynamic) isOptionActive;
  final bool Function(dynamic) toBool;

  // Theme
  final Color _primaryGreen = const Color(0xFF4E8D7C);
  final Color _darkText = const Color(0xFF4B2C20); // Matched espresso brown

  const InlineOptionGroup({
    super.key,
    required this.group,
    required this.itemActive,
    required this.groupExpanded,
    required this.isToggling,
    required this.onToggleGroupExpand,
    this.onToggleOptionActive,
    required this.toCents,
    required this.fmt,
    required this.isOptionActive,
    required this.toBool,
  });

  int _safeId(dynamic v) {
    if (v == null) return -1;
    if (v is int) return v;
    if (v is double) return v.toInt();
    final s = v.toString();
    final n = int.tryParse(s);
    if (n != null) return n;
    return -1;
  }

  String _safeString(dynamic v) => v == null ? '' : v.toString();

  @override
  Widget build(BuildContext context) {
    final gid = _safeId(group['id']);
    final expanded = groupExpanded[gid] ?? true;
    final requiredFlag = (group['is_required'] ?? 0).toString() == '1' || toBool(group['is_required']);
    final options = (group['options'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB), // Very slight grey for contrast against white page
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => onToggleGroupExpand(gid),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Icon(Icons.layers_outlined, size: 20, color: _primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          _safeString(group['name']),
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _darkText),
                        ),
                        if (requiredFlag)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(4)),
                            child: const Text('Required', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, 
                    color: Colors.grey[400]
                  ),
                ],
              ),
            ),
          ),
          
          if (expanded) ...[
            Divider(height: 1, color: Colors.grey[200]),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                children: options.map((o) {
                  final optionIsActive = isOptionActive(o['is_active']);
                  final available = optionIsActive && itemActive;
                  final adjCents = toCents(o['price_adjust_cents']) ~/ 100;
                  final iconUrl = _safeString(o['icon_url']);
                  final statusId = o['status_id'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
                      ]
                    ),
                    child: Row(
                      children: [
                        // Option Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 42, height: 42,
                            color: Colors.grey[100],
                            child: iconUrl.isNotEmpty
                              ? ColorFiltered(
                                  colorFilter: available 
                                    ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                                    : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                                  child: Image.network(iconUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const SizedBox()),
                                )
                              : Icon(Icons.restaurant_menu, size: 18, color: Colors.grey[300]),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Text Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _safeString(o['name']),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: available ? Colors.black87 : Colors.grey,
                                ),
                              ),
                              if(adjCents > 0 || !available) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if(adjCents > 0)
                                      Text(
                                        "+${fmt(adjCents)}", 
                                        style: TextStyle(fontSize: 12, color: available ? _primaryGreen : Colors.grey, fontWeight: FontWeight.bold)
                                      ),
                                    if(!available) ...[
                                      if(adjCents > 0) const SizedBox(width: 6),
                                      const Text("Inactive", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    ]
                                  ],
                                ),
                              ]
                            ],
                          ),
                        ),

                        // Switch
                        Transform.scale(
                          scale: 0.75,
                          child: Switch(
                            value: optionIsActive,
                            activeColor: Colors.white,
                            activeTrackColor: _primaryGreen,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Colors.grey[200],
                            trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
                            onChanged: (onToggleOptionActive != null && itemActive && !isToggling && statusId != null)
                                ? (val) async {
                                    await ShopItemOptionStatusService.updateStatus(statusId, val);
                                    onToggleOptionActive?.call(o, val);
                                  }
                                : null,
                          ),
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ]
        ],
      ),
    );
  }
}