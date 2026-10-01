class SizeGuideResponseModel {
  final int id;
  final String name;
  final String description;
  final String guideImageUrl;
  final bool isActive;

  const SizeGuideResponseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.guideImageUrl,
    required this.isActive,
  });

  factory SizeGuideResponseModel.fromJson(Map<String, dynamic> json) {
    return SizeGuideResponseModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      guideImageUrl: json['guideImageUrl'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'guideImageUrl': guideImageUrl,
      'isActive': isActive,
    };
  }
}
