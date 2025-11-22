import 'package:flutter/material.dart';
import '../../../models/Item_OptionGroup.dart';
import '../../../server/item_service.dart';

class DetailItem extends StatefulWidget {
  final int itemId;
  final int shopId;

  const DetailItem({
    super.key,
    required this.itemId,
    required this.shopId,
  });

  @override
  State<DetailItem> createState() => _DetailItemState();
}

class _DetailItemState extends State<DetailItem> {
  bool loading = true;
  late Item item;
  List<OptionGroup> groups = [];
  Map<int, Option?> selectedOptions = {};
  int quantity = 1;
  double subtotal = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchItem();
  }

  Future<void> _fetchItem() async {
    setState(() => loading = true);

    final fetched =
    await ItemService.fetchItemOptionStatus(widget.itemId, widget.shopId);

    if (fetched != null && fetched.isNotEmpty) {
      item = fetched.first.item;

      final Map<int, OptionGroup> groupMap = {};
      for (var status in fetched) {
        final g = status.optionGroup;
        final o = status.option;

        // create group if not exists
        if (!groupMap.containsKey(g.id)) {
          groupMap[g.id] = OptionGroup(
            id: g.id,
            name: g.name,
            type: g.type,
            isRequired: g.isRequired,
            createdAt: g.createdAt,
            updatedAt: g.updatedAt,
            options: [],
          );
        }

        // add option if not already in group
        final existingGroup = groupMap[g.id]!;
        if (!existingGroup.options.any((opt) => opt.id == o.id)) {
          existingGroup.options.add(o);
        }
      }

      groups = groupMap.values.toList();

      // Preselect required options
      for (var group in groups) {
        if (group.isRequired && group.options.isNotEmpty) {
          selectedOptions[group.id] = group.options.first;
        }
      }

      _calculateSubtotal();
    }

    setState(() => loading = false);
  }

  void _calculateSubtotal() {
    double basePrice = item.priceCents;
    double optionsPrice = 0.0;

    selectedOptions.forEach((key, option) {
      if (option != null) {
        optionsPrice += option.priceAdjust;
      }
    });

    setState(() {
      subtotal = (basePrice + optionsPrice) * quantity;
    });
  }

  // ---------- UI HELPERS ----------


  // Header for groups (“Size” + “1 Required” pill)
  Widget _buildGroupHeader(OptionGroup group) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          group.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (group.isRequired)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4CC),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '1 Required',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE2A700),
              ),
            ),
          ),
      ],
    );
  }

  // Cards for options – soft yellow when selected, like screenshot
  Widget _buildOptionGroup(OptionGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroupHeader(group),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: group.options.map((option) {
            final isSelected = selectedOptions[group.id]?.id == option.id;
            final priceAdjust = option.priceAdjust;
            final priceText = priceAdjust > 0
                ? " +\$${priceAdjust.toStringAsFixed(2)}"
                : "";

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedOptions[group.id] = option;
                  _calculateSubtotal();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: 110, // more “tile-ish”
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFF4CC)
                      : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFC107)
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (option.icon_url.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Image.network(
                          option.icon_url,
                          width: 28,
                          height: 28,
                        ),
                      ),
                    Text(
                      option.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.grey[900],
                      ),
                    ),
                    if (priceText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        priceText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subtotal row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subtotal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "\$${subtotal.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  // Quantity pill
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (quantity > 1) {
                              setState(() {
                                quantity--;
                                _calculateSubtotal();
                              });
                            }
                          },
                        ),
                        Text(
                          quantity.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              quantity++;
                              _calculateSubtotal();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Add to cart button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          final selected = groups.map((g) {
                            return {
                              'group_id': g.id,
                              'group_name': g.name,
                              'selected_option':
                              selectedOptions[g.id]?.name ?? null,
                              'option_id': selectedOptions[g.id]?.id,
                            };
                          }).toList();

                          // TODO: hook into your cart
                          debugPrint('🛒 Add to cart: ${item.name}');
                          debugPrint('Quantity: $quantity');
                          debugPrint('Selected: $selected');
                          debugPrint('Selected: $selected');
                          debugPrint(
                              'Subtotal: \$${subtotal.toStringAsFixed(2)}');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'ADD TO CART',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (groups.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Failed to load item or options')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Top image area similar to screenshot
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.amber),
              onPressed: () => Navigator.pop(context),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.favorite_border, color: Colors.amber),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              background: Container(
                color: Colors.white,
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.only(bottom: 24),
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.contain,
                  width: 260,
                  height: 260,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Option groups (Size, Sugar Level, Ice Level, etc.)
                  ...groups.map(_buildOptionGroup).toList(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
}
