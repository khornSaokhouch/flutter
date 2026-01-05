// cart_widgets.dart
import 'package:flutter/material.dart';


// Reusable widgets exported for cart_screen.dart

Widget buildEmptyCartView() => Center(
  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey[300]),
    const SizedBox(height: 16),
    const Text("Cart is empty", style: TextStyle(color: Colors.grey, fontSize: 16)),
  ]),
);

Widget buildSectionHeader(String title) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
]);

Widget buildItemsCard(List<Map<String,dynamic>> items, Widget Function(Map<String,dynamic>) detailBuilder) => Container(
  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0,4))]),
  padding: const EdgeInsets.all(16),
  child: Column(children: items.map((it) => detailBuilder(it)).toList()),
);

Widget buildNotesField(TextEditingController controller, FocusNode focusNode) => Container(
  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
  child: TextField(controller: controller, focusNode: focusNode, maxLines: 2, decoration: const InputDecoration(hintText: "E.g. Less sugar, allergies...", hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none, contentPadding: EdgeInsets.all(16)), style: const TextStyle(fontWeight: FontWeight.w500)),
);

Widget buildDetailItem(Map<String, dynamic> item) {
  final name = item['name'];
  final qty = item['qty'];
  final basePrice = (item['price'] is num) ? (item['price'] as num).toDouble() : double.tryParse('${item['price']}') ?? 0.0;
  final modifiers = item['modifiers'] ?? [];

  return Container(
    margin: const EdgeInsets.only(bottom: 24),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: BorderRadius.circular(8), child: Container(width: 60, height: 60, color: Colors.grey[100], child: Image.network(item['image'] ?? '', fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.coffee, color: Colors.grey)))),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("${qty}x $name", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), const Icon(Icons.edit_outlined, size: 16, color: Colors.green)]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Base Price", style: TextStyle(fontSize: 13, color: Colors.black87)), Text("\$${basePrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))]),
        ...modifiers.map((mod) {
          String modName = "";
          if (mod is Map) modName = (mod['selected_option'] ?? mod['option'] ?? '').toString();
          if (modName.isEmpty) return const SizedBox.shrink();
          return Padding(padding: const EdgeInsets.only(top: 4.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(modName, style: const TextStyle(fontSize: 13, color: Colors.grey))]));
        }).toList(),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Subtotal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text("\$${(basePrice * qty).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))]),
      ])),
    ]),
  );
}

Widget buildClickableTile({required IconData icon, required String title, required String subtitle, required Widget trailing, VoidCallback? onTap}) => Container(
  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
  child: ListTile(onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)), child: Icon(icon, size: 20, color: Colors.black87)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)), trailing: trailing),
);

Widget buildPaymentSummaryCard({required double subtotal, required double discountAmount, required bool isPromoApplied, required double total, required Color freshMintGreen, required Color espressoBrown}) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
  child: Column(children: [
    buildSummaryRow("Subtotal", subtotal),
    if (isPromoApplied) ...[const SizedBox(height: 8), buildSummaryRow("Discount", -discountAmount, isRed: true)],
    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Total Payment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])), Text("\$${total.toStringAsFixed(2)}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: espressoBrown))]),
  ]),
);

Widget buildSummaryRow(String label, double amount, {bool isRed = false}) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey)), Text("${amount < 0 ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isRed ? Colors.red : Colors.black))]);

Widget buildPlaceOrderBar({required bool isDisabled, required VoidCallback onPressed, required Color freshMintGreen, required bool isLoading}) => Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
  child: SizedBox(height: 55, child: ElevatedButton(onPressed: isDisabled ? null : onPressed, style: ElevatedButton.styleFrom(backgroundColor: freshMintGreen, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Place Order", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
);


