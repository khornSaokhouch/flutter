import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_endpoints.dart';
import '../../response/shops_response/shop_response.dart';

class ShopsService {
  /// Fetch shops for the authenticated owner
  static Future<ShopResponse> getShopsByOwner() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // 🔐 No token saved
    if (token == null || token.isEmpty) {
      throw Exception('No auth token found. Please log in again.');
    }

    // ⚠️ Make sure this matches your Laravel route:
    // Route::get('/shops/owner', ...) -> '/shops/owner' (plural)
    final url = Uri.parse('${ApiConfig.baseUrl}/shop/owner');

    final headers = await ApiConfig.authHeaders(token);

    final response = await http.get(url, headers: headers);

    // ✅ Success
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonBody = json.decode(response.body);
      return ShopResponse.fromJson(jsonBody);
    }

    // 🕳️ No shops found (your controller returns 404 with message)
    if (response.statusCode == 404) {
      try {
        final Map<String, dynamic> jsonBody = json.decode(response.body);
        return ShopResponse(
          message: jsonBody['message'] ?? 'No shops found for your account.',
          data: [],
        );
      } catch (_) {
        return ShopResponse(
          message: 'No shops found for your account.',
          data: [],
        );
      }
    }

    // 🔑 Unauthorized
    if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please log in again.');
    }

    // 💥 Other server errors
    throw Exception(
      'Failed to load shops: [${response.statusCode}] ${response.body}',
    );
  }

  static Future<ShopResponse> updateShop({
    required int shopId,
    required Map<String, dynamic> payload,
    File? imageFile, // Add this parameter
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('No auth token found. Please log in again.');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/shop/$shopId');

    // 1. Create Multipart Request
    var request = http.MultipartRequest('POST', url);

    // 2. Add Auth Headers
    final authHeaders = await ApiConfig.authHeaders(token);
    request.headers.addAll(authHeaders);
    // Important: Remove content-type if authHeaders sets it to application/json
    request.headers.remove('Content-Type');

    // 3. Method spoofing for Laravel
    request.fields['_method'] = 'PUT';

    // 4. Add text payload (Convert all values to String)
    payload.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    // 5. Add Image File if exists
    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image', // Must match Laravel $request->file('image')
        imageFile.path,
      ));
    }

    // 6. Send Request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    // ✅ Success
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonBody = json.decode(response.body);
      return ShopResponse.fromJson(jsonBody);
    }

    // 🔑 Unauthorized
    if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please log in again.');
    }

    // 💥 Other errors
    throw Exception(
      'Failed to update shop: [${response.statusCode}] ${response.body}',
    );
  }


}
