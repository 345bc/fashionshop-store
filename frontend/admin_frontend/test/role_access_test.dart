import 'package:flutter_test/flutter_test.dart';
import 'package:zella_admin_flutter/core/security/role_access.dart';

void main() {
  test('Each business role opens only its operational modules', () {
    expect(RoleAccess.canOpen('SALES', '/orders'), isTrue);
    expect(RoleAccess.canOpen('SALES', '/users'), isFalse);
    expect(RoleAccess.canOpen('WAREHOUSE', '/inventory'), isTrue);
    expect(RoleAccess.canOpen('WAREHOUSE', '/orders'), isTrue);
    expect(RoleAccess.canOpen('WAREHOUSE', '/vouchers'), isFalse);
    expect(RoleAccess.canOpen('MARKETING', '/vouchers'), isTrue);
    expect(RoleAccess.canOpen('MARKETING', '/orders'), isFalse);
    expect(RoleAccess.canOpen('CUSTOMER_SUPPORT', '/customers'), isTrue);
    expect(RoleAccess.canOpen('USER', '/orders'), isFalse);
    expect(RoleAccess.canOpen(null, '/'), isFalse);
    expect(RoleAccess.canOpen('ADMIN', '/users'), isTrue);
    expect(RoleAccess.canOpen('ADMIN', '/bought-together'), isTrue);
    expect(RoleAccess.canOpen('MARKETING', '/bought-together'), isTrue);
    for (final role in ['USER', 'SALES', 'WAREHOUSE', 'CUSTOMER_SUPPORT']) {
      expect(RoleAccess.canOpen(role, '/bought-together'), isFalse);
    }
  });
}
