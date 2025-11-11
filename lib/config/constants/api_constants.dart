import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  /// Base URL for storage images
  static final String baseStorageUrl = dotenv.env['STORAGE_URL'] ?? 'http://127.0.0.1:8000/storage';
}
