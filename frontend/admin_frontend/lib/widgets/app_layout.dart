import '../core/security/role_access.dart';
import '../features/auth/presentation/dialogs/session_profile_dialog.dart';

import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../features/auth/presentation/provider/auth_provider.dart';

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
    NavItem('Dashboard & Báo cáo', Symbols.dashboard, '/'),
  ]),
  NavGroup('QUẢN LÝ BÁN HÀNG', [
    NavItem('Đơn hàng', Symbols.shopping_cart, '/orders'),
    NavItem('Voucher & Khuyến mãi', Symbols.local_offer, '/promotions'),
  ]),
  NavGroup('SẢN PHẨM & KHO', [
    NavItem('Danh mục sản phẩm', Symbols.category, '/categories'),
    NavItem('Sản phẩm', Symbols.inventory_2, '/products'),
    NavItem('Tồn kho', Symbols.storage, '/inventory'),
    NavItem('Nhập hàng', Symbols.local_shipping, '/purchases'),
    NavItem('Nhà cung cấp', Symbols.business_center, '/suppliers'),
  ]),
  NavGroup('KHÁCH HÀNG & HỖ TRỢ', [
    NavItem('Khách hàng', Symbols.group, '/customers'),
    NavItem('Phản hồi', Symbols.chat_bubble, '/feedback'),
  ]),
  NavGroup('HỆ THỐNG', [
    NavItem('Tài khoản', Symbols.security, '/users'),
    NavItem('Nhân sự', Symbols.badge, '/staff'),
    NavItem('Cài đặt', Symbols.settings, '/settings'),
  ]),
];

class AppLayout extends StatefulWidget {
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
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  bool _sidebarOpen = true;

  List<NavGroup> get _visibleGroups {
    final role = context.watch<AuthProvider>().user?.activeRole;
    return navGroups
        .map(
          (group) => NavGroup(
            group.title,
            group.items
                .where((item) => RoleAccess.canOpen(role, item.route))
                .toList(),
          ),
        )
        .where((group) => group.items.isNotEmpty)
        .toList();
  }

  bool _isActive(NavItem item) =>
      widget.currentRoute == item.route ||
      (item.route == '/' && widget.currentRoute == '/reports') ||
      (item.route == '/promotions' &&
          (widget.currentRoute == '/vouchers' ||
              widget.currentRoute == '/promotion-programs'));

  Widget _compactSidebar() => OverflowBox(
    alignment: Alignment.centerLeft,
    minWidth: 64,
    maxWidth: 64,
    child: Column(
      children: [
        const SizedBox(
          height: 70,
          child: Center(
            child: Text(
              'Z',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            children: [
              for (final group in _visibleGroups) ...[
                for (final item in group.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: IconButton(
                      tooltip: item.title,
                      onPressed: () => widget.onNavigate(item.route),
                      style: IconButton.styleFrom(
                        backgroundColor: _isActive(item)
                            ? AppTheme.primary.withValues(alpha: 0.06)
                            : Colors.transparent,
                        foregroundColor: _isActive(item)
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(item.icon, size: 20),
                    ),
                  ),
                if (group != _visibleGroups.last) const Divider(height: 16),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: AppAnimations.normal,
            curve: Curves.easeInOutCubic,
            width: _sidebarOpen ? 260 : 64,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(color: AppTheme.surface),
            child: !_sidebarOpen
                ? _compactSidebar()
                : OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: 260,
                    maxWidth: 260,
                    child: ExcludeFocus(
                      excluding: !_sidebarOpen,
                      child: ExcludeSemantics(
                        excluding: !_sidebarOpen,
                        child: Column(
                          children: [
                            // Logo
                            Container(
                              height: 70,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              alignment: Alignment.centerLeft,
                              child: const Text(
                                'ZELLA.',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                            // Navigation
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                itemCount: _visibleGroups.length,
                                itemBuilder: (context, groupIndex) {
                                  final group = _visibleGroups[groupIndex];
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 28,
                                          top: 24,
                                          bottom: 12,
                                        ),
                                        child: Text(
                                          group.title,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textMuted,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                      ...group.items.map((item) {
                                        final isActive =
                                            widget.currentRoute == item.route ||
                                            (item.route == '/' &&
                                                widget.currentRoute ==
                                                    '/reports') ||
                                            (item.route == '/promotions' &&
                                                (widget.currentRoute ==
                                                        '/vouchers' ||
                                                    widget.currentRoute ==
                                                        '/promotion-programs'));
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 2,
                                          ),
                                          child: InkWell(
                                            onTap: () =>
                                                widget.onNavigate(item.route),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: AnimatedContainer(
                                              duration: AppAnimations.fast,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isActive
                                                    ? AppTheme.primary
                                                          .withValues(
                                                            alpha: 0.06,
                                                          )
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    item.icon,
                                                    size: 20,
                                                    color: isActive
                                                        ? AppTheme.primary
                                                        : AppTheme
                                                              .textSecondary,
                                                  ),
                                                  const SizedBox(width: 14),
                                                  Expanded(
                                                    child: Text(
                                                      item.title,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: isActive
                                                            ? FontWeight.w600
                                                            : FontWeight.w500,
                                                        color: isActive
                                                            ? AppTheme.primary
                                                            : AppTheme
                                                                  .textSecondary,
                                                      ),
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
                    ),
                  ),
          ),
          // Main Content Area
          Expanded(
            child: Container(
              margin: EdgeInsets.only(
                top: 8,
                right: 8,
                bottom: 8,
                left: _sidebarOpen ? 0 : 8,
              ),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: const BoxDecoration(color: AppTheme.background),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Search and Collapse
                        Row(
                          children: [
                            // Collapse Button
                            InkWell(
                              onTap: () =>
                                  setState(() => _sidebarOpen = !_sidebarOpen),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.borderLight,
                                  ),
                                ),
                                child: Tooltip(
                                  message: _sidebarOpen
                                      ? 'Thu gọn sidebar'
                                      : 'Mở sidebar',
                                  child: Icon(
                                    _sidebarOpen
                                        ? Symbols.left_panel_close
                                        : Symbols.left_panel_open,
                                    size: 20,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 1,
                              height: 20,
                              color: AppTheme.borderLight,
                            ),
                            const SizedBox(width: 16),
                            // Search Input
                            Container(
                              width: 320,
                              height: 36,
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Symbols.search,
                                    size: 18,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: 'Search',
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        hintStyle: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppTheme.borderLight,
                                      ),
                                    ),
                                    child: const Text(
                                      '⌘ K',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Actions
                        Row(
                          children: [
                            Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                final user = auth.user;
                                if (user == null) {
                                  return const SizedBox.shrink();
                                }
                                if (user.roles.length < 2) {
                                  return Text(
                                    RoleAccess.labels[user.activeRole] ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                }
                                return PopupMenuButton<String>(
                                  tooltip: 'Chuyển vai trò',
                                  onSelected: (role) async {
                                    try {
                                      await auth.selectRole(role);
                                      if (!context.mounted) return;
                                      Navigator.of(context)
                                          .popUntil((route) => route.isFirst);
                                      widget.onNavigate(RoleAccess.home(role));
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              SnackBar(content: Text('$error')),
                                            );
                                      }
                                    }
                                  },
                                  itemBuilder: (_) => user.roles
                                      .where((role) => role != 'USER')
                                      .map(
                                        (role) => PopupMenuItem(
                                          value: role,
                                          child: Text(
                                            RoleAccess.labels[role] ?? role,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      RoleAccess.labels[user.activeRole] ??
                                          'Vai trò',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(
                                Symbols.notifications,
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
                                if (value == 'profile') {
                                  await showDialog(
                                    context: context,
                                    builder: (_) =>
                                        const SessionProfileDialog(),
                                  );
                                  return;
                                }
                                if (value == 'logout') {
                                  await context.read<AuthProvider>().logout();
                                  if (!context.mounted) return;
                                  Navigator.of(context)
                                      .popUntil((route) => route.isFirst);
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem<String>(
                                  value: 'profile',
                                  child: Row(
                                    children: [
                                      Icon(Symbols.person, size: 20),
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
                                        Symbols.logout,
                                        size: 20,
                                        color: AppTheme.danger,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Đăng xuất',
                                        style: TextStyle(
                                          color: AppTheme.danger,
                                        ),
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
                                child: Center(
                                  child: Text(
                                    context
                                                .watch<AuthProvider>()
                                                .user
                                                ?.username
                                                .trim()
                                                .isNotEmpty ==
                                            true
                                        ? context
                                              .watch<AuthProvider>()
                                              .user!
                                              .username
                                              .trim()
                                              .substring(0, 1)
                                              .toUpperCase()
                                        : '?',
                                    style: const TextStyle(
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
                      color: AppTheme.background, // Sửa màu nền của Page Content thành trắng
                      width: double.infinity,
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
