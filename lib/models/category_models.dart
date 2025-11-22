class Category {
  final int id;
  final String name;
  final int status;
  final String imageCategory;
  final String createdAt;
  final String updatedAt;
  final String imageCategoryUrl;

  Category({
    required this.id,
    required this.name,
    required this.status,
    required this.imageCategory,
    required this.createdAt,
    required this.updatedAt,
    required this.imageCategoryUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      imageCategory: json['image_category'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      imageCategoryUrl: json['image_category_url'],
    );
  }
}
