import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/promotion_model.dart';
import '../../../server/promotion_service.dart';
import '../widgets/promotion_card.dart';
import '../widgets/promotion_form_sheet.dart';

class PromotionsScreen extends StatefulWidget {
  final int shopId;
  const PromotionsScreen({super.key, required this.shopId});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final PromotionService _service = PromotionService();

  List<PromotionModel> promotions = [];
  bool _loading = false;
  String? _error;

  // tracks individual item busy states (e.g., updating / deleting)
  final Map<int, bool> _itemBusy = {};

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions([int? shopId]) async {
    final id = shopId ?? widget.shopId;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final promoList = await _service.getPromotionByShopId(id);
      setState(() {
        promotions = promoList;
      });
    } catch (e) {
      setState(() {
        promotions = [];
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _openCreateForm() async {
    final newPromotion = await showModalBottomSheet<PromotionModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: PromotionFormSheet(
            defaultShopId: promotions.isNotEmpty ? promotions.first.shopid : widget.shopId,
          ),
        );
      },
    );

    if (newPromotion != null) {
      try {
        final created = await _service.createPromotion(newPromotion);
        setState(() => promotions.add(created));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Promotion created: ${created.code}')));
      } catch (e) {
        setState(() => promotions.add(newPromotion));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Created locally (server failed): ${e.toString()}')));
      }
    }
  }

  Future<void> _toggleActive(int index, bool value) async {
    final p = promotions[index];
    // mark busy for item id (use index as fallback)
    final key = p.id == 0 ? index : p.id;
    setState(() => _itemBusy[key] = true);

    // optimistic update locally
    final old = p;
    final updated = PromotionModel(
      id: p.id,
      shopid: p.shopid,
      code: p.code,
      type: p.type,
      value: p.value,
      startsat: p.startsat,
      endsat: p.endsat,
      isactive: value ? 1 : 0,
      usagelimit: p.usagelimit,
      createdAt: p.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      shop: p.shop,
    );

    setState(() => promotions[index] = updated);

    try {
      if (p.id == 0) {
        // nothing to update on server; skip call
      } else {
        final serverUpdated = await _service.updatePromotion(p.id, updated);
        setState(() => promotions[index] = serverUpdated);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Promotion ${value ? "activated" : "deactivated"}: ${p.code}')));
    } catch (e) {
      // revert on error
      setState(() => promotions[index] = old);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: ${e.toString()}')));
    } finally {
      setState(() => _itemBusy.remove(key));
    }
  }

  Future<void> _confirmAndDelete(int index) async {
    final p = promotions[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete promotion'),
        content: Text('Are you sure you want to delete ${p.code}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    final key = p.id == 0 ? index : p.id;
    setState(() => _itemBusy[key] = true);

    try {
      if (p.id != 0) {
        await _service.deletePromotion(p.id);
      }
      setState(() => promotions.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted: ${p.code}')));
    } catch (e) {
      // remove busy flag and show error
      setState(() => _itemBusy.remove(key));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: const Text('Promotions', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}, tooltip: 'Filter'),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(children: [
            const SizedBox(height: 8),
            _buildHeader(context),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateForm,
        icon: const Icon(Icons.add),
        label: const Text("New"),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(children: [
      const Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Active campaigns', style: TextStyle(fontSize: 14, color: Colors.black54)),
          SizedBox(height: 6),
          Text('Exciting offers to boost sales', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6A5AE0), Color(0xFF8E6AF5)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          const Text('Total', style: TextStyle(color: Colors.white70)),
          Text('${promotions.length}', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
      )
    ]);
  }

  Widget _buildBody() {
    if (_loading && promotions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && promotions.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadPromotions(),
        child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
          const SizedBox(height: 120),
          Center(child: Text(_error!, textAlign: TextAlign.center)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPromotions(),
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, mainAxisExtent: 150),
        itemCount: promotions.length,
        itemBuilder: (context, i) {
          final p = promotions[i];
          final busyKey = p.id == 0 ? i : p.id;
          final busy = _itemBusy[busyKey] ?? false;

          return Stack(children: [
            PromotionCard(
              promotion: p,
              onToggleActive: (v) {
                _toggleActive(i, v);
              },
              onCopyCode: () => _copyCode(p),
              onDelete: () => _confirmAndDelete(i),
            ),
            if (busy)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                ),
              ),
          ]);
        },
      ),
    );
  }

  Future<void> _copyCode(PromotionModel p) async {
    await Clipboard.setData(ClipboardData(text: p.code));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Code copied: ${p.code}')));
  }
}
