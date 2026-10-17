class RoleAccess {
  static const labels = {
    'ADMIN': 'Quản trị viên',
    'SALES': 'Bán hàng',
    'WAREHOUSE': 'Kho',
    'CUSTOMER_SUPPORT': 'Chăm sóc khách hàng',
    'MARKETING': 'Marketing',
    'USER': 'Khách hàng',
  };

  static bool canOpen(String? role, String route) {
    if (role == 'ADMIN') return true;
    return switch (role) {
      'SALES' => ['/orders', '/customers', '/products'].contains(route),
      'WAREHOUSE' => [
        '/orders',
        '/inventory',
        '/purchases',
        '/suppliers',
        '/products',
        '/product-variants',
      ].contains(route),
      'CUSTOMER_SUPPORT' => [
        '/orders',
        '/customers',
        '/feedback',
      ].contains(route),
      'MARKETING' => [
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
    'SALES' || 'CUSTOMER_SUPPORT' => '/orders',
    'WAREHOUSE' => '/inventory',
    'MARKETING' => '/promotions',
    _ => '/',
  };
}
