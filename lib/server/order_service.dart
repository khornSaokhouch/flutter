// lib/services/order_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_endpoints.dart';
import '../models/order_model.dart';

class OrderService {
  final String baseUrl = ApiConfig.baseUrl; // from your ApiConfig

  /// Create a new order. Pass an optional bearer token for auth; if not provided,
  /// we'll try to read it from SharedPreferences. Throws if no token available.
  /// Returns the created OrderModel on success.
  /// OrderService.createOrder — builds payload matching Laravel store(Request $request)
  Future<OrderModel> createOrder(OrderModel order, {String? promocode}) async {
    // require token (or change to accept token param)
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw Exception('Missing auth token — please login.');
    }

    final uri = Uri.parse('$baseUrl/users/orders'); // adjust endpoint if needed

    // headers
    final headers = await ApiConfig.authHeaders(token);
    headers['Accept'] = 'application/json';
    headers['Content-Type'] = 'application/json';

    // Helper to serialize option groups to backend shape
    List<Map<String, dynamic>> _serializeOptionGroups(List<OptionGroupModel>? groups) {
      if (groups == null) return [];
      return groups.map((g) => {
        'group_id': g.groupId,
        'option_id': g.optionId,
        'group_name': g.groupName,
        'selected_option': g.selectedOption,
      }).toList();
    }

    // Build items exactly as Laravel expects
    final items = (order.orderItems ?? []).map((it) {
      return {
        'itemid': it.itemid,
        'unitprice_cents': it.unitpriceCents,
        'quantity': it.quantity,
        if ((it.namesnapshot ?? '').isNotEmpty) 'namesnapshot': it.namesnapshot,
        if ((it.notes ?? '').isNotEmpty) 'notes': it.notes,
        // include option_groups only when not empty
        if ((it.optionGroups ?? []).isNotEmpty) 'option_groups': _serializeOptionGroups(it.optionGroups),
      };
    }).toList();

    // Build body matching your Laravel validator
    final body = <String, dynamic>{
      'userid': order.userid,
      'shopid': order.shopid,
      // include placedat only if you want server to use your supplied datetime
      if (order.placedat != null && order.placedat.toString().isNotEmpty) 'placedat': order.placedat,
      if (order.promoid != null) 'promoid': order.promoid, // optional
      if (promocode != null && promocode.isNotEmpty) 'promocode': promocode, // optional
      'items': items,
    };

    final res = await http.post(uri, headers: headers, body: jsonEncode(body));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        // controller returns the saved order in 'data'
        final data = decoded['data'] ?? decoded;
        if (data is Map<String, dynamic>) return OrderModel.fromJson(data);
      }
      throw Exception('Unexpected createOrder response: ${res.body}');
    } else if (res.statusCode == 422) {
      // validation errors from Laravel
      final decoded = jsonDecode(res.body);
      // surface Laravel validation messages if available
      final errors = decoded['errors'] ?? decoded['message'] ?? res.body;
      throw Exception('Validation failed: $errors');
    } else {
      throw Exception('createOrder failed: ${res.statusCode} ${res.body}');
    }
  }
  static Future<List<OrderModel>> fetchAllOrders({required int userid}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // 1️⃣ Build the correct endpoint with ?userid=
    final uri = Uri.parse('${ApiConfig.baseUrl}/users/orders/all')
        .replace(queryParameters: {'userid': userid.toString()});

    // 2️⃣ Set auth or normal headers
    final headers = token == null
        ? ApiConfig.headers
        : await ApiConfig.authHeaders(token);

    // 3️⃣ Call API
    final response = await http.get(uri, headers: headers);

    // 4️⃣ Parse
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // If API returns a raw list
      if (decoded is List) {
        return decoded
            .map<OrderModel>((e) => OrderModel.fromJson(e))
            .toList();
      }

      // If API returns "data": [...]
      if (decoded is Map && decoded['data'] is List) {
        return (decoded['data'] as List)
            .map<OrderModel>((e) => OrderModel.fromJson(e))
            .toList();
      }

      throw Exception('Unexpected JSON format');
    } else {
      throw Exception(
          'Failed to load orders: ${response.statusCode} ${response.body}');
    }
  }

  static Future<List<OrderModel>> fetchAllOrdersForShop({required int shopid}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // 1️⃣ Build the correct endpoint with ?userid=
    final uri = Uri.parse('${ApiConfig.baseUrl}/users/orders/all')
        .replace(queryParameters: {'shopid': shopid.toString()});

    // 2️⃣ Set auth or normal headers
    final headers = token == null
        ? ApiConfig.headers
        : await ApiConfig.authHeaders(token);

    // 3️⃣ Call API
    final response = await http.get(uri, headers: headers);
    // 4️⃣ Parse
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // If API returns a raw list
      if (decoded is List) {
        return decoded
            .map<OrderModel>((e) => OrderModel.fromJson(e))
            .toList();
      }

      // If API returns "data": [...]
      if (decoded is Map && decoded['data'] is List) {
        return (decoded['data'] as List)
            .map<OrderModel>((e) => OrderModel.fromJson(e))
            .toList();
      }

      throw Exception('Unexpected JSON format');
    } else {
      throw Exception(
          'Failed to load orders: ${response.statusCode} ${response.body}');
    }
  }




  /// Get single order by id. Optional token override.
  Future<OrderModel> getOrder(int id, {String? token}) async {
    final uri = Uri.parse('$baseUrl/orders/$id');

    final headers = token == null
        ? ApiConfig.headers
        : await ApiConfig.authHeaders(token);

    final res = await http.get(uri, headers: headers);

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          return OrderModel.fromJson(data);
        } else {
          throw Exception('getOrder failed: unexpected "data" shape: ${res.body}');
        }
      } else {
        throw Exception('getOrder failed: unexpected response shape: ${res.body}');
      }
    } else {
      throw Exception('getOrder failed: ${res.statusCode} ${res.body}');
    }
  }

  /// Update order with partial fields. `updates` should be a Map of fields to change.
  Future<OrderModel> updateOrder(int id, Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final headers =
    token == null ? ApiConfig.headers : await ApiConfig.authHeaders(token);

    final uri = Uri.parse('$baseUrl/shop/orders/$id');

    final res = await http.patch(
      uri,
      headers: headers,
      body: jsonEncode(payload),
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final data = decoded['data'] ?? decoded;
      return OrderModel.fromJson(data);
    }

    if (res.statusCode == 422) {
      final decoded = jsonDecode(res.body);
      throw Exception(jsonEncode({
        'status': 422,
        'errors': decoded['errors'] ?? decoded,
      }));
    }

    throw Exception('updateOrder failed: ${res.statusCode} ${res.body}');
  }




  /// Delete an order by id
  Future<void> deleteOrder(int id, {String? token}) async {
    final uri = Uri.parse('$baseUrl/orders/$id');

    final headers = token == null
        ? ApiConfig.headers
        : await ApiConfig.authHeaders(token);

    final res = await http.delete(uri, headers: headers);

    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    } else {
      throw Exception('deleteOrder failed: ${res.statusCode} ${res.body}');
    }
  }
}
