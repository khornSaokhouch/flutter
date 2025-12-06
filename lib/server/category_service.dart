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
print('Fetching categories from: $url');

  final response = await http.get(Uri.parse(url), headers: ApiConfig.headers);

  print('Response status: ${response.statusCode}');
  print('Response body: ${response.body}');

  if (response.statusCode == 200) {
    final decoded = json.decode(response.body);

    final List dataList = decoded is Map<String, dynamic>
        ? (decoded['data'] as List? ?? [])
        : (decoded as List);

    final categories = dataList
        .map((item) => Category.fromJson(item as Map<String, dynamic>))
        .toList();

    print('Categories parsed successfully');
    return categories;
  } else {
    print('Failed to fetch categories: ${response.statusCode}');
    return [];
  }
} catch (e, stackTrace) {
  print('Error fetching categories: $e');
  print(stackTrace);
  return [];
}

}

// Fetch items by category ID
static Future<List<Item>> fetchItemsByCategory(int categoryId) async {
try {
final url = '${ApiConfig.baseUrl}/shops/category/$categoryId';
print('Fetching items from: $url');


  final response = await http.get(Uri.parse(url), headers: ApiConfig.headers);

  print('Response status: ${response.statusCode}');
  print('Response body: ${response.body}');

  if (response.statusCode == 200) {
    final decoded = json.decode(response.body);
    final List itemsData = decoded['data'] as List? ?? [];

    final items = itemsData
        .map((item) => Item.fromJson(item as Map<String, dynamic>))
        .toList();

    print('Items parsed successfully for category $categoryId');
    return items;
  } else {
    print('Failed to fetch items: ${response.statusCode}');
    return [];
  }
} catch (e, stackTrace) {
  print('Error fetching items: $e');
  print(stackTrace);
  return [];
}

}
}
