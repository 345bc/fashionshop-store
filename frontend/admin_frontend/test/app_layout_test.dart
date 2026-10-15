import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zella_admin_flutter/features/auth/presentation/provider/auth_provider.dart';

import 'support/fake_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zella_admin_flutter/widgets/app_layout.dart';

void main() {
  setUpAll(
    () => dotenv.loadFromString(
      envString: 'API_BASE_URL=http://localhost:8080/api/v1',
    ),
  );
  testWidgets('Sidebar closes, opens and retains navigation', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? route;
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => FakeAuth(),
        child: MaterialApp(
          home: AppLayout(
            currentRoute: '/orders',
            onNavigate: (value, [args]) => route = value,
            child: const SizedBox(key: ValueKey('content')),
          ),
        ),
      ),
    );
    final originalWidth = tester
        .getSize(find.byKey(const ValueKey('content')))
        .width;
    await tester.tap(find.byTooltip('Thu gọn sidebar'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('content'))).width,
      greaterThan(originalWidth),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Đơn hàng'));
    expect(route, '/orders');
    expect(find.text('Đơn hàng'), findsNothing);
    await tester.tap(find.byTooltip('Mở sidebar'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('content'))).width,
      originalWidth,
    );
    await tester.tap(find.text('Đơn hàng'));
    expect(route, '/orders');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Assigned ADMIN role does not expose admin menus while SALES is active',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = FakeAuth(role: 'SALES');
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: MaterialApp(
            home: AppLayout(
              currentRoute: '/orders',
              onNavigate: (route, [args]) {},
              child: const SizedBox(),
            ),
          ),
        ),
      );
      expect(find.text('Đơn hàng'), findsOneWidget);
      expect(find.text('Tài khoản'), findsNothing);
      expect(find.text('Tồn kho'), findsNothing);
      auth.role = 'WAREHOUSE';
      auth.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('Đơn hàng'), findsOneWidget);
      expect(find.text('Tồn kho'), findsOneWidget);
      expect(find.text('Hoàn hàng'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      auth.dispose();
    },
  );
}
