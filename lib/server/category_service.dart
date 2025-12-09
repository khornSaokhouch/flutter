import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_endpoints.dart';
import '../models/category_models.dart';
import '../models/item.dart';

class CategoryService {
// Fetch all categories
static Future<List<Category>> fetchCategories() async {
try {
final url = '${ApiConfig.baseUrl}/shops/categories';

  final response = await http.get(Uri.parse(url), headers: ApiConfig.headers);



  if (response.statusCode == 200) {
    final decoded = json.decode(response.body);

    final List dataList = decoded is Map<String, dynamic>
        ? (decoded['data'] as List? ?? [])
        : (decoded as List);

    final categories = dataList
        .map((item) => Category.fromJson(item as Map<String, dynamic>))
        .toList();

    return categories;
  } else {
    return [];
  }
} catch (e) {
  return [];
}

}

// Fetch items by category ID
static Future<List<Item>> fetchItemsByCategory(int categoryId) async {
try {
final url = '${ApiConfig.baseUrl}/shops/category/$categoryId';

  final response = await http.get(Uri.parse(url), headers: ApiConfig.headers);

  if (response.statusCode == 200) {
    final decoded = json.decode(response.body);
    final List itemsData = decoded['data'] as List? ?? [];

    final items = itemsData
        .map((item) => Item.fromJson(item as Map<String, dynamic>))
        .toList();
    return items;
  } else {
    return [];
  }
} catch (e) {
  return [];
}

}
}
