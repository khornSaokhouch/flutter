// lib/widgets/inline_option_group.dart
import 'package:flutter/material.dart';
import '../../../server/shops_server/shop_option_service.dart';

class InlineOptionGroup extends StatelessWidget {
  final Map<String, dynamic> group;
  final bool itemActive;
  final Map<int, int> selectedOptionForGroup;
  final Map<int, Set<int>> selectedOptionSets;
  final Map<int, bool> groupExpanded;
  final bool isToggling;
  final void Function(int gid) onToggleGroupExpand;
  final void Function(Map<String, dynamic> g, Map<String, dynamic> o) onToggleOption;
  final Future<void> Function(Map<String, dynamic> option, bool newStatus)? onToggleOptionActive;

  final int Function(dynamic) toCents;
  final String Function(int) fmt;
  final bool Function(dynamic) isOptionActive;
  final bool Function(dynamic) toBool;

  // Theme
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);

  const InlineOptionGroup({
    super.key,
    required this.group,
    required this.itemActive,
    required this.selectedOptionForGroup,
    required this.selectedOptionSets,
    required this.groupExpanded,
    required this.isToggling,
    required this.onToggleGroupExpand,
    required this.onToggleOption,
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
    final groupType = (group['type'] ?? 'select').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => onToggleGroupExpand(gid),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    _safeString(group['name']),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _espressoBrown),
                  ),
                  if (requiredFlag)
                    const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          
          if (expanded) const Divider(height: 1),

          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: options.map((o) {
                  final oid = _safeId(o['id']);
                  final optionIsActive = isOptionActive(o['is_active']);
                  final available = optionIsActive && itemActive;
                  final adjCents = toCents(o['price_adjust_cents']);
                  final priceLabel = adjCents == 0 ? '' : '(+${fmt(adjCents)})';
                  
                  final isSelected = (groupType == 'select')
                      ? (selectedOptionForGroup[gid] == oid)
                      : (selectedOptionSets[gid]?.contains(oid) ?? false);
                  
                  final iconUrl = _safeString(o['icon_url']);
                  final statusId = o['status_id'];

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: available ? Colors.white : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? _freshMintGreen : Colors.grey.shade200, 
                        width: isSelected ? 1.5 : 1
                      ),
                    ),
                    child: Row(
                      children: [
                        // 1. Interactive Selection Area (Left Side)
                        Expanded(
                          child: InkWell(
                            onTap: available ? () => onToggleOption(group, o) : null,
                            child: Row(
                              children: [
                                // Selection Icon
                                Icon(
                                  groupType == 'select'
                                      ? (isSelected ? Icons.radio_button_checked : Icons.radio_button_off)
                                      : (isSelected ? Icons.check_box : Icons.check_box_outline_blank),
                                  color: isSelected ? _freshMintGreen : Colors.grey[400],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                // Image
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                                  child: iconUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(iconUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const SizedBox()),
                                        )
                                      : const Icon(Icons.image_not_supported_outlined, size: 18, color: Colors.grey),
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
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: available ? Colors.black87 : Colors.grey,
                                          decoration: available ? null : TextDecoration.lineThrough,
                                        ),
                                      ),
                                      if(adjCents > 0)
                                        Text(priceLabel, style: TextStyle(fontSize: 12, color: _freshMintGreen, fontWeight: FontWeight.bold))
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 2. Status Toggle (Right Side)
                        // Shows a vertical divider then the switch
                        Container(width: 1, height: 24, color: Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 8)),
                        
                        SizedBox(
                          height: 24,
                          child: Transform.scale(
                            scale: 0.7,
                            child: Switch(
                              value: optionIsActive,
                              activeColor: _espressoBrown,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: Colors.grey[300],
                              onChanged: (onToggleOptionActive != null && itemActive && !isToggling && statusId != null)
                                  ? (bool newStatus) async {
                                      try {
                                        await ShopItemOptionStatusService.updateStatus(statusId, newStatus);
                                        if (onToggleOptionActive != null) {
                                          await onToggleOptionActive!(o, newStatus);
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                                        }
                                      }
                                    }
                                  : null,
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}