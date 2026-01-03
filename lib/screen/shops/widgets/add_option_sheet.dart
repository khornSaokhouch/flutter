import 'package:flutter/material.dart';
import '../../../models/shops_models/shop_options_model.dart';
import '../../../server/shops_server/shop_option_service.dart';

typedef OptionSelectCallback = void Function(Map<String, dynamic> group, Map<String, dynamic> option);

class AddOptionSheet extends StatefulWidget {
  final OptionSelectCallback onSelect;
  final VoidCallback? onDone;
  final int itemId;
  final int shopId;
  final Set<int> existingOptionIds;

  const AddOptionSheet({
    super.key,
    required this.onSelect,
    this.onDone,
    required this.itemId,
    required this.shopId,
    required this.existingOptionIds,
  });

  @override
  State<AddOptionSheet> createState() => _AddOptionSheetState();
}

class _AddOptionSheetState extends State<AddOptionSheet> {
  late Future<ShopOptions> futureItem;
  bool _isSubmitting = false;
  
  // Track selected options: Map<optionId, {group, option}>
  final Map<int, Map<String, dynamic>> _selectedOptions = {};

  final Color _primaryGreen = const Color(0xFF4E8D7C);
  final Color _darkText = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    futureItem = ShopItemOptionStatusService.getItemDetails(widget.itemId);
  }

  // --- LOGIC HELPERS ---
  bool isOptionActive(dynamic v) => v == 1 || v == true;

  int toCents(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return (v * 100).round();
    if (v is String) return ((double.tryParse(v) ?? 0) * 100).round();
    return 0;
  }

  String fmt(int cents) => "\$${(cents / 100).toStringAsFixed(2)}";

  void _toggleOptionSelection(OptionGroup g, OptionItem o) {
    setState(() {
      final optionId = o.id ?? 0;
      if (_selectedOptions.containsKey(optionId)) {
        _selectedOptions.remove(optionId);
      } else {
        _selectedOptions[optionId] = {'group': g, 'option': o};
      }
    });
  }

  void _selectAllOptions(List<OptionGroup> groups) {
    int selectableCount = _countAllSelectableOptions(groups);
    setState(() {
      if (_selectedOptions.length == selectableCount) {
        _selectedOptions.clear(); // Deselect all
      } else {
        for (final g in groups) {
          for (final o in g.options ?? []) {
            final id = o.id ?? 0;
            if (!widget.existingOptionIds.contains(id) && o.name != null && o.name!.isNotEmpty) {
              _selectedOptions[id] = {'group': g, 'option': o};
            }
          }
        }
      }
    });
  }

  int _countAllSelectableOptions(List<OptionGroup> groups) {
    int count = 0;
    for (final g in groups) {
      for (final o in g.options ?? []) {
        final id = o.id ?? 0;
        if (!widget.existingOptionIds.contains(id) && o.name != null && o.name!.isNotEmpty) count++;
      }
    }
    return count;
  }

  Future<void> _addAllSelectedOptions() async {
    if (_selectedOptions.isEmpty) return;
    setState(() => _isSubmitting = true);
    int successCount = 0;

    try {
      for (final entry in _selectedOptions.values) {
        final g = entry['group'] as OptionGroup;
        final o = entry['option'] as OptionItem;
        try {
          await ShopItemOptionStatusService.createStatus(
            shopId: widget.shopId,
            itemId: widget.itemId,
            itemOptionGroupId: o.itemOptionGroupId ?? (g.id ?? 0),
            itemOptionId: o.id ?? 0,
            status: true,
          );
          widget.onSelect(g.toJson(), o.toJson());
          successCount++;
        } catch (e) {
          debugPrint('Error: $e');
        }
      }
      if (mounted && successCount > 0) {
        widget.onDone?.call();
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: FutureBuilder<ShopOptions>(
        future: futureItem,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _primaryGreen));
          }

          final groups = snapshot.data?.optionGroups ?? [];
          final totalSelectable = _countAllSelectableOptions(groups);
          final isAllSelected = _selectedOptions.length == totalSelectable && totalSelectable > 0;

          return Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  
                  // --- HEADER WITH SELECT ALL AT TOP RIGHT ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 15, 8, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Add Options", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _darkText)),
                              Text(
                                _selectedOptions.isEmpty ? "Pick one or more" : "${_selectedOptions.length} items selected",
                                style: TextStyle(color: _selectedOptions.isEmpty ? Colors.grey : _primaryGreen, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        if (totalSelectable > 0)
                          TextButton.icon(
                            onPressed: () => _selectAllOptions(groups),
                            icon: Icon(isAllSelected ? Icons.deselect : Icons.select_all, size: 18, color: _primaryGreen),
                            label: Text(
                              isAllSelected ? "None" : "All",
                              style: TextStyle(color: _primaryGreen, fontWeight: FontWeight.w800),
                            ),
                          ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // --- LIST ---
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final g = groups[index];
                        final visibleOptions = (g.options ?? []).where((o) {
                          final id = o.id ?? 0;
                          return !widget.existingOptionIds.contains(id) && o.name != null && o.name!.isNotEmpty;
                        }).toList();

                        if (visibleOptions.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
                              child: Text(g.name?.toUpperCase() ?? 'GROUP', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1.5)),
                            ),
                            ...visibleOptions.map((o) {
                              final optionId = o.id ?? 0;
                              final isSelected = _selectedOptions.containsKey(optionId);
                              final priceAdj = toCents(o.priceAdjustCents);

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? _primaryGreen.withOpacity(0.06) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isSelected ? _primaryGreen : Colors.grey[200]!, width: 2),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: !_isSubmitting ? () => _toggleOptionSelection(g, o) : null,
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48, height: 48,
                                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
                                          child: (o.iconUrl != null && o.iconUrl!.isNotEmpty)
                                              ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(o.iconUrl!, fit: BoxFit.cover))
                                              : Icon(Icons.local_cafe_outlined, color: _primaryGreen.withOpacity(0.4)), // ✅ Fixed Icon
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(o.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              const SizedBox(height: 2),
                                              Text(priceAdj == 0 ? "Standard" : "+ ${fmt(priceAdj)}", style: TextStyle(color: _primaryGreen, fontSize: 13, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 26, height: 26,
                                          decoration: BoxDecoration(
                                            color: isSelected ? _primaryGreen : Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: isSelected ? _primaryGreen : Colors.grey[300]!, width: 2),
                                          ),
                                          child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),

              // --- STICKY FOOTER ---
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(25, 20, 25, 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, -5))],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting || _selectedOptions.isEmpty ? null : _addAllSelectedOptions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      disabledBackgroundColor: Colors.grey[300],
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: _isSubmitting 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(
                          _selectedOptions.isEmpty ? "Select to Add" : "Confirm ${_selectedOptions.length} Selections",
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}