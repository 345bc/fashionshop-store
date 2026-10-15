class ProductResponseModel {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String style;
  final String occasion;
  final double basePrice;
  final bool isActive;
  final int categoryId;
  final String categoryName;
  final int supplierId;
  final String supplierName;
  final int sizeGuideId;
  final String sizeGuideName;
  final String? createdAt;
  final String? updatedAt;

  const ProductResponseModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.style,
    required this.occasion,
    required this.basePrice,
    required this.isActive,
    required this.categoryId,
    required this.categoryName,
    required this.sizeGuideId,
    required this.sizeGuideName,
    required this.supplierId,
    required this.supplierName,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductResponseModel.fromJson(Map<String, dynamic> json) {
    return ProductResponseModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      style: json['style'] as String? ?? '',
      occasion: json['occasion'] as String? ?? '',
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? false,
      categoryId: json['categoryId'] as int? ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
      supplierId: json['supplierId'] as int? ?? 0,
      supplierName: json['supplierName'] as String? ?? '',
      sizeGuideId: json['sizeGuideId'] as int? ?? 0,
      sizeGuideName: json['sizeGuideName'] as String? ?? '',

      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'style': style,
      'occasion': occasion,
      'basePrice': basePrice,
      'isActive': isActive,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'sizeGuideId': sizeGuideId,
      'sizeGuideName': sizeGuideName,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
