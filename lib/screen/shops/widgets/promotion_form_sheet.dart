import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/promotion_model.dart';

class PromotionFormSheet extends StatefulWidget {
  final int defaultShopId;
  const PromotionFormSheet({super.key, required this.defaultShopId});

  @override
  State<PromotionFormSheet> createState() => _PromotionFormSheetState();
}

class _PromotionFormSheetState extends State<PromotionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _usageCtrl = TextEditingController(text: "100");
  
  String type = "percent";
  DateTime start = DateTime.now();
  DateTime end = DateTime.now().add(const Duration(days: 30));
  bool isActive = true;

  final Color _emerald = const Color(0xFF2D6A4F);
  final Color _mint = const Color(0xFF52B788);

  @override
  Widget build(BuildContext context) {
    final displayFmt = DateFormat('MMM dd, yyyy');

    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 24, right: 24, top: 12),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 20),
              Text("Create Promotion", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _emerald)),
              const SizedBox(height: 20),
              
              _buildField(_codeCtrl, "Promo Code", Icons.confirmation_number_outlined, hint: "SUMMER2024"),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: type,
                      decoration: _inputDecoration("Type", Icons.tune),
                      items: const [
                        DropdownMenuItem(value: "percent", child: Text("Percent %")),
                        DropdownMenuItem(value: "fixed", child: Text("Fixed \$")),
                      ],
                      onChanged: (v) => setState(() => type = v ?? "percent"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField(_valueCtrl, "Value", Icons.add_chart, keyboard: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(child: _buildPicker("Start Date", displayFmt.format(start), _pickStart)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildPicker("End Date", displayFmt.format(end), _pickEnd)),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildField(_usageCtrl, "Usage Limit", Icons.group_outlined, keyboard: TextInputType.number),
              
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
                title: const Text("Activate Now", style: TextStyle(fontWeight: FontWeight.bold)),
                activeColor: _mint,
              ),
              
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _emerald,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("SAVE PROMOTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {String? hint, TextInputType? keyboard}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: _inputDecoration(label, icon).copyWith(hintText: hint),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }

  Widget _buildPicker(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(decoration: _inputDecoration(label, Icons.calendar_month), child: Text(value, style: const TextStyle(fontSize: 13))),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _emerald, fontWeight: FontWeight.bold),
      prefixIcon: Icon(icon, color: _mint, size: 20),
      filled: true,
      fillColor: _emerald.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(context: context, initialDate: start, firstDate: DateTime.now(), lastDate: DateTime(2100));
    if (picked != null) setState(() => start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(context: context, initialDate: end, firstDate: start, lastDate: DateTime(2100));
    if (picked != null) setState(() => end = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final backendFmt = DateFormat('yyyy-MM-dd HH:mm:ss');
    final promo = PromotionModel(
      id: 0,
      shopid: widget.defaultShopId,
      code: _codeCtrl.text.toUpperCase(),
      type: type,
      value: double.tryParse(_valueCtrl.text) ?? 0,
      startsat: backendFmt.format(start),
      endsat: backendFmt.format(end),
      isactive: isActive ? 1 : 0,
      usagelimit: int.tryParse(_usageCtrl.text),
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    Navigator.pop(context, promo);
  }
}