import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/item_option_group.dart';
import '../../../server/item_service.dart';
import '../../auth/login_bottom_sheet.dart';
import './order_screen.dart';
import '../../../core/widgets/loading/logo_loading.dart';



class GuestDetailItem extends StatefulWidget {
  final int itemId;
  final int shopId;

  final int? userId;
  const GuestDetailItem({
    super.key,
    required this.itemId,
    required this.shopId, this.userId,
  });

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

  // Local mutable copy of userId
  int? _currentUserId;

  // --- Theme Colors ---
  final Color _freshMintGreen = const Color(0xFF4E8D7C);
  final Color _espressoBrown = const Color(0xFF4B2C20);
  final Color _bgGrey = const Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.userId;
    _fetchItem();
  }

  Future<void> _fetchItem() async {
    setState(() => loading = true);

    try {
      final fetched = await ItemService.fetchItemOptionStatusGuest(
          widget.itemId, widget.shopId);

      if (fetched != null && fetched.isNotEmpty) {
        item = fetched.first.item;

        final Map<int, OptionGroup> groupMap = {};
        for (var status in fetched) {
          final g = status.optionGroup;
          final o = status.option;

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
    } catch (e) {
      debugPrint("Error fetching item: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _calculateSubtotal() {
    double basePrice = item.priceCents / 100;
    double optionsPrice = 0.0;

    selectedOptions.forEach((key, option) {
      if (option != null) {
        optionsPrice += option.priceAdjust / 100;
      }
    });

    setState(() {
      subtotal = (basePrice + optionsPrice) * quantity;
    });
  }

  @override
  Widget build(BuildContext context) {
  if (loading) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LogoLoading(), // your existing loading widget
          const SizedBox(height: 16),
          const Text(
            'Fetching item info...',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}


    if (groups.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Failed to load item info')),
      );
    }
    return Scaffold(
      backgroundColor: _bgGrey,
      body: CustomScrollView(
        slivers: [
          // 1. Immersive Header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: _bgGrey,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      size: 18, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: Icon(Icons.favorite_border,
                        size: 20, color: _freshMintGreen),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported,
                            size: 50, color: Colors.grey)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black12,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.05)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Content Body
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: _bgGrey,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: _espressoBrown,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "\$${(item.priceCents / 100).toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _freshMintGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (item.description.isNotEmpty)
                          Text(
                            item.description,
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                                height: 1.5),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Option Groups
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children:
                      groups.map((g) => _buildOptionGroup(g)).toList(),
                    ),
                  ),

                  const SizedBox(height: 100), // Space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  // --- UI Widgets ---

  Widget _buildOptionGroup(OptionGroup group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  group.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _espressoBrown,
                  ),
                ),
                if (group.isRequired)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _espressoBrown.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Required',
                      style: TextStyle(
                          fontSize: 11,
                          color: _espressoBrown,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          // Options Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: group.options.map((option) {
              final isSelected = selectedOptions[group.id]?.id == option.id;
              final double priceAdjust = option.priceAdjust / 100;
              final String priceText = priceAdjust > 0
                  ? "+ \$${priceAdjust.toStringAsFixed(2)}"
                  : "";

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedOptions[group.id] = option;
                    _calculateSubtotal();
                  });
                  HapticFeedback.lightImpact();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _freshMintGreen.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                      isSelected ? _freshMintGreen : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                          color: _freshMintGreen.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]
                        : [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Optional Icon
                      if (option.icon_url.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(option.icon_url,
                                width: 20, height: 20, fit: BoxFit.cover),
                          ),
                        ),
                      Text(
                        "$priceText ${option.name}",
                        style: TextStyle(
                          fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? _espressoBrown : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Subtotal Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600])),
              Text("\$${subtotal.toStringAsFixed(2)}",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _espressoBrown)),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Quantity Control
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildQtyBtn(Icons.remove, () {
                      if (quantity > 1) {
                        setState(() {
                          quantity--;
                          _calculateSubtotal();
                        });
                      }
                    }),
                    SizedBox(
                      width: 30,
                      child: Text(
                        quantity.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _espressoBrown),
                      ),
                    ),
                    _buildQtyBtn(Icons.add, () {
                      setState(() {
                        quantity++;
                        _calculateSubtotal();
                      });
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Add to Cart Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // If not logged in -> show login bottom sheet and wait for user id
                    if (_currentUserId == null || _currentUserId == 0) {
                      final result = await showModalBottomSheet<int?>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const LoginBottomSheet(),
                      );

                      if (result == null || result == 0) {
                        // user cancelled or login failed
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Login required to add to cart')),
                          );
                        }
                        return;
                      }

                      // Save logged-in user id locally for subsequent checks
                      setState(() {
                        _currentUserId = result;
                      });
                    }

                    // Now _currentUserId is non-null -> proceed to cart
                    final selected = groups.map((g) {
                      return {
                        'group_id': g.id,
                        'group_name': g.name,
                        'selected_option': selectedOptions[g.id]?.name,
                        'option_id': selectedOptions[g.id]?.id
                      };
                    }).toList();

                    Navigator.push(
                       context,
                      MaterialPageRoute(
                        builder: (_) => CartScreen(
                          id: item.id,
                          name: item.name,
                          imageUrl: item.imageUrl,
                          quantity: quantity,
                          subtotal: subtotal,
                          selectedModifiers: selected,
                          shopId: widget.shopId,
                          userId: _currentUserId,
                        ),
                      ),
                      // MaterialPageRoute(
                      //   builder: (_) =>  CartScreen(shopId: widget.shopId),
                      // ),

                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _freshMintGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: const Text(
                    'ADD TO CART',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: _espressoBrown, size: 20),
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}
