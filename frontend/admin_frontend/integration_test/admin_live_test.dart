import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zella_admin_flutter/main.dart';
import 'package:zella_admin_flutter/core/network/api_client.dart';
import 'package:zella_admin_flutter/features/auth/presentation/provider/auth_provider.dart';
import 'package:zella_admin_flutter/features/suppliers/presentation/screens/supplier_form_screen.dart';
import 'package:zella_admin_flutter/features/suppliers/presentation/providers/suppliers_provider.dart';

const evidenceRoot = 'C:/Users/Tuan/Desktop/dacn_048/test-results';
final results = <Map<String, dynamic>>[];
final captureKey = GlobalKey();

Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 45),
  );
}

Future<void> record(
  WidgetTester tester,
  String title,
  Future<void> Function() action,
) async {
  final row = <String, dynamic>{
    'title': title,
    'level': 'Flutter Windows + HTTP backend thật; preferences thử nghiệm trong bộ nhớ',
  };
  try {
    await action();
    final error = tester.takeException();
    if (error != null) throw error;
    row['status'] = 'Pass';
  } catch (e) {
    row['status'] = 'Fail';
    row['actual'] = '$e';
    while (tester.takeException() != null) {}
    if (find.byType(SupplierFormScreen).evaluate().isNotEmpty) {
      Navigator.of(tester.element(find.byType(SupplierFormScreen))).pop();
      await settle(tester);
    }
  }
  results.add(row);
  print('${row['status']}: $title');
  File('$evidenceRoot/admin-windows-live-20261105.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ')
        .convert({'date': '2026-11-05', 'results': results}),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Admin Windows real backend workflows and screen matrix', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(
      envString: 'API_BASE_URL=http://127.0.0.1:18080/api/v1',
    );
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixtures = jsonDecode(
      File('$evidenceRoot/live-fixtures.json').readAsStringSync(),
    );
    await tester.pumpWidget(
      RepaintBoundary(key: captureKey, child: const ZellaAdminApp()),
    );
    await settle(tester);
    await record(
      tester,
      'Đăng nhập và chọn vai trò admin qua backend thật',
      () async {
        await tester.enterText(
          find.byType(TextFormField).at(0),
          fixtures['accounts']['admin']['email'],
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'TestPassword123!',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
        await settle(tester);
        if (find.text('Chọn vai trò làm việc').evaluate().isNotEmpty) {
          await tester.tap(
            find.widgetWithText(OutlinedButton, 'Quản trị viên'),
          );
          await settle(tester);
        }
        expect(find.byType(MainScreen), findsOneWidget);
        final auth = tester
            .element(find.byType(MainScreen))
            .read<AuthProvider>();
        expect(auth.user!.activeRole, 'ADMIN');
      },
    );
    if (find.byType(MainScreen).evaluate().isEmpty) {
      fail('Login failed; operational screens were not exercised');
    }
    await record(
      tester,
      'Thêm NCC chỉ nhập tên, để trống các trường tùy chọn',
      () async {
        final state = tester.state<MainScreenState>(find.byType(MainScreen));
        state.navigate('/suppliers');
        await settle(tester);
        final context = tester.element(find.byType(MainScreen));
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (routeContext) => ChangeNotifierProvider<SuppliersProvider>.value(
              value: context.read<SuppliersProvider>(),
              child: SupplierFormScreen(
                onClose: () => Navigator.of(routeContext).pop(),
              ),
            ),
          ),
        );
        await settle(tester);
        final name = 'NCC giao diện ${DateTime.now().millisecondsSinceEpoch}';
        await tester.enterText(find.byType(TextFormField).first, name);
        await tester.ensureVisible(
          find.descendant(
            of: find.byType(SupplierFormScreen),
            matching: find.widgetWithText(FilledButton, 'Thêm nhà cung cấp'),
          ),
        );
        await tester.tap(
          find.descendant(
            of: find.byType(SupplierFormScreen),
            matching: find.widgetWithText(FilledButton, 'Thêm nhà cung cấp'),
          ),
        );
        await settle(tester);
        expect(find.byType(SupplierFormScreen), findsNothing);
        final response = await ApiClient().get(
          '/supplier',
          queryParameters: {'q': name},
        );
        final content = response.data['data']['content'] as List;
        expect(content.length, 1);
        expect(content.first['name'], name);
        await ApiClient().delete('/supplier/${content.first['id']}');
      },
    );
    await record(
      tester,
      'Thêm NCC có email và điện thoại hợp lệ qua UI và đối chiếu API',
      () async {
        final context = tester.element(find.byType(MainScreen));
        final provider = context.read<SuppliersProvider>();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (routeContext) => ChangeNotifierProvider<SuppliersProvider>.value(
              value: provider,
              child: SupplierFormScreen(
                onClose: () => Navigator.of(routeContext).pop(),
              ),
            ),
          ),
        );
        await settle(tester);
        final name =
            'NCC đủ thông tin ${DateTime.now().millisecondsSinceEpoch}';
        final fields = find.descendant(
          of: find.byType(SupplierFormScreen),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(fields.at(0), name);
        await tester.enterText(fields.at(2), 'admin-ui@example.test');
        await tester.enterText(fields.at(3), '0901234567');
        final button = find.descendant(
          of: find.byType(SupplierFormScreen),
          matching: find.widgetWithText(FilledButton, 'Thêm nhà cung cấp'),
        );
        await tester.ensureVisible(button);
        await tester.tap(button);
        await settle(tester);
        expect(find.byType(SupplierFormScreen), findsNothing);
        final response = await ApiClient().get(
          '/supplier',
          queryParameters: {'q': name},
        );
        final content = response.data['data']['content'] as List;
        expect(content.length, 1);
        expect(content.first['name'], name);
        await ApiClient().delete('/supplier/${content.first['id']}');
      },
    );
    const routes = [
      '/',
      '/products',
      '/categories',
      '/colors',
      '/sizes',
      '/sizeguides',
      '/inventory',
      '/purchases',
      '/suppliers',
      '/customers',
      '/orders',
      '/feedback',
      '/staff',
      '/users',
      '/posts',
      '/post-categories',
      '/promotions',
      '/vouchers',
      '/promotion-programs',
      '/bought-together',
      '/home-appearance',
      '/reports',
    ];
    for (final width in [1600, 1280, 800]) {
      tester.view.physicalSize = Size(width.toDouble(), 1100);
      for (final route in routes) {
        await record(tester, 'Màn hình $route ở chiều rộng $width px', () async {
          final state = tester.state<MainScreenState>(find.byType(MainScreen));
          state.navigate(route);
          await settle(tester);
          expect(find.textContaining('chưa được triển khai'), findsNothing);
          final exceptions = <String>[];
          Object? error;
          while ((error = tester.takeException()) != null) {
            exceptions.add('$error');
          }
          expect(exceptions, isEmpty);
          // Pixel evidence from the running Windows application's render tree.
          final boundary =
              captureKey.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final folder = Directory('$evidenceRoot/admin-windows-live');
          folder.createSync(recursive: true);
          final slug = route == '/' ? 'dashboard' : route.substring(1);
          File('${folder.path}/${width}_$slug.png')
              .writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
    await record(tester, 'Đăng xuất kết thúc phiên thật', () async {
      final auth = tester.element(find.byType(MainScreen)).read<AuthProvider>();
      await auth.logout();
      await settle(tester);
      expect(find.byType(MainScreen), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Đăng nhập'), findsOneWidget);
    });
    expect(
      results.where((r) => r['status'] == 'Fail'),
      isEmpty,
      reason: 'See admin-windows-live-20261105.json for individual failures',
    );
  });
}
