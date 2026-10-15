import 'package:zella_admin_flutter/features/auth/data/models/user_model.dart';
import 'package:zella_admin_flutter/features/auth/presentation/provider/auth_provider.dart';

class FakeAuth extends AuthProvider {
  FakeAuth({this.role = 'ADMIN'});
  String role;
  @override
  bool hasRole(String requested) => requested == role;
  @override
  UserModel get user => UserModel(
    id: 1,
    email: 'test@example.test',
    username: 'test',
    roles: ['ADMIN', 'SALES', 'WAREHOUSE'],
    activeRole: role,
  );
}
