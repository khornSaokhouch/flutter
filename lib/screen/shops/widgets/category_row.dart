// lib/widgets/category_row.dart
import 'package:flutter/material.dart';
import '../../../models/shops_models/shop_categories_models.dart';


/// A single category row widget.
///
/// - Shows the image, name, switch and menu button.
/// - Computes `canOpen` from `item.status` and `item.pivot?.status`.
/// - When tapped: if the category is inactive, a SnackBar is shown; otherwise
///   it calls [onTap] (which the parent should provide to navigate).
/// - When switch toggled, calls [onStatusChanged] and shows a local loading
///   spinner on the switch while the callback completes.
class CategoryRow extends StatefulWidget {
  final int index;
  final CategoryModel item;
  final Color accentColor;

  /// Called when the user taps the whole row (only called for active categories).
  /// The parent should perform navigation here.
  final VoidCallback? onTap;

  /// Called when the switch is toggled.
  /// Receives the categoryId and the new boolean status (true => active).
  /// Should throw on failure so widget can show a SnackBar (optional).
  final Future<void> Function(int categoryId, bool newStatus)? onStatusChanged;

  /// Optional menu selection callback ('edit' or 'delete').
  final void Function(String action)? onMenuSelected;

  const CategoryRow({
    Key? key,
    required this.index,
    required this.item,
    required this.accentColor,
    this.onTap,
    this.onStatusChanged,
    this.onMenuSelected,
  }) : super(key: key);

  @override
  State<CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<CategoryRow> {
  bool _isToggling = false;

  bool get _canOpen => (widget.item.status == 1) && ((widget.item.pivot?.status ?? 1) == 1);

  @override
  Widget build(BuildContext context) {
    final isOn = _canOpen;
    return InkWell(
      onTap: () {
        if (!_canOpen) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This category is inactive and cannot be opened.')),
          );
          return;
        }
        if (widget.onTap != null) widget.onTap!();
      },
      child: Opacity(
        opacity: _canOpen ? 1.0 : 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${widget.index + 1}',
                      style: TextStyle(fontSize: 14, color: _canOpen ? null : Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: widget.item.imageCategoryUrl.isNotEmpty
                          ? Image.network(
                        widget.item.imageCategoryUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      )
                          : Container(
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.item.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _canOpen ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: _isToggling
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Switch(
                      value: isOn,
                      activeThumbColor: Colors.white,
                      activeTrackColor: widget.accentColor,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey.shade400,
                      onChanged: (val) async {
                        if (widget.onStatusChanged == null) return;

                        setState(() => _isToggling = true);
                        try {
                          await widget.onStatusChanged!(widget.item.id, val);
                          // Parent should update model/state; widget will rebuild
                          // with new item via parent setState.
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update status: $e')),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isToggling = false);
                          }
                        }
                      },
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      if (widget.onMenuSelected != null) widget.onMenuSelected!(value);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 52 + 48 + 12, right: 16),
              child: Row(
                children: [
                  Text(
                    'Variant Price',
                    style: TextStyle(
                      color: _canOpen ? Colors.grey : Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Additional Price',
                    style: TextStyle(
                      color: widget.accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
