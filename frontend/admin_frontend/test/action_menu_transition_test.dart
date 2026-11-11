import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zella_admin_flutter/widgets/common/action_menu.dart';

void main() {
  testWidgets('selection opens its dialog once and the popup is removed after settling', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ActionMenu(
                trigger: const Text('Mở menu'),
                items: const [
                  ActionMenuItem(value: 'edit', label: 'Chỉnh sửa'),
                ],
                onSelected: (_) {
                  calls++;
                  showDialog<void>(
                    context: context,
                    builder: (_) =>
                        const AlertDialog(title: Text('Form sản phẩm')),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở menu'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    await tester.tap(find.text('Chỉnh sửa'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Chỉnh sửa'), findsNothing);
    expect(find.text('Form sản phẩm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dismissing the popup does not run an action', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ActionMenu(
              trigger: const Text('Mở menu'),
              items: const [ActionMenuItem(value: 'edit', label: 'Chỉnh sửa')],
              onSelected: (_) => calls++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở menu'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('Chỉnh sửa'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
