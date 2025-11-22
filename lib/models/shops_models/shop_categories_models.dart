class CategoryModel {
  final int id;
  final String name;
  final int status;
  final String imageCategory;
  final String createdAt;
  final String updatedAt;
  final String imageCategoryUrl;
  final PivotModel? pivot;

  CategoryModel({
    required this.id,
    required this.name,
    required this.status,
    required this.imageCategory,
    required this.createdAt,
    required this.updatedAt,
    required this.imageCategoryUrl,
    this.pivot,
  });

  CategoryModel copyWith({
    int? id,
    String? name,
    int? status,
    String? imageCategory,
    String? createdAt,
    String? updatedAt,
    String? imageCategoryUrl,
    PivotModel? pivot,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      imageCategory: imageCategory ?? this.imageCategory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageCategoryUrl: imageCategoryUrl ?? this.imageCategoryUrl,
      pivot: pivot ?? this.pivot,
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      imageCategory: json['image_category'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      imageCategoryUrl: json['image_category_url'],
      pivot: json['pivot'] != null ? PivotModel.fromJson(json['pivot']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'image_category': imageCategory,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'image_category_url': imageCategoryUrl,
      'pivot': pivot?.toJson(),
    };
  }
}

class PivotModel {
  final int shopId;
  final int categoryId;
  final int status;
  final String createdAt;
  final String updatedAt;

  PivotModel({
    required this.shopId,
    required this.categoryId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  PivotModel copyWith({
    int? shopId,
    int? categoryId,
    int? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return PivotModel(
      shopId: shopId ?? this.shopId,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PivotModel.fromJson(Map<String, dynamic> json) {
    return PivotModel(
      shopId: json['shop_id'],
      categoryId: json['category_id'],
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shop_id': shopId,
      'category_id': categoryId,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
