class RoleAccess {
  static const labels = {
    'SUPERADMIN': 'Quản trị viên cấp cao',
    'ADMIN': 'Quản trị viên',
    'SALES': 'Bán hàng',
    'WAREHOUSE': 'Kho',
    'CUSTOMER_SUPPORT': 'Chăm sóc khách hàng',
    'MARKETING': 'Marketing',
    'USER': 'Khách hàng',
  };

  static bool isBackOfficeRole(String? role) =>
      role != 'USER' && labels.containsKey(role);

  static bool canOpen(String? role, String route) {
    return switch (role) {
      'SUPERADMIN' => true,
      'ADMIN' => [
        '/',
        '/customers',
        '/users',
        '/staff',
        '/reports',
      ].contains(route),
      'SALES' => ['/orders', '/customers', '/products'].contains(route),
      'WAREHOUSE' => [
        '/orders',
        '/inventory',
        '/purchases',
        '/suppliers',
        '/products',
        '/product-variants',
        '/products/variants/new',
        '/products/variants/edit',
      ].contains(route),
      'CUSTOMER_SUPPORT' => [
        '/orders',
        '/customers',
        '/feedback',
      ].contains(route),
      'MARKETING' => [
        '/bought-together',
        '/home-appearance',
        '/posts',
        '/post-categories',
        '/promotions',
        '/vouchers',
        '/promotion-programs',
        '/products',
      ].contains(route),
      _ => false,
    };
  }

  static String home(String? role) => switch (role) {
    'ADMIN' => '/reports',
    'SALES' || 'CUSTOMER_SUPPORT' => '/orders',
    'WAREHOUSE' => '/inventory',
    'MARKETING' => '/promotions',
    _ => '/',
  };
}
