import 'features/suppliers/data/models/supplier_response_model.dart';
import 'features/suppliers/presentation/screens/supplier_form_screen.dart';
import 'features/promotions/presentation/screens/campaign_form_screen.dart';
import 'features/products/presentation/screens/product_form_screen.dart';
import 'features/products/presentation/screens/variant_form_screen.dart';
import 'features/bought_together/bought_together_screen.dart';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/posts/post_category_form_screen.dart';
import 'features/posts/post_form_screen.dart';
import 'features/posts/posts_screen.dart';
import 'features/posts/post_categories_screen.dart';
import 'core/security/role_access.dart';
import 'screens/role_selection_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'features/auth/presentation/provider/auth_provider.dart';
import 'core/network/api_client.dart';
import 'widgets/app_layout.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/dashboard/presentation/providers/dashboard_provider.dart';
import 'features/products/presentation/screens/products_screen.dart';
import 'features/inventory/data/models/inventory_response_model.dart';
import 'features/inventory/presentation/screens/inventory_detail_screen.dart';
import 'features/inventory/presentation/screens/inventory_screen.dart';
import 'features/promotions/presentation/screens/promotions_screen.dart';
import 'features/promotions/presentation/screens/campaign_management_screen.dart';
import 'features/promotions/presentation/providers/campaigns_provider.dart';
import 'features/promotions/data/models/campaign_model.dart';
import 'features/orders/presentation/screens/orders_screen.dart';
import 'features/orders/presentation/screens/order_detail_screen.dart';
import 'features/orders/presentation/providers/orders_provider.dart';
import 'features/customers/presentation/screens/customers_screen.dart';
import 'features/customers/presentation/providers/customers_provider.dart';
import 'features/purchases/presentation/screens/goods_receipt_detail_screen.dart';
import 'features/purchases/presentation/screens/goods_receipt_form_screen.dart';
import 'features/purchases/data/models/goods_receipt_response_model.dart';
import 'features/purchases/presentation/screens/purchases_screen.dart';
import 'features/purchases/presentation/providers/purchases_provider.dart';
import 'features/inventory/presentation/providers/inventory_provider.dart';
import 'features/suppliers/presentation/screens/suppliers_screen.dart';
import 'features/feedback/presentation/screens/feedback_screen.dart';
import 'features/feedback/presentation/providers/feedback_provider.dart';
import 'features/staff/presentation/screens/staff_screen.dart';
import 'features/reports/presentation/screens/reports_screen.dart';
import 'features/users/presentation/screens/users_screen.dart';
import 'features/users/presentation/providers/users_provider.dart';
import 'features/products/presentation/providers/products_provider.dart';
import 'features/products/presentation/providers/product_variants_provider.dart';
import 'features/categories/presentation/providers/categories_provider.dart';
import 'features/suppliers/presentation/providers/suppliers_provider.dart';
import 'features/sizeguides/presentation/providers/size_guides_provider.dart';
import 'screens/login_screen.dart';
import 'features/products/presentation/screens/product_variants_screen.dart';
import 'features/categories/presentation/screens/categories_screen.dart';
import 'features/product_attributes/data/attribute_kind.dart';
import 'features/product_attributes/presentation/screens/attribute_management_screen.dart';
import 'screens/unauthorized_screen.dart';
import 'widgets/common/zella_toast.dart';

final adminNavigatorKey = GlobalKey<NavigatorState>();

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
        ChangeNotifierProvider(create: (_) => ProductVariantsProvider()),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(create: (_) => SuppliersProvider()),
        ChangeNotifierProvider(create: (_) => CustomersProvider()),
        ChangeNotifierProvider(create: (_) => PurchasesProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => FeedbackProvider()),
        ChangeNotifierProvider(create: (_) => CampaignsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => SizeGuidesProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          authProvider.onSessionExpired = () {
            adminNavigatorKey.currentState?.popUntil((route) => route.isFirst);
            final toastContext = adminNavigatorKey.currentContext;
            if (toastContext == null) return;
            ZellaToast.show(
              toastContext,
              message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
              type: ToastType.warning,
            );
          };
          ApiClient().onSessionExpired = authProvider.expireSession;
          return MaterialApp(
            title: 'Zella Admin',
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [Locale('vi'), Locale('en')],
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            builder: FToastBuilder(),
            navigatorKey: adminNavigatorKey,
            home: const AdminAuthGate(),
          );
        },
      ),
    );
  }
}

class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.isAuthenticated) return const LoginScreen();
    if (auth.needsRoleSelection) return const RoleSelectionScreen();
    return const MainScreen();
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
  bool _showUnauthorized = false;

  void navigate(String route, [Map<String, dynamic>? args]) {
    final role = context.read<AuthProvider>().user?.activeRole;
    if (route == '/unauthorized' || !RoleAccess.canOpen(role, route)) {
      setState(() => _showUnauthorized = true);
      return;
    }
    setState(() {
      _currentRoute = route;
      _currentArgs = args;
      _showUnauthorized = false;
    });
  }

  Widget _buildScreen() {
    final role = context.watch<AuthProvider>().user?.activeRole;
    if (!RoleAccess.canOpen(role, _currentRoute)) {
      _currentRoute = RoleAccess.home(role);
      _currentArgs = null;
    }
    switch (_showUnauthorized ? '/unauthorized' : _currentRoute) {
      case '/':
        return DashboardScreen(onNavigate: (route) => navigate(route));
      case '/categories':
        return const CategoriesScreen();
      case '/colors':
        return const AttributeManagementScreen(kind: AttributeKind.color);
      case '/sizes':
        return const AttributeManagementScreen(kind: AttributeKind.size);
      case '/sizeguides':
        return const AttributeManagementScreen(kind: AttributeKind.sizeGuide);
      case '/products/new':
        return ProductFormScreen(onClose: () => navigate('/products'));
      case '/products/edit':
        return ProductFormScreen(
          product: _currentArgs,
          onClose: () => navigate('/products'),
        );
      case '/products':
        return const ProductsScreen();
      case '/products/variants/new':
      case '/products/variants/edit':
        final product = _currentArgs?['product'] as Map<String, dynamic>?;
        final variant = _currentArgs?['variant'] as Map<String, dynamic>?;
        if (product == null ||
            (_currentRoute == '/products/variants/edit' && variant == null)) {
          return ProductVariantsScreen(product: product);
        }
        return VariantFormScreen(
          key: ValueKey((product['id'], variant?['id'])),
          productId: (product['id'] as num).toInt(),
          variant: variant,
          onClose: () => navigate('/product-variants', product),
        );
      case '/product-variants':
        return ProductVariantsScreen(product: _currentArgs);
      case '/inventory/detail':
        final item = _currentArgs?['item'] as InventoryResponseModel?;
        if (item == null) return const InventoryScreen();
        return InventoryDetailScreen(
          key: ValueKey(item.variantId),
          item: item,
          onClose: () => navigate('/inventory'),
        );
      case '/inventory':
        return const InventoryScreen();
      case '/bought-together':
        return const BoughtTogetherScreen();
      case '/posts/form':
        final post = _currentArgs?['post'] as Map<String, dynamic>?;
        final categories = _currentArgs?['categories'] as List<dynamic>? ?? [];
        return PostFormScreen(
          key: ValueKey(post?['id']),
          post: post,
          categories: categories,
          onClose: () => navigate('/posts'),
        );
      case '/post-categories/form':
        final category = _currentArgs?['category'] as Map<String, dynamic>?;
        return PostCategoryFormScreen(
          key: ValueKey(category?['id']),
          category: category,
          onClose: () => navigate('/post-categories'),
        );
      case '/posts':
        return const PostsScreen();
      case '/post-categories':
        return const PostCategoriesScreen();
      case '/promotions':
        return const PromotionsScreen();
      case '/vouchers/form':
      case '/promotion-programs/form':
        final isVoucher = _currentRoute == '/vouchers/form';
        final kind = isVoucher ? CampaignKind.voucher : CampaignKind.promotion;
        final item = _currentArgs?['item'] as CampaignModel?;
        return CampaignFormScreen(
          key: ValueKey((kind, item?.id)),
          kind: kind,
          item: item,
          onClose: () => navigate(isVoucher ? '/vouchers' : '/promotion-programs'),
        );
      case '/vouchers':
        return const CampaignManagementScreen(kind: CampaignKind.voucher);
      case '/promotion-programs':
        return const CampaignManagementScreen(kind: CampaignKind.promotion);
      case '/orders':
        return OrdersScreen(
          onOpenOrder: (id) => navigate('/orders/detail', {'id': id}),
        );
      case '/orders/detail':
        final orderId = _currentArgs?['id'];
        if (orderId is! int) {
          return OrdersScreen(
            onOpenOrder: (id) => navigate('/orders/detail', {'id': id}),
          );
        }
        return OrderDetailScreen(
          key: ValueKey(orderId),
          orderId: orderId,
          onBack: () => navigate('/orders'),
        );
      case '/customers':
        return const CustomersScreen();
      case '/purchases/form':
        final draft = _currentArgs?['receipt'] as GoodsReceiptResponseModel?;
        return GoodsReceiptFormScreen(
          key: ValueKey(draft?.id),
          receipt: draft,
          onClose: () => draft == null
              ? navigate('/purchases')
              : navigate('/purchases/detail', {'receiptId': draft.id}),
        );
      case '/purchases/detail':
        final receiptId = _currentArgs?['receiptId'] as int?;
        if (receiptId == null) return const PurchasesScreen();
        return GoodsReceiptDetailScreen(
          key: ValueKey(receiptId),
          receiptId: receiptId,
          onClose: () => navigate('/purchases'),
          onEdit: (receipt) => navigate('/purchases/form', {'receipt': receipt}),
        );
      case '/purchases':
        return const PurchasesScreen();
      case '/suppliers/form':
        final supplier = _currentArgs?['supplier'] as SupplierResponseModel?;
        return SupplierFormScreen(
          key: ValueKey(supplier?.id),
          supplier: supplier,
          onClose: () => navigate('/suppliers'),
        );
      case '/suppliers':
        return const SuppliersScreen();
      case '/feedback':
        return const FeedbackScreen();
      case '/staff':
        return const StaffScreen();
      case '/reports':
        return const ReportsScreen();
      case '/users':
        return UsersScreen(key: ValueKey(role));
      case '/unauthorized':
        return UnauthorizedScreen(
          onBack: () => setState(() => _showUnauthorized = false),
          onHome: () => navigate(RoleAccess.home(role)),
        );
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
    final screen = _buildScreen();
    return Scaffold(
      body: AppLayout(
        currentRoute: _showUnauthorized ? '/unauthorized' : _currentRoute,
        onNavigate: navigate,
        child: screen,
      ),
    );
  }
}
