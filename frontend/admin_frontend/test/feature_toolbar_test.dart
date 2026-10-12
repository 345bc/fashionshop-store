import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zella_admin_flutter/widgets/common/feature_toolbar.dart';

void main() {
  testWidgets('Search border fills the same height as the filter', (
    tester,
  ) async {
    for (final width in [700.0, 300.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: FeatureToolbar(
                  searchHint: 'Tìm theo tên, mã, email...',
                  onSearchChanged: (_) {},
                  filterWidget: const SizedBox(
                    key: ValueKey('filter'),
                    height: 38,
                    width: 110,
                    child: Center(child: Text('Trạng thái')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(InputDecorator)).height, 38);
      expect(tester.getSize(find.byKey(const ValueKey('filter'))).height, 38);
      if (width == 700) {
        expect(
          tester.getTopLeft(find.byType(InputDecorator)).dy,
          tester.getTopLeft(find.byKey(const ValueKey('filter'))).dy,
        );
      }
      expect(tester.takeException(), isNull);
    }
  });
}
