// lib/widgets/inline_option_group.dart
import 'package:flutter/material.dart';
import '../../../server/shops_server/shop_option_service.dart';

/// Row-style option group widget (defensive, null-safe helpers).
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

  // helpers forwarded into the widget (optional formatting functions)
  final int Function(dynamic) toCents;
  final String Function(int) fmt;
  final bool Function(dynamic) isOptionActive;
  final bool Function(dynamic) toBool;

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
    final d = double.tryParse(s);
    if (d != null) return d.toInt();
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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Column(
        children: [
          // Header
          ListTile(
            title: Row(
              children: [
                Text(_safeString(group['name']), style: const TextStyle(fontWeight: FontWeight.bold)),
                if (requiredFlag) const Text(' *', style: TextStyle(color: Colors.red)),
              ],
            ),
            trailing: Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
            onTap: () => onToggleGroupExpand(gid),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),

          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: options.map((o) {
                  final oid = _safeId(o['id']);

                  // optionIsActive is shop-level status (0/1 or bool)
                  final optionIsActive = isOptionActive(o['is_active']);
                  final available = optionIsActive && itemActive;

                  final adjCents = toCents(o['price_adjust_cents']);
                  final priceLabel = adjCents == 0 ? '' : '(+${fmt(adjCents)})';
                  final isSelected = (groupType == 'select')
                      ? (selectedOptionForGroup[gid] == oid)
                      : (selectedOptionSets[gid]?.contains(oid) ?? false);
                  final iconUrl = _safeString(o['icon_url']);
                  final hasIcon = iconUrl.isNotEmpty;

                  final statusId = o['status_id']; // MUST exist (set by parent)

                  return Container(
                    key: ValueKey('option-${gid.toString()}-$oid'),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Material(
                      color: isSelected ? Colors.brown.withOpacity(0.04) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isSelected ? Colors.brown : Colors.grey.shade200, width: isSelected ? 2 : 1),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: available ? () => onToggleOption(group, o) : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              // Icon or placeholder
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: hasIcon
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    iconUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)));
                                    },
                                    errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                                  ),
                                )
                                    : const Center(child: Icon(Icons.circle_outlined, size: 18, color: Colors.grey)),
                              ),

                              const SizedBox(width: 12),

                              // Title + subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      available ? _safeString(o['name']) : '${_safeString(o['name'])} (N/A)',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? Colors.brown[800] : Colors.black87,
                                        decoration: available ? TextDecoration.none : TextDecoration.lineThrough,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (adjCents > 0)
                                          Text(
                                            priceLabel,
                                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                          )
                                        else
                                          Text(
                                            'No extra charge',
                                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                                          ),
                                        const SizedBox(width: 8),
                                        if (!available)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text('Unavailable', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Selection indicator + status column
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Radio or Checkbox depending on type
                                  Container(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Icon(
                                      groupType == 'select'
                                          ? (isSelected ? Icons.radio_button_checked : Icons.radio_button_off)
                                          : (isSelected ? Icons.check_box : Icons.check_box_outline_blank),
                                      color: isSelected ? Colors.brown : Colors.grey,
                                    ),
                                  ),

                                  // Status: spinner or switch
                                  if (isToggling)
                                    const SizedBox(
                                      width: 36,
                                      height: 24,
                                      child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                                    )
                                  else
                                    Switch(
                                      value: optionIsActive,
                                      activeThumbColor: Colors.white,
                                      activeTrackColor: Colors.brown,
                                      inactiveThumbColor: Colors.white,
                                      inactiveTrackColor: Colors.grey.shade400,
                                      onChanged: (onToggleOptionActive != null &&
                                          itemActive &&
                                          !isToggling &&
                                          statusId != null)
                                          ? (bool newStatus) async {
                                        try {
                                          // API expects bool, not int
                                          await ShopItemOptionStatusService.updateStatus(
                                            statusId,
                                            newStatus,   // <<< FIX HERE
                                          );

                                          // Notify parent so it updates statuses and rebuilds UI
                                          if (onToggleOptionActive != null) {
                                            await onToggleOptionActive!(o, newStatus);
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Failed to update option: $e')),
                                            );
                                          }
                                        }
                                      }
                                          : null,
                                    )

                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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
