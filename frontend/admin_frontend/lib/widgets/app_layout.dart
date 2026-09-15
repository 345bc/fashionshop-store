import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NavItem {
  final String title;
  final IconData icon;
  final String route;

  NavItem(this.title, this.icon, this.route);
}

final List<NavItem> navItems = [
  NavItem('Dashboard', Icons.dashboard_outlined, '/'),
  NavItem('Products', Icons.inventory_2_outlined, '/products'),
  NavItem('Inventory', Icons.storage_outlined, '/inventory'),
  NavItem('Orders', Icons.shopping_cart_outlined, '/orders'),
  NavItem('Customers', Icons.people_outline, '/customers'),
  NavItem('Purchases', Icons.local_shipping_outlined, '/purchases'),
  NavItem('Suppliers', Icons.business_center_outlined, '/suppliers'),
  NavItem('Promotions', Icons.local_offer_outlined, '/promotions'),
  NavItem('Feedback', Icons.chat_bubble_outline, '/feedback'),
  NavItem('Staff', Icons.badge_outlined, '/staff'),
  NavItem('Reports', Icons.bar_chart_outlined, '/reports'),
  NavItem('Users', Icons.security_outlined, '/users'),
  NavItem('Settings', Icons.settings_outlined, '/settings'),
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
                    itemCount: navItems.length,
                    itemBuilder: (context, index) {
                      final item = navItems[index];
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
                          Container(
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
