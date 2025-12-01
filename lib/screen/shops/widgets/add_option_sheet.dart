import 'package:flutter/material.dart';
import '../../../models/shops_models/shop_options_model.dart';
import '../../../server/shops_server/shop_option_service.dart';

typedef OptionSelectCallback = void Function(
    Map<String, dynamic> group, Map<String, dynamic> option);

class AddOptionSheet extends StatefulWidget {
  final OptionSelectCallback onSelect;
  final VoidCallback? onDone;
  final int itemId;
  final int shopId;

  // NEW: pass existing option ids so sheet can hide already-added options
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

  @override
  void initState() {
    super.initState();
    futureItem = ShopItemOptionStatusService.getItemDetails(widget.itemId);
  }

  bool isOptionActive(dynamic v) {
    if (v == null) return false;
    return v == 1 || v == true;
  }

  int toCents(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return (v * 100).round();
    if (v is String) return ((double.tryParse(v) ?? 0) * 100).round();
    return 0;
  }

  String fmt(int cents) {
    return "\$${(cents / 100).toStringAsFixed(2)}";
  }

  /// Create status on server and return true on success.
  Future<bool> _onOptionSelected(OptionGroup g, OptionItem o) async {
    try {
      setState(() => _isSubmitting = true);

      await ShopItemOptionStatusService.createStatus(
        shopId: widget.shopId,
        itemId: widget.itemId,
        itemOptionGroupId: o.itemOptionGroupId ?? (g.id ?? 0),
        itemOptionId: o.id ?? 0,
        status: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Option status updated')),
        );
      }

      // notify parent about selection
      widget.onSelect(g.toJson(), o.toJson());
      widget.onDone?.call();

      return true;
    } catch (e) {
      debugPrint('Error creating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update option status: $e')),
        );
      }
      // still notify parent about attempted selection (optional)
      try {
        widget.onSelect(g.toJson(), o.toJson());
      } catch (_) {}
      return false;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<ShopOptions>(
        future: futureItem,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              snapshot.connectionState == ConnectionState.active) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Text("Error: ${snapshot.error}"),
            );
          }

          final item = snapshot.data!;
          final groups = item.optionGroups ?? [];

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Add Option',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: groups.map((g) {
                        final options = g.options ?? [];

                        // Filter options:
                        //  - hide if already added
                        //  - hide if name is null/empty
                        final visibleOptions = options.where((o) {
                          final id = o.id ?? 0;
                          final hasName = o.name != null && o.name!.trim().isNotEmpty;
                          return !widget.existingOptionIds.contains(id) && hasName;
                        }).toList();

                        if (visibleOptions.isEmpty) {
                          // If you prefer to hide empty groups entirely, skip rendering them:
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(g.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            ...visibleOptions.map((o) {
                              final isActive = isOptionActive(o.isActive);
                              final priceAdj = toCents(o.priceAdjustCents);
                              final priceLabel = priceAdj == 0 ? '' : ' +${fmt(priceAdj)}';
                              final imageUrl = o.iconUrl;

                              return ListTile(
                                enabled: isActive && !_isSubmitting,
                                leading: (imageUrl != null && imageUrl.isNotEmpty)
                                    ? Image.network(
                                  imageUrl,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const CircleAvatar(child: Icon(Icons.broken_image)),
                                )
                                    : const CircleAvatar(child: Icon(Icons.add)),
                                title: Text(o.name ?? ''),
                                subtitle: priceLabel.isNotEmpty ? Text(priceLabel) : null,
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: isActive && !_isSubmitting
                                      ? () async {
                                    final ok = await _onOptionSelected(g, o);
                                    if (mounted) Navigator.pop(context, ok);
                                  }
                                      : null,
                                ),
                                onTap: isActive && !_isSubmitting
                                    ? () async {
                                  final ok = await _onOptionSelected(g, o);
                                  if (mounted) Navigator.pop(context, ok);
                                }
                                    : null,
                              );
                            }).toList(),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
