class CategoryResponseModel {
  final int id;
  final String name;
  final String slug;
  final bool isActive;
  final int? parentId;
  final String? parentName;
  final String? imageUrl;

  const CategoryResponseModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
    this.parentId,
    this.parentName,
    this.imageUrl,
  });

  factory CategoryResponseModel.fromJson(Map<String, dynamic> json) {
    return CategoryResponseModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      parentId: (json['parentId'] as num?)?.toInt(),
      parentName: json['parentName'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'isActive': isActive,
      'parentId': parentId,
      'parentName': parentName,
      'imageUrl': imageUrl,
    };
  }
}
