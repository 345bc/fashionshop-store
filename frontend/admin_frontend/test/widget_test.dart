import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zella_admin_flutter/main.dart';
import 'package:zella_admin_flutter/screens/login_screen.dart';

void main() {
  testWidgets('Fresh installation opens login instead of the admin workspace', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(
      envString: 'API_BASE_URL=http://127.0.0.1:8080/api/v1',
    );
    await tester.pumpWidget(const ZellaAdminApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MainScreen), findsNothing);
    expect(find.text('Đăng nhập'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
