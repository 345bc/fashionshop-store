class SupplierResponseModel {
  final int id;
  final String name;
  final String? code;
  final String? contactEmail;
  final String? phone;
  final String? address;
  final String? contactPerson;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SupplierResponseModel({
    required this.id,
    required this.name,
    this.code,
    this.contactEmail,
    this.phone,
    this.address,
    this.contactPerson,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory SupplierResponseModel.fromJson(Map<String, dynamic> json) {
    return SupplierResponseModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      contactEmail: json['contactEmail'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      contactPerson: json['contactPerson'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'contactEmail': contactEmail,
      'phone': phone,
      'address': address,
      'contactPerson': contactPerson,
      'isActive': isActive,
    };
  }
}
