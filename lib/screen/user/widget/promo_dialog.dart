// promo_dialog.dart
import 'package:flutter/material.dart';

class PromoDialog extends StatelessWidget {
  final TextEditingController promoController;
  final bool isApplying;
  final VoidCallback onApply;
  final Color freshMintGreen;

  const PromoDialog({Key? key, required this.promoController, required this.isApplying, required this.onApply, required this.freshMintGreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(20.0), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text("Enter Voucher", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 20),
        TextField(controller: promoController, decoration: InputDecoration(hintText: "Promo Code", filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: Icon(Icons.card_giftcard, color: freshMintGreen))),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          const SizedBox(width: 10),
          ElevatedButton(onPressed: isApplying ? null : onApply, style: ElevatedButton.styleFrom(backgroundColor: freshMintGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)), child: isApplying ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Apply", style: TextStyle(fontWeight: FontWeight.bold))),
        ])
      ])),
    );
  }
}
