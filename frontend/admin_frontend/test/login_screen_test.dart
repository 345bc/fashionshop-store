import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zella_admin_flutter/features/auth/presentation/provider/auth_provider.dart';
import 'package:zella_admin_flutter/main.dart';
import 'package:zella_admin_flutter/screens/login_screen.dart';

class TestAuthProvider extends AuthProvider {
  TestAuthProvider(this.loginSucceeds);

  final bool loginSucceeds;

  @override
  String? get errorMessage => loginSucceeds ? null : 'Sai thông tin đăng nhập';

  @override
  Future<bool> login(String email, String password) async => loginSucceeds;
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:8080/api/v1');
  });

  for (final succeeds in [false, true]) {
    testWidgets('Login shows ${succeeds ? 'success' : 'error'} message', (
      tester,
    ) async {
      final provider = TestAuthProvider(succeeds);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: provider,
          child: MaterialApp(
            scaffoldMessengerKey: adminScaffoldMessengerKey,
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'admin@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.text('Đăng nhập'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text(
          succeeds ? 'Đăng nhập thành công' : 'Sai thông tin đăng nhập',
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    });
  }
}
