import 'package:intl/intl.dart';

String money(num value) => NumberFormat.currency(
  locale: 'vi_VN',
  symbol: 'đ',
  decimalDigits: 0,
).format(value);

class InventoryResponseModel {
  final int variantId, stockQuantity, reservedQuantity, availableQuantity;
  final String sku,
      productName,
      categoryName,
      supplierName,
      sizeName,
      colorName;
  final num costPrice, price;
  final bool isActive;
  final int? supplierId;
  InventoryResponseModel(Map<String, dynamic> json)
    : variantId = json['variantId'] as int,
      supplierId = json['supplierId'] as int?,
      stockQuantity = json['stockQuantity'] as int,
      reservedQuantity = json['reservedQuantity'] as int,
      availableQuantity = json['availableQuantity'] as int,
      sku = json['sku'] as String,
      productName = json['productName'] as String,
      categoryName = json['categoryName'] as String,
      supplierName = json['supplierName'] as String,
      sizeName = json['sizeName'] as String,
      colorName = json['colorName'] as String,
      costPrice = json['costPrice'] as num,
      price = json['price'] as num? ?? 0,
      isActive = json['isActive'] as bool;
  String get label => '$productName — $sizeName / $colorName ($sku)';
}
