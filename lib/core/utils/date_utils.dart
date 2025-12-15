// lib/screen/order/utils/date_utils.dart
import 'package:intl/intl.dart';

String formatPlacedAtShort(DateTime dt) {
  try {
    return DateFormat('MMM dd, hh:mm a').format(dt);
  } catch (_) {
    return dt.toString();
  }
}
