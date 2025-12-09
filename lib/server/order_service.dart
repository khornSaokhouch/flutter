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

  /// Get all orders (endpoint: /orders/all)
  Future<List<OrderModel>> getAllOrders({String? token}) async {
    final uri = Uri.parse('$baseUrl/orders/all');

    final headers = token == null
        ? ApiConfig.headers
        : await ApiConfig.authHeaders(token);

    final res = await http.get(uri, headers: headers);

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);

      List<dynamic> list = [];

      // Handle several common API shapes:
      // 1) { "data": [ ... ] }
      // 2) { "data": { "data": [ ... ], "meta": { ... } } } (paginated)
      // 3) [ ... ] (top-level list)
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is List) {
          list = data;
        } else if (data is Map<String, dynamic> && data['data'] is List) {
          list = data['data'] as List<dynamic>;
        } else if (data == null) {
          // sometimes API returns top-level list inside other key names; try fallback:
          list = [];
        } else {
          // unknown structure; try to coerce a single object into a list
          if (data is Map<String, dynamic>) {
            list = [data];
          }
        }
      } else {
        throw Exception('getAllOrders failed: unexpected response shape: ${res.body}');
      }

      return list.map((e) {
        if (e is Map<String, dynamic>) {
          return OrderModel.fromJson(e);
        } else if (e is Map) {
          // cast if necessary
          return OrderModel.fromJson(Map<String, dynamic>.from(e));
        } else {
          throw Exception('getAllOrders failed: unexpected list element: $e');
        }
      }).toList();
    } else {
      throw Exception('getAllOrders failed: ${res.statusCode} ${res.body}');
    }
  }

  /// Update order with partial fields. `updates` should be a Map of fields to change.
  Future<OrderModel> updateOrder(int id, Map<String, dynamic> updates, {String? token}) async {
    final uri = Uri.parse('$baseUrl/orders/$id');

    final headers = token == null
        ? ApiConfig.headers
        : await ApiConfig.authHeaders(token);

    final res = await http.patch(uri, headers: headers, body: json.encode(updates));

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
        return OrderModel.fromJson(decoded['data'] as Map<String, dynamic>);
      } else {
        throw Exception('updateOrder failed: unexpected response shape: ${res.body}');
      }
    } else {
      throw Exception('updateOrder failed: ${res.statusCode} ${res.body}');
    }
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
