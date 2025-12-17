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
  final Color _primaryGreen = const Color(0xFF4E8D7C);
  final Color _darkText = const Color(0xFF1A1A1A);

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
            backgroundColor: _primaryGreen,
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
            return Center(child: CircularProgressIndicator(color: _primaryGreen));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final item = snapshot.data!;
          final groups = item.optionGroups ?? [];

          return Column(
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Add Options", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _darkText)),
                        const SizedBox(height: 4),
                        const Text("Enable options for this product", style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey[200]),

              // Content
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                          child: Row(
                            children: [
                              Container(width: 4, height: 16, decoration: BoxDecoration(color: _primaryGreen, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 8),
                              Text(
                                g.name ?? 'Group',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkText),
                              ),
                            ],
                          ),
                        ),
                        ...visibleOptions.map((o) {
                          final isActive = isOptionActive(o.isActive);
                          final priceAdj = toCents(o.priceAdjustCents);
                          final priceLabel = priceAdj == 0 ? '' : '+${fmt(priceAdj)}';
                          final imageUrl = o.iconUrl;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
                              ],
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: ListTile(
                                enabled: isActive && !_isSubmitting,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  width: 48, 
                                  height: 48,
                                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                                  child: (imageUrl != null && imageUrl.isNotEmpty)
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 20, color: Colors.grey[400]),
                                          ),
                                        )
                                      : Icon(Icons.local_offer_rounded, size: 24, color: _primaryGreen.withOpacity(0.5)),
                                ),
                                title: Text(o.name ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                subtitle: priceLabel.isNotEmpty 
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: _primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                            child: Text(priceLabel, style: TextStyle(color: _primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                    ) 
                                  : null,
                                trailing: ElevatedButton(
                                  onPressed: (isActive && !_isSubmitting)
                                      ? () async {
                                          final ok = await _onOptionSelected(g, o);
                                          if (mounted) Navigator.pop(context, ok);
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryGreen,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text("Add"),
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
          );
        },
      ),
    );
  }
}