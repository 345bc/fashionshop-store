import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zella_admin_flutter/main.dart';
import 'package:zella_admin_flutter/features/auth/data/models/user_model.dart';
import 'package:zella_admin_flutter/features/auth/presentation/provider/auth_provider.dart';
import 'package:zella_admin_flutter/features/auth/presentation/dialogs/session_profile_dialog.dart';
import 'package:zella_admin_flutter/features/orders/presentation/providers/orders_provider.dart';
import 'package:zella_admin_flutter/screens/login_screen.dart';

import 'support/fake_auth.dart';

import 'package:zella_admin_flutter/screens/role_selection_screen.dart';

class SessionAuth extends FakeAuth {
  SessionAuth() : super(role: 'SALES');
  bool signedIn = false;
  bool failProfile = false;
  int profileRequests = 0;
  @override
  bool get isInitializing => false;
  @override
  bool get isAuthenticated => signedIn;
  @override
  Future<bool> login(String email, String password) async {
    signedIn = true;
    notifyListeners();
    return true;
  }

  @override
  Future<void> logout() async {
    signedIn = false;
    notifyListeners();
  }

  @override
  Future<UserModel> loadSessionProfile() async {
    profileRequests++;
    if (failProfile) throw Exception('Connection failed');
    return user;
  }
}

class PendingRoleAuth extends SessionAuth {
  String? active;
  final selected = Completer<void>();
  bool failSelection = false;
  @override
  UserModel get user => UserModel(
    id: 1,
    email: 'multi@example.test',
    username: 'multi',
    roles: ['SALES', 'WAREHOUSE'],
    activeRole: active,
  );
  @override
  bool get needsRoleSelection => active == null;
  @override
  Future<void> selectRole(String role) async {
    if (failSelection) throw Exception('Không thể chọn vai trò');
    await selected.future;
    active = role;
    notifyListeners();
  }
}

class SessionOrders extends OrdersProvider {
  @override
  Future<void> loadItems() async {}
}

void main() {
  setUpAll(
    () => dotenv.loadFromString(
      envString: 'API_BASE_URL=http://localhost:8080/api/v1',
    ),
  );

  testWidgets('Login logout and login again all change the root screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = SessionAuth();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<OrdersProvider>(
            create: (_) => SessionOrders(),
          ),
        ],
        child: const MaterialApp(home: AdminAuthGate()),
      ),
    );
    for (int attempt = 0; attempt < 2; attempt++) {
      expect(find.byType(LoginScreen), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.test',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password');
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();
      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      await tester.tap(find.byType(PopupMenuButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(find.byType(MainScreen), findsNothing);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    auth.dispose();
  });

  testWidgets(
    'Pending account stays in selection until API confirms its role',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = PendingRoleAuth()..signedIn = true;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<OrdersProvider>(
              create: (_) => SessionOrders(),
            ),
          ],
          child: const MaterialApp(home: AdminAuthGate()),
        ),
      );
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(find.byType(MainScreen), findsNothing);
      await tester.tap(find.text('Bán hàng'));
      await tester.pump();
      expect(find.byType(MainScreen), findsNothing);
      auth.selected.complete();
      await tester.pumpAndSettle();
      expect(find.byType(RoleSelectionScreen), findsNothing);
      expect(find.byType(MainScreen), findsOneWidget);
      expect(auth.user.activeRole, 'SALES');
      await tester.pumpWidget(const SizedBox.shrink());
      auth.dispose();
    },
  );

  testWidgets(
    'Failed role selection keeps account out of operational screens',
    (tester) async {
      final auth = PendingRoleAuth()
        ..signedIn = true
        ..failSelection = true;
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const MaterialApp(home: AdminAuthGate()),
        ),
      );
      await tester.tap(find.text('Kho'));
      await tester.pumpAndSettle();
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(find.byType(MainScreen), findsNothing);
      expect(find.textContaining('Không thể chọn vai trò'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      auth.dispose();
    },
  );

  testWidgets(
    'Session profile retries API errors and displays the current user',
    (tester) async {
      final auth = SessionAuth()..failProfile = true;
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const MaterialApp(
            home: Scaffold(body: SessionProfileDialog()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Không tải được hồ sơ phiên làm việc.'), findsOneWidget);
      expect(auth.profileRequests, 1);
      auth.failProfile = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(auth.profileRequests, 2);
      expect(find.text('test@example.test'), findsOneWidget);
      expect(find.text('Bán hàng'), findsOneWidget);
      expect(find.text('Quản trị viên, Bán hàng, Kho'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      auth.dispose();
    },
  );
}
