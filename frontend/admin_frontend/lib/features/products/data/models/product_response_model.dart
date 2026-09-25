import 'package:zella_admin_flutter/features/categories/data/models/category_response_model.dart';
import 'package:zella_admin_flutter/features/categories/sizeguide/data/size_guide_response_model.dart';
import 'package:zella_admin_flutter/features/suppliers/data/models/supplier_response_model.dart';

class ProductResponseModel {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String style;
  final String occasion;
  final double basePrice;
  final bool isActive;
  final CategoryResponseModel? category;
  final SupplierResponseModel? supplier;
  final SizeGuideResponseModel? sizeGuide;
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
    this.category,
    this.supplier,
    this.sizeGuide,
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
      category: json['categoryId'] is Map<String, dynamic>
          ? CategoryResponseModel.fromJson(
              json['categoryId'] as Map<String, dynamic>,
            )
          : null,
      supplier: json['supplierId'] is Map<String, dynamic>
          ? SupplierResponseModel.fromJson(
              json['supplierId'] as Map<String, dynamic>,
            )
          : null,
      sizeGuide: json['sizeGuideId'] is Map<String, dynamic>
          ? SizeGuideResponseModel.fromJson(
              json['sizeGuideId'] as Map<String, dynamic>,
            )
          : null,
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
      'categoryId': category?.toJson(),
      'supplierId': supplier?.toJson(),
      'sizeGuideId': sizeGuide?.toJson(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
