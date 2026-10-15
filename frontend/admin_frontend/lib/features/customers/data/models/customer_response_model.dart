class CustomerResponseModel {
  final int id;
  final int userId;
  final String email;
  final String username;
  final String fullName;
  final String? phone;
  final String? address;
  final bool isActive;
  final String membershipTier;
  final int rewardPoints;
  final num totalSpending;
  final DateTime? createdAt;

  const CustomerResponseModel({
    required this.id,
    required this.userId,
    required this.email,
    required this.username,
    required this.fullName,
    this.phone,
    this.address,
    required this.isActive,
    required this.membershipTier,
    required this.rewardPoints,
    required this.totalSpending,
    this.createdAt,
  });

  factory CustomerResponseModel.fromJson(Map<String, dynamic> json) =>
      CustomerResponseModel(
        id: json['id'] as int? ?? 0,
        userId: json['userId'] as int? ?? 0,
        email: json['email'] as String? ?? '',
        username: json['username'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        membershipTier: json['membershipTier'] as String? ?? 'STANDARD',
        rewardPoints: json['rewardPoints'] as int? ?? 0,
        totalSpending: json['totalSpending'] as num? ?? 0,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}
