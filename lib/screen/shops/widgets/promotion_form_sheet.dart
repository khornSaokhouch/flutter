import 'dart:io' show Platform;
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
  String type = "percent";
  final _valueCtrl = TextEditingController();
  final _usageCtrl = TextEditingController(text: "1");

  DateTime start = DateTime.now();
  DateTime end = DateTime.now().add(const Duration(days: 30));
  bool isActive = true;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    _usageCtrl.dispose();
    super.dispose();
  }

  // Android: date then time picker
  Future<DateTime?> _pickDateTimeMaterial(DateTime initial, {required DateTime firstDate, DateTime? lastDate}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate ?? DateTime(2100),
    );
    if (date == null) return null;

    final timeOfDay = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (timeOfDay == null) return null;

    return DateTime(date.year, date.month, date.day, timeOfDay.hour, timeOfDay.minute);
  }

  // iOS: CupertinoDatePicker in a bottom sheet (date & time mode)
  Future<DateTime?> _pickDateTimeCupertino(DateTime initial, {required DateTime minimumDate, DateTime? maximumDate}) async {
    DateTime temp = initial;
    final res = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              // handle
              Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: initial,
                  use24hFormat: false,
                  minimumDate: minimumDate,
                  maximumDate: maximumDate,
                  onDateTimeChanged: (dt) => temp = dt,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.of(ctx).pop(temp), child: const Text('Done')),
                ],
              ),
            ],
          ),
        );
      },
    );

    return res;
  }

  Future<void> _pickStart() async {
    DateTime? picked;
    if (Platform.isIOS) {
      picked = await _pickDateTimeCupertino(start, minimumDate: DateTime(2000));
    } else {
      // Android (material)
      picked = await _pickDateTimeMaterial(start, firstDate: DateTime(2000), lastDate: DateTime(2100));
    }

    if (picked != null) {
      setState(() {
        start = DateTime(picked!.year, picked.month, picked.day, picked.hour, picked.minute);
        if (!end.isAfter(start)) end = start.add(const Duration(days: 1));
      });
    }
  }

  Future<void> _pickEnd() async {
    DateTime? picked;
    if (Platform.isIOS) {
      picked = await _pickDateTimeCupertino(end, minimumDate: start.add(const Duration(minutes: 1)));
    } else {
      picked = await _pickDateTimeMaterial(end, firstDate: start.add(const Duration(days: 1)), lastDate: DateTime(2100));
    }

    if (picked != null) {
      setState(() {
        end = DateTime(picked!.year, picked.month, picked.day, picked.hour, picked.minute);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // display format for user (readable with time)
    final displayFmt = DateFormat('yyyy-MM-dd HH:mm');
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 12,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 12),
              const Text("Create Promotion", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeCtrl,
                decoration: const InputDecoration(labelText: "Code"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: type,
                      items: const [
                        DropdownMenuItem(value: "percent", child: Text("Percent")),
                        DropdownMenuItem(value: "fixed", child: Text("Fixed \$")),
                      ],
                      onChanged: (v) => setState(() => type = v ?? "percent"),
                      decoration: const InputDecoration(labelText: 'Type'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _valueCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: type == "percent" ? "Value (%)" : "Value (\$)"),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final parsed = double.tryParse(v);
                        if (parsed == null) return 'Invalid number';
                        if (type == 'percent' && (parsed <= 0 || parsed > 100)) return 'Percent must be 1–100';
                        if (parsed <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickStart,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Start',
                            hintText: displayFmt.format(start),
                            suffixIcon: const Icon(Icons.schedule),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickEnd,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'End',
                            hintText: displayFmt.format(end),
                            suffixIcon: const Icon(Icons.schedule),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Usage limit (optional)'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final parsed = int.tryParse(v);
                  if (parsed == null || parsed < 1) return 'Invalid number';
                  return null;
                },
              ),
              SwitchListTile(
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
                title: const Text("Active"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _submit,
                child: const Text("Create"),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // convert value to integer for backend (Laravel expects integer)
    final parsedValue = double.tryParse(_valueCtrl.text.trim()) ?? 0.0;
    final intValue = parsedValue.round();

    final usage = _usageCtrl.text.trim().isEmpty ? null : int.tryParse(_usageCtrl.text.trim());

    // Format dates to MySQL-friendly string: "yyyy-MM-dd HH:mm:ss"
    final backendFmt = DateFormat('yyyy-MM-dd HH:mm:ss');
    final startsAtStr = backendFmt.format(start);
    final endsAtStr = backendFmt.format(end);

    final promotion = PromotionModel(
      id: 0,
      shopid: widget.defaultShopId,
      code: _codeCtrl.text.trim(),
      type: type, // the service will map 'fixed' -> 'fixedamount' before sending
      value: intValue.toDouble(), // keep double in model but server will get integer
      startsat: startsAtStr,
      endsat: endsAtStr,
      isactive: isActive ? 1 : 0,
      usagelimit: usage,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      shop: null,
    );

    Navigator.pop(context, promotion);
  }
}
