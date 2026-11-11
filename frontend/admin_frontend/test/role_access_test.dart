import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zella_admin_flutter/core/security/role_access.dart';
import 'package:zella_admin_flutter/features/auth/presentation/provider/auth_provider.dart';
import 'package:zella_admin_flutter/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:zella_admin_flutter/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:zella_admin_flutter/features/promotions/presentation/screens/promotions_screen.dart';
import 'package:zella_admin_flutter/main.dart';
import 'package:zella_admin_flutter/screens/unauthorized_screen.dart';

import 'support/fake_auth.dart';

class _FakeInventory extends InventoryProvider {
  @override
  Future<void> loadItems() async {}

  @override
  Future<({int lowStock, int outOfStock})> stockAlerts() async =>
      (lowStock: 0, outOfStock: 0);
}

void main() {
  testWidgets('Sidebar shows restricted modules and opens 403 on click', (
    tester,
  ) async {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:8080/api/v1');
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => FakeAuth(role: 'WAREHOUSE'),
          ),
          ChangeNotifierProvider<InventoryProvider>(
            create: (_) => _FakeInventory(),
          ),
        ],
        child: const MaterialApp(home: MainScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final promotions = find.text('Voucher & Khuyến mãi');
    expect(promotions, findsOneWidget);
    await tester.tap(promotions);
    await tester.pumpAndSettle();
    expect(find.byType(UnauthorizedScreen), findsOneWidget);
    expect(find.byType(PromotionsScreen), findsNothing);

    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.byType(InventoryScreen), findsOneWidget);

    await tester.tap(promotions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Về trang chủ'));
    await tester.pumpAndSettle();
    expect(find.byType(InventoryScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('Superadmin opens all back office modules', () {
    for (final route in [
      '/',
      '/reports',
      '/users',
      '/orders',
      '/inventory',
      '/products/edit',
      '/bought-together',
    ]) {
      expect(RoleAccess.canOpen('SUPERADMIN', route), isTrue, reason: route);
    }
    expect(RoleAccess.isBackOfficeRole('SUPERADMIN'), isTrue);
    expect(RoleAccess.isBackOfficeRole('USER'), isFalse);
    expect(RoleAccess.home('SUPERADMIN'), '/');
  });

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
    expect(RoleAccess.canOpen('MARKETING', '/bought-together'), isTrue);
    for (final role in ['USER', 'SALES', 'WAREHOUSE', 'CUSTOMER_SUPPORT']) {
      expect(RoleAccess.canOpen(role, '/bought-together'), isFalse);
    }
  });

  test('Admin opens overview, customer, account, staff and report modules', () {
    for (final route in ['/', '/customers', '/users', '/staff', '/reports']) {
      expect(RoleAccess.canOpen('ADMIN', route), isTrue, reason: route);
    }
    for (final route in [
      '/orders',
      '/inventory',
      '/products',
      '/products/edit',
      '/purchases',
      '/feedback',
      '/bought-together',
      '/promotions',
      '/home-appearance',
    ]) {
      expect(RoleAccess.canOpen('ADMIN', route), isFalse, reason: route);
    }
    expect(RoleAccess.home('ADMIN'), '/reports');
  });
}
