class UserModel {
  final int id;
  final String email;
  final String username;
  final List<String> roles;
  final String? activeRole;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.roles,
    this.activeRole,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      roles: json['roles'] != null ? List<String>.from(json['roles']) : [],
      activeRole: json['activeRole'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'roles': roles,
      'activeRole': activeRole,
    };
  }
}
