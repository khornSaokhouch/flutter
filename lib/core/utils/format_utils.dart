// lib/screen/order/utils/format_utils.dart
import 'package:intl/intl.dart';

// small helpers used across files

int parseIntSafe(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? 0;
}

/// Robust amount parser: accepts
/// - int cents (if inputIsCentsIfInt: true)
/// - double dollars
/// - string "12.50" (dollars) or "1250" (heuristic)
double parseAmountToDollars(dynamic v, {bool inputIsCentsIfInt = true}) {
  if (v == null) return 0.0;
  if (v is int) {
    return inputIsCentsIfInt ? (v / 100.0) : v.toDouble();
  }
  if (v is double) return v;
  if (v is String) {
    final s = v.replaceAll(',', '').trim();
    if (s.isEmpty) return 0.0;
    if (s.contains('.')) {
      final d = double.tryParse(s);
      return d ?? 0.0;
    }
    final n = int.tryParse(s);
    if (n == null) return 0.0;
    return (s.length > 3) ? (n / 100.0) : n.toDouble();
  }
  return 0.0;
}

String formatPlacedAt(String raw) {
  try {
    final dt = DateTime.tryParse(raw) ?? DateTime.parse(raw);
    return DateFormat('yyyy-MM-dd – HH:mm').format(dt);
  } catch (_) {
    return raw;
  }
}
