// GENERATED FROM TEMPLATE: templates/feature_model.dart.template
class UserResponseModel {
  final int id;
  final String username;
  final String email;
  final List<String> roles;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  UserResponseModel({
    required this.id,
    required this.username,
    required this.email,
    required this.roles,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory UserResponseModel.fromJson(Map<String, dynamic> json) {
    return UserResponseModel(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      roles: json['roles'] != null ? List<String>.from(json['roles']) : [],
      isActive: json['isActive'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'roles': roles,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
