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
            groupMap[g.id] = OptionGroup(id: g.id, name: g.name, type: g.type, isRequired: g.isRequired, createdAt: g.createdAt, updatedAt: g.updatedAt, options: []);
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
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // 1. IMAGE HEADER
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: Colors.white, // appBar color when pinned
            leadingWidth: 80,
            leading: _buildHeaderBtn(Icons.arrow_back_ios_new, () => Navigator.pop(context)),
            actions: [_buildHeaderBtn(Icons.favorite_border, () {}, isAction: true)],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(item.imageUrl, fit: BoxFit.cover),
                  // Dark overlay at the top for button visibility
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Colors.black26, Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. INFORMATION CARD (The one with the Radius)
          SliverToBoxAdapter(
            child: Container(
              // The negative translation pulls the card OVER the image
              transform: Matrix4.translationValues(0, -40, 0), 
              padding: const EdgeInsets.fromLTRB(24, 35, 24, 140),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40), // CLEAN PREMIUM RADIUS
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _espresso, letterSpacing: -0.5),
                        ),
                      ),
                      Text(
                        "\$${(item.priceCents / 100).toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _mintGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      style: TextStyle(fontSize: 15, color: Colors.grey[500], height: 1.5, fontWeight: FontWeight.w400),
                    ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(thickness: 1, color: Color(0xFFF5F5F5)),
                  ),

                  // Option Groups (Sizes, Sugar, etc.)
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Container(
            height: 44, width: 44,
            color: Colors.white.withOpacity(0.9),
            child: IconButton(
              icon: Icon(icon, size: 20, color: _espresso),
              onPressed: onTap,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionSection(OptionGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(group.name.toUpperCase(), 
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _espresso, letterSpacing: 1.2)),
            const SizedBox(width: 8),
            if (group.isRequired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _mintGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text("REQUIRED", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _mintGreen)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: group.options.map((option) {
            final isSelected = selectedOptions[group.id]?.id == option.id;
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
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? _mintGreen : _lightBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected ? [BoxShadow(color: _mintGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.name,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isSelected ? Colors.white : _espresso),
                    ),
                    if (option.priceAdjust > 0)
                      Text(
                        " (+\$${(option.priceAdjust/100).toStringAsFixed(2)})",
                        style: TextStyle(fontSize: 13, color: isSelected ? Colors.white70 : Colors.grey[500], fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 30, offset: const Offset(0, -10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${quantity}x Total Price", style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w600)),
                    Text("\$${subtotal.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _espresso)),
                  ],
                ),
              ),
              Container(
                height: 52,
                decoration: BoxDecoration(color: _lightBg, borderRadius: BorderRadius.circular(18)),
                child: Row(
                  children: [
                    _qtyAction(Icons.remove, () { if (quantity > 1) setState(() { quantity--; _calculateSubtotal(); }); }),
                    Text("$quantity", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    _qtyAction(Icons.add, () { setState(() { quantity++; _calculateSubtotal(); }); }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: _handleAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: _mintGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Text("Checkout Now",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyAction(IconData icon, VoidCallback onTap) {
    return IconButton(onPressed: onTap, icon: Icon(icon, size: 20, color: _espresso), splashRadius: 20);
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