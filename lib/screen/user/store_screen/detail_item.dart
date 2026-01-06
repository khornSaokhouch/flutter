import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/item_option_group.dart';
import '../../../server/item_service.dart';
import '../../auth/login_bottom_sheet.dart';
import './order_screen.dart'; // Ensure this matches your Cart/Order screen path
import '../../../core/widgets/loading/logo_loading.dart';

class GuestDetailItem extends StatefulWidget {
  final int itemId;
  final int shopId;
  final int? userId;

  const GuestDetailItem({
    super.key,
    required this.itemId,
    required this.shopId,
    this.userId,
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
  int? _currentUserId;

  // Premium Theme Colors
  final Color _mintGreen = const Color(0xFF5A9486);
  final Color _espresso = const Color(0xFF2D140B);
  final Color _lightBg = const Color(0xFFF9F9F9);

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.userId;
    _fetchItem();
  }

  Future<void> _fetchItem() async {
    setState(() => loading = true);
    try {
      final fetched = await ItemService.fetchItemOptionStatusGuest(widget.itemId, widget.shopId);
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
                options: []);
          }
          final existingGroup = groupMap[g.id]!;
          if (!existingGroup.options.any((opt) => opt.id == o.id)) existingGroup.options.add(o);
        }
        groups = groupMap.values.toList();
        for (var group in groups) {
          if (group.isRequired && group.options.isNotEmpty) selectedOptions[group.id] = group.options.first;
        }
        _calculateSubtotal();
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _calculateSubtotal() {
    double basePrice = item.priceCents / 100;
    double optionsPrice = 0.0;
    selectedOptions.forEach((key, option) {
      if (option != null) optionsPrice += option.priceAdjust / 100;
    });
    setState(() {
      subtotal = (basePrice + optionsPrice) * quantity;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return Scaffold(backgroundColor: Colors.white, body: Center(child: LogoLoading()));

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. IMAGE HEADER
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: Colors.white,
            leadingWidth: 80,
            leading: _buildHeaderBtn(Icons.arrow_back_ios_new, () => Navigator.pop(context)),
            actions: [_buildHeaderBtn(Icons.favorite_border, () {}, isAction: true)],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'item_${item.id}',
                    child: Image.network(item.imageUrl, fit: BoxFit.cover),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black38, Colors.transparent, Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. CONTENT CARD
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -35, 0),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 150),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Name & Base Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: _espresso,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "\$${(item.priceCents / 100).toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _mintGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      style: TextStyle(fontSize: 15, color: Colors.grey[500], height: 1.5),
                    ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Divider(thickness: 1, color: Color(0xFFF2F2F2)),
                  ),

                  // Option Sections
                  ...groups.map((g) => _buildOptionSection(g)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildHeaderBtn(IconData icon, VoidCallback onTap, {bool isAction = false}) {
    return Padding(
      padding: EdgeInsets.only(left: isAction ? 0 : 20, right: isAction ? 20 : 0),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Icon(icon, size: 18, color: _espresso),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionSection(OptionGroup group) {
    final bool isSizeGroup = group.name.toLowerCase().contains('size');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER SECTION ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name.toUpperCase(),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _espresso, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    group.isRequired ? "Required • Select one" : "Optional",
                    style: TextStyle(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (group.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _mintGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text("REQUIRED", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _mintGreen)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // --- GRID SECTION ---
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isSizeGroup ? 2.2 : 0.85,
          ),
          itemCount: group.options.length,
          itemBuilder: (context, index) {
            final option = group.options[index];
            final isSelected = selectedOptions[group.id]?.id == option.id;

            // ✅ ROBUST URL CHECK: Ensures string isn't empty AND is a real URL
            final String rawUrl = option.icon_url ?? "";
            final bool hasValidIcon = rawUrl.trim().isNotEmpty && rawUrl.startsWith('http');

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  selectedOptions[group.id] = option;
                  _calculateSubtotal();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : _lightBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isSelected ? _mintGreen : Colors.transparent, width: 2),
                  boxShadow: isSelected ? [BoxShadow(color: _mintGreen.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 6))] : [],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (!isSizeGroup) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? _mintGreen.withOpacity(0.1) : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          // ✅ Use the new hasValidIcon check here
                          child: hasValidIcon
                              ? Image.network(
                            rawUrl,
                            width: 24,
                            height: 24,
                            color: isSelected ? _mintGreen : _espresso.withOpacity(0.7),
                            errorBuilder: (_, __, ___) => Icon(Icons.restaurant_menu, size: 18, color: Colors.grey[300]),
                          )
                              : Icon(Icons.radio_button_unchecked, size: 18, color: Colors.grey[300]),
                        ),
                        const SizedBox(height: 8),
                      ],

                      Text(
                        option.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSizeGroup ? 14 : 13,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: _espresso,
                        ),
                      ),

                      if (option.priceAdjust > 0)
                        Text(
                          "+\$${(option.priceAdjust / 100).toStringAsFixed(2)}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? _mintGreen : Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TOTAL PRICE", style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                  Text("\$${subtotal.toStringAsFixed(2)}", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _espresso)),
                ],
              ),
              const Spacer(),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(color: _lightBg, borderRadius: BorderRadius.circular(15)),
                child: Row(
                  children: [
                    _qtyAction(Icons.remove, () { if (quantity > 1) setState(() { quantity--; _calculateSubtotal(); }); }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("$quantity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _espresso)),
                    ),
                    _qtyAction(Icons.add, () { setState(() { quantity++; _calculateSubtotal(); }); }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _handleAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: _mintGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: const Text("CHECKOUT NOW", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyAction(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: _espresso),
      constraints: const BoxConstraints(minWidth: 40),
    );
  }

  Future<void> _handleAddToCart() async {
    if (_currentUserId == null || _currentUserId == 0) {
      final result = await showModalBottomSheet<int?>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const LoginBottomSheet(),
      );
      if (result == null || result == 0) return;
      setState(() => _currentUserId = result);
    }
    final selected = groups.map((g) => {
      'group_id': g.id,
      'group_name': g.name,
      'selected_option': selectedOptions[g.id]?.name,
      'option_id': selectedOptions[g.id]?.id
    }).toList();

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen(
      id: item.id, name: item.name, imageUrl: item.imageUrl,
      quantity: quantity, subtotal: subtotal, selectedModifiers: selected,
      shopId: widget.shopId, userId: _currentUserId,
    )));
  }
}