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

  // Theme
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);

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
          SnackBar(
            content: const Text('Option successfully added'),
            backgroundColor: _freshMintGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      widget.onSelect(g.toJson(), o.toJson());
      widget.onDone?.call();

      return true;
    } catch (e) {
      debugPrint('Error creating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
      return false;
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: FutureBuilder<ShopOptions>(
        future: futureItem,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _freshMintGreen));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final item = snapshot.data!;
          final groups = item.optionGroups ?? [];

          return Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Add Options", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _espressoBrown)),
                        const Text("Select options to enable", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context, false), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Content
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final g = groups[index];
                    final options = g.options ?? [];
                    final visibleOptions = options.where((o) {
                      final id = o.id ?? 0;
                      final hasName = o.name != null && o.name!.trim().isNotEmpty;
                      return !widget.existingOptionIds.contains(id) && hasName;
                    }).toList();

                    if (visibleOptions.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
                          child: Text(
                            g.name ?? 'Group',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _espressoBrown),
                          ),
                        ),
                        ...visibleOptions.map((o) {
                          final isActive = isOptionActive(o.isActive);
                          final priceAdj = toCents(o.priceAdjustCents);
                          final priceLabel = priceAdj == 0 ? '' : '+${fmt(priceAdj)}';
                          final imageUrl = o.iconUrl;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              enabled: isActive && !_isSubmitting,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: Container(
                                width: 40, 
                                height: 40,
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                child: (imageUrl != null && imageUrl.isNotEmpty)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 20),
                                        ),
                                      )
                                    : const Icon(Icons.local_offer_outlined, size: 20, color: Colors.grey),
                              ),
                              title: Text(o.name ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: priceLabel.isNotEmpty 
                                ? Text(priceLabel, style: TextStyle(color: _freshMintGreen, fontWeight: FontWeight.bold)) 
                                : null,
                              trailing: IconButton(
                                icon: Icon(Icons.add_circle, color: (isActive && !_isSubmitting) ? _espressoBrown : Colors.grey),
                                onPressed: (isActive && !_isSubmitting)
                                    ? () async {
                                        final ok = await _onOptionSelected(g, o);
                                        if (mounted) Navigator.pop(context, ok);
                                      }
                                    : null,
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
          );
        },
      ),
    );
  }
}