import 'package:flutter/material.dart';
import '../../../models/Item_OptionGroup.dart';
import '../../../server/item_service.dart';

class GuestDetailItem extends StatefulWidget {
  final int itemId;
   final int shopId;
  const GuestDetailItem({super.key, required this.itemId,required this.shopId});

  @override
  State<GuestDetailItem> createState() => _DetailItemState();
}

class _DetailItemState extends State<GuestDetailItem> {
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

    final fetched = await ItemService.fetchItemOptionStatusGuest(widget.itemId,widget.shopId);

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
    double basePrice = item.priceCents / 100;
    double optionsPrice = 0.0;

    selectedOptions.forEach((key, option) {
      if (option != null) {
        optionsPrice += option.priceAdjust; // use getter
      }
    });

    setState(() {
      subtotal = (basePrice + optionsPrice) * quantity;
    });
  }


  Widget _buildOptionGroup(OptionGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(group.name,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            if (group.isRequired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '1 Required',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber[800],
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: group.options.map((option) {
            final isSelected = selectedOptions[group.id]?.id == option.id;
            final priceAdjust = option.priceAdjust;
            final priceText = priceAdjust > 0 ? " +\$${priceAdjust.toStringAsFixed(2)}" : "";

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedOptions[group.id] = option;
                  _calculateSubtotal();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFC107) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFFC107) : Colors.grey.shade300,
                    width: 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    if (!isSelected)
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (option.icon_url.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Image.network(option.icon_url, width: 20, height: 20),
                      ),
                    Text(
                      "${option.name}$priceText",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[800],
                      ),
                    ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Text("\$${subtotal.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
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
                          }),
                      Text(quantity.toString(),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              quantity++;
                              _calculateSubtotal();
                            });
                          }),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final selected = groups.map((g) {
                        return {
                          'group_id': g.id,
                          'group_name': g.name,
                          'selected_option': selectedOptions[g.id]?.name ?? null,
                          'option_id': selectedOptions[g.id]?.id
                        };
                      }).toList();

                      print('🛒 Add to cart: ${item.name}');
                      print('Quantity: $quantity');
                      print('Selected: $selected');
                      print('Subtotal: \$${subtotal.toStringAsFixed(2)}');
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[600],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        elevation: 2),
                    child: const Text('ADD TO CART',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // if (loading) {
    //   return const Scaffold(
    //       body: Center(child: CircularProgressIndicator()));
    // }

    // if (groups.isEmpty) {
    //   return const Scaffold(
    //       body: Center(child: Text('Failed to load item or options')));
    // }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
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
                  child: Icon(Icons.favorite_border, color: Colors.amber)),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              background: Container(
                  alignment: Alignment.center,
                  child: Image.network(item.imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (item.description.isNotEmpty)
                    Text(item.description,
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey[700], height: 1.4)),
                  const SizedBox(height: 30),
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
