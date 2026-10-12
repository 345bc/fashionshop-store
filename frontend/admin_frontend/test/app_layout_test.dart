import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zella_admin_flutter/widgets/app_layout.dart';

void main() {
  testWidgets('Sidebar closes, opens and retains navigation', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? route;
    await tester.pumpWidget(
      MaterialApp(
        home: AppLayout(
          currentRoute: '/orders',
          onNavigate: (value, [args]) => route = value,
          child: const SizedBox(key: ValueKey('content')),
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
}
