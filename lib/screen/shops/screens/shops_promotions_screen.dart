import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/promotion_model.dart';
import '../../../server/promotion_service.dart';
import '../widgets/promotion_card.dart';
import '../widgets/promotion_form_sheet.dart';
import '../../../core/widgets/loading/logo_loading.dart';

class PromotionsScreen extends StatefulWidget {
  final int shopId;
  const PromotionsScreen({super.key, required this.shopId});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final PromotionService _service = PromotionService();

  // --- Theme Colors ---
  final Color _deepGreen = const Color(0xFF1B4332);
  final Color _emerald = const Color(0xFF2D6A4F);
  final Color _mint = const Color(0xFF52B788);
  final Color _softBg = const Color(0xFFF7F9F8);

  List<PromotionModel> promotions = [];
  bool _loading = false;
  final Map<int, bool> _itemBusy = {};


  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() { _loading = true; });
    try {
      final promoList = await _service.getPromotionByShopId(widget.shopId);
      setState(() => promotions = promoList);
    } catch (e) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(int index, bool value) async {
    final p = promotions[index];
    final key = p.id;
    setState(() => _itemBusy[key] = true);

    try {
      // ✅ promo.value is cents (e.g. 125 => $1.25)
      final int safeValue = p.value.round();

      final updated = PromotionModel(
        id: p.id,
        shopid: p.shopid,
        code: p.code,
        type: p.type,
        value: safeValue, // ✅ FIXED
        startsat: p.startsat,
        endsat: p.endsat,
        isactive: value ? 1 : 0,
        usagelimit: p.usagelimit,
        createdAt: p.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        shop: p.shop,
      );

      final serverUpdated =
      await _service.updatePromotion(p.id, updated);

      setState(() => promotions[index] = serverUpdated);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Promotion ${value ? "Enabled" : "Disabled"}',
          ),
          backgroundColor: _emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _itemBusy.remove(key));
    }
  }

  Future<void> _confirmAndDelete(int index) async {
    final p = promotions[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Promotion', style: TextStyle(color: _deepGreen, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${p.code}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _itemBusy[p.id] = true);

    try {
      await _service.deletePromotion(p.id);
      setState(() => promotions.removeAt(index));
    } catch (e) {
      setState(() => _itemBusy.remove(p.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  void _openCreateForm() async {
    final newPromotion = await showModalBottomSheet<PromotionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PromotionFormSheet(defaultShopId: widget.shopId),
    );

    if (newPromotion != null) {
      setState(() => _loading = true);
      try {
        final created = await _service.createPromotion(newPromotion);
        setState(() => promotions.add(created));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Create failed: $e')));
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text('PROMOTIONS', 
          style: TextStyle(color: _deepGreen, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateForm,
        backgroundColor: _emerald,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("NEW CAMPAIGN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_emerald, _mint], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _emerald.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Marketing Hub', style: TextStyle(color: Colors.white70, fontSize: 14)),
                SizedBox(height: 4),
                Text('Active Offers', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text('${promotions.length}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                const Text('Total', style: TextStyle(color: Colors.white, fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }

Widget _buildBody() {
  if (_loading && promotions.isEmpty) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LogoLoading(size: 60), // branded loader
          const SizedBox(height: 12),
          Text(
            'Loading promotions...',
            style: TextStyle(
              color: _emerald,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  if (promotions.isEmpty) return _buildEmptyState();

  return RefreshIndicator(
    onRefresh: _loadPromotions,
    color: _emerald,
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: promotions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = promotions[i];
        final bool busy = _itemBusy[p.id] ?? false;

        return Stack(
          children: [
            PromotionCard(
              promotion: p,
              onToggleActive: (v) => _toggleActive(i, v),
              onCopyCode: () {
                Clipboard.setData(ClipboardData(text: p.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Code ${p.code} copied!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              onDelete: () => _confirmAndDelete(i),
            ),
            if (busy)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(16)),
                  child: const Center(child: LogoLoading(size: 40)),
                ),
              ),
          ],
        );
      },
    ),
  );
}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_number_outlined, size: 64, color: _mint.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text("No promotions created yet", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}