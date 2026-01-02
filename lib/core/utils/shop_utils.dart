// shop_utils.dart
import '../../core/utils/utils.dart'; // assumes parseTimeToSeconds, formatTimeString exist here

class _ShopOpenStatus {
  final bool isOpen;
  final String? opensAtFormatted;
  final String? closesAtFormatted;
  _ShopOpenStatus({required this.isOpen, this.opensAtFormatted, this.closesAtFormatted});
}

_ShopOpenStatus evaluateShopOpenStatus(String? openTimeStr, String? closeTimeStr) {
  if ((openTimeStr == null || openTimeStr.trim().isEmpty) || (closeTimeStr == null || closeTimeStr.trim().isEmpty)) {
    return _ShopOpenStatus(isOpen: true, opensAtFormatted: null, closesAtFormatted: null);
  }

  final openSeconds = parseTimeToSeconds(openTimeStr);
  final closeSeconds = parseTimeToSeconds(closeTimeStr);
  if (openSeconds == null || closeSeconds == null) {
    return _ShopOpenStatus(isOpen: true, opensAtFormatted: null, closesAtFormatted: null);
  }

  final now = DateTime.now();
  final nowSeconds = now.hour * 3600 + now.minute * 60 + now.second;

  bool isOpen;
  if (openSeconds < closeSeconds) {
    isOpen = (nowSeconds >= openSeconds && nowSeconds < closeSeconds);
  } else if (openSeconds > closeSeconds) {
    isOpen = (nowSeconds >= openSeconds) || (nowSeconds < closeSeconds);
  } else {
    isOpen = true;
  }

  final opensAtFormatted = formatTimeString(openTimeStr);
  final closesAtFormatted = formatTimeString(closeTimeStr);

  return _ShopOpenStatus(isOpen: isOpen, opensAtFormatted: opensAtFormatted, closesAtFormatted: closesAtFormatted);
}
