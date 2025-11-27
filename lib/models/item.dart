class Item {
  final int id;
  final int categoryId;
  final String name;
  final String? description;
  final String priceCents; // keep as String if you want to preserve server format
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
    // Some APIs return null, some return empty string, some return relative path like "/uploads/.."
    final rawImage = json['image_url'];
    String? image;
    if (rawImage == null) {
      image = null;
    } else {
      final s = rawImage.toString().trim();
      image = s.isEmpty ? null : s;
    }

    return Item(
      id: json['id'] as int,
      categoryId: json['category_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      priceCents: json['price_cents']?.toString() ?? '0',
      imageUrl: image,
      isAvailable: json['is_available'] as int?,
    );
  }
}
