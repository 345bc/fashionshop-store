import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'features/auth/presentation/provider/auth_provider.dart';
import 'widgets/app_layout.dart';
import 'screens/dashboard_screen.dart';
import 'screens/products_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/promotions_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/purchases_screen.dart';
import 'features/suppliers/presentation/screens/suppliers_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/staff_screen.dart';
import 'screens/reports_screen.dart';
import 'features/users/presentation/screens/users_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Đọc cấu hình từ file .env
  await dotenv.load(fileName: ".env");
  
  runApp(const ZellaAdminApp());
}

class ZellaAdminApp extends StatelessWidget {
  const ZellaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Khởi tạo AuthProvider và kiểm tra trạng thái đăng nhập ngay khi mở app
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthStatus(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'Zella Admin',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            // Nếu đang kiểm tra token, hiện loading. Nếu đã đăng nhập, vào MainScreen. Chưa thì vào Login.
            home: authProvider.isLoading
                ? const Scaffold(body: Center(child: CircularProgressIndicator()))
                : authProvider.isAuthenticated
                    ? const MainScreen()
                    : const LoginScreen(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();

  static MainScreenState of(BuildContext context) {
    return context.findAncestorStateOfType<MainScreenState>()!;
  }
}

class MainScreenState extends State<MainScreen> {
  String _currentRoute = '/';
  Widget? _currentDrawer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void navigate(String route) {
    setState(() {
      _currentRoute = route;
    });
  }

  void openDrawer(Widget drawerContent) {
    setState(() {
      _currentDrawer = drawerContent;
    });
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void closeDrawer() {
    _scaffoldKey.currentState?.closeEndDrawer();
  }

  Widget _buildScreen() {
    switch (_currentRoute) {
      case '/':
        return const DashboardScreen();
      case '/products':
        return const ProductsScreen();
      case '/inventory':
        return const InventoryScreen();
      case '/promotions':
        return const PromotionsScreen();
      case '/orders':
        return const OrdersScreen();
      case '/customers':
        return const CustomersScreen();
      case '/purchases':
        return const PurchasesScreen();
      case '/suppliers':
        return const SuppliersScreen();
      case '/feedback':
        return const FeedbackScreen();
      case '/staff':
        return const StaffScreen();
      case '/reports':
        return const ReportsScreen();
      case '/users':
        return const UsersScreen();
      case '/settings':
        return const SettingsScreen();
      default:
        return Center(
          child: Text(
            'Lệnh $_currentRoute chưa được triển khai',
            style: const TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _currentDrawer,
      body: AppLayout(
        currentRoute: _currentRoute,
        onNavigate: navigate,
        child: _buildScreen(),
      ),
    );
  }
}
