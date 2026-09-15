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
  NavGroup('BÁN HÀNG', [
    NavItem('Đơn hàng', Icons.shopping_cart_outlined, '/orders'),
    NavItem('Khách hàng', Icons.people_outline, '/customers'),
    NavItem('Khuyến mãi', Icons.local_offer_outlined, '/promotions'),
    NavItem('Phản hồi', Icons.chat_bubble_outline, '/feedback'),
  ]),
  NavGroup('SẢN PHẨM & KHO', [
    NavItem('Sản phẩm', Icons.inventory_2_outlined, '/products'),
    NavItem('Tồn kho', Icons.storage_outlined, '/inventory'),
    NavItem('Nhập hàng', Icons.local_shipping_outlined, '/purchases'),
    NavItem('Nhà cung cấp', Icons.business_center_outlined, '/suppliers'),
  ]),
  NavGroup('HỆ THỐNG', [
    NavItem('Nhân sự', Icons.badge_outlined, '/staff'),
    NavItem('Tài khoản', Icons.security_outlined, '/users'),
    NavItem('Cài đặt', Icons.settings_outlined, '/settings'),
  ]),
];

class AppLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final Function(String) onNavigate;

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
              color: AppTheme.background,
              border: Border(right: BorderSide(color: AppTheme.border)),
            ),
            child: Column(
              children: [
                // Logo
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                  ),
                  child: const Text(
                    'ZELLA.',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
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
                            padding: const EdgeInsets.only(left: 24, top: 16, bottom: 8),
                            child: Text(
                              group.title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMuted,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          ...group.items.map((item) {
                            final isActive = currentRoute == item.route;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              child: InkWell(
                                onTap: () => onNavigate(item.route),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isActive ? AppTheme.surface : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.icon,
                                        size: 20,
                                        color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                          color: isActive ? AppTheme.primary : AppTheme.textSecondary,
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
                            Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
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
                            icon: const Icon(Icons.notifications_none, size: 20, color: AppTheme.textSecondary),
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
                                    Icon(Icons.logout, size: 20, color: AppTheme.danger),
                                    SizedBox(width: 12),
                                    Text('Đăng xuất', style: TextStyle(color: AppTheme.danger)),
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
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                    color: AppTheme.surface,
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
