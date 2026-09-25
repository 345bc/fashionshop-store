import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../features/auth/presentation/provider/auth_provider.dart';
import '../screens/login_screen.dart';

class NavItem {
  final String title;
  final IconData icon;
  final String route;

  NavItem(this.title, this.icon, this.route);
}

class NavGroup {
  final String title;
  final List<NavItem> items;

  NavGroup(this.title, this.items);
}

final List<NavGroup> navGroups = [
  NavGroup('TỔNG QUAN', [
    NavItem('Dashboard', Icons.dashboard_outlined, '/'),
    NavItem('Báo cáo', Icons.bar_chart_outlined, '/reports'),
  ]),
  NavGroup('QUẢN LÝ BÁN HÀNG', [
    NavItem('Đơn hàng', Icons.shopping_cart_outlined, '/orders'),
    NavItem('Khuyến mãi', Icons.local_offer_outlined, '/promotions'),
  ]),
  NavGroup('SẢN PHẨM & KHO', [
    NavItem('Danh mục', Icons.category_outlined, '/categories'),
    NavItem('Sản phẩm', Icons.inventory_2_outlined, '/products'),
    NavItem('Tồn kho', Icons.storage_outlined, '/inventory'),
    NavItem('Nhập hàng', Icons.local_shipping_outlined, '/purchases'),
    NavItem('Nhà cung cấp', Icons.business_center_outlined, '/suppliers'),
  ]),
  NavGroup('KHÁCH HÀNG & HỖ TRỢ', [
    NavItem('Khách hàng', Icons.people_outline, '/customers'),
    NavItem('Phản hồi', Icons.chat_bubble_outline, '/feedback'),
  ]),
  NavGroup('HỆ THỐNG', [
    NavItem('Tài khoản', Icons.security_outlined, '/users'),
    NavItem('Nhân sự', Icons.badge_outlined, '/staff'),
    NavItem('Cài đặt', Icons.settings_outlined, '/settings'),
  ]),
];

class AppLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final void Function(String, [Map<String, dynamic>?]) onNavigate;

  const AppLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              border: Border(right: BorderSide(color: AppTheme.primary)),
            ),
            child: Column(
              children: [
                // Logo
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withAlpha(25)),
                    ),
                  ),
                  child: const Text(
                    'ZELLA.',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Navigation
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: navGroups.length,
                    itemBuilder: (context, groupIndex) {
                      final group = navGroups[groupIndex];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 28,
                              top: 24,
                              bottom: 12,
                            ),
                            child: Text(
                              group.title,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withAlpha(100),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          ...group.items.map((item) {
                            final isActive = currentRoute == item.route;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              child: InkWell(
                                onTap: () => onNavigate(item.route),
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedContainer(
                                  duration: AppAnimations.fast,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.white.withAlpha(20)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.icon,
                                        size: 20,
                                        color: isActive
                                            ? Colors.white
                                            : Colors.white.withAlpha(150),
                                      ),
                                      const SizedBox(width: 14),
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isActive
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isActive
                                              ? Colors.white
                                              : Colors.white.withAlpha(170),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    border: Border(bottom: BorderSide(color: AppTheme.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Search
                      Container(
                        width: 320,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.search,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Actions
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none,
                              size: 20,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 16),
                          PopupMenuButton<String>(
                            offset: const Offset(0, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onSelected: (value) async {
                              if (value == 'logout') {
                                await context.read<AuthProvider>().logout();
                                if (!context.mounted) return;
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'profile',
                                child: Row(
                                  children: [
                                    Icon(Icons.person_outline, size: 20),
                                    SizedBox(width: 12),
                                    Text('Hồ sơ'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem<String>(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.logout,
                                      size: 20,
                                      color: AppTheme.danger,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Đăng xuất',
                                      style: TextStyle(color: AppTheme.danger),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'A',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Page Content
                Expanded(
                  child: Container(
                    color: AppTheme
                        .background, // Sửa màu nền của Page Content thành trắng
                    width: double.infinity,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
