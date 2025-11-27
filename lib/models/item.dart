class Item {
  final int id;
  final int categoryId;
  final String name;
  final String? description;
  final String priceCents; // <--- keep as String
  final String? imageUrl;
  final int? isAvailable;

  Item({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.priceCents,
    this.imageUrl,
    this.isAvailable,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int,
      categoryId: json['category_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      priceCents: json['price_cents'].toString(), // <-- convert to string
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] as int?,
    );
  }
}
