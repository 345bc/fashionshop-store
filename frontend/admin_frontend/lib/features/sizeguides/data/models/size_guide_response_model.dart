class SizeGuideResponseModel {
  final int id;
  final String name;

  SizeGuideResponseModel({required this.id, required this.name});

  factory SizeGuideResponseModel.fromJson(Map<String, dynamic> json) {
    return SizeGuideResponseModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
