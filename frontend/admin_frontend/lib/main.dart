import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'features/auth/presentation/provider/auth_provider.dart';
import 'widgets/app_layout.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/products/presentation/screens/products_screen.dart';
import 'features/inventory/presentation/screens/inventory_screen.dart';
import 'features/promotions/presentation/screens/promotions_screen.dart';
import 'features/orders/presentation/screens/orders_screen.dart';
import 'features/customers/presentation/screens/customers_screen.dart';
import 'features/purchases/presentation/screens/purchases_screen.dart';
import 'features/suppliers/presentation/screens/suppliers_screen.dart';
import 'features/feedback/presentation/screens/feedback_screen.dart';
import 'features/staff/presentation/screens/staff_screen.dart';
import 'features/reports/presentation/screens/reports_screen.dart';
import 'features/users/presentation/screens/users_screen.dart';
import 'features/users/presentation/providers/users_provider.dart';
import 'features/products/presentation/providers/products_provider.dart';
import 'features/categories/presentation/providers/categories_provider.dart';
import 'features/suppliers/presentation/providers/suppliers_provider.dart';
import 'features/sizeguides/presentation/providers/size_guides_provider.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'features/products/presentation/screens/product_detail_screen.dart';
import 'features/products/presentation/screens/product_variants_screen.dart';
import 'features/categories/presentation/screens/categories_screen.dart';
import 'screens/unauthorized_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(const ZellaAdminApp());
}

class ZellaAdminApp extends StatelessWidget {
  const ZellaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(create: (_) => SuppliersProvider()),
        ChangeNotifierProvider(create: (_) => SizeGuidesProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'Zella Admin',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: authProvider.isLoading
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  )
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
  Map<String, dynamic>? _currentArgs;
  Widget? _currentDrawer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void navigate(String route, [Map<String, dynamic>? args]) {
    setState(() {
      _currentRoute = route;
      _currentArgs = args;
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
      case '/categories':
        return const CategoriesScreen();
      case '/products':
        return const ProductsScreen();
      case '/product-detail':
        return ProductDetailScreen(product: _currentArgs);
      case '/product-variants':
        return ProductVariantsScreen(product: _currentArgs);
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
      case '/unauthorized':
        return const UnauthorizedScreen();
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
