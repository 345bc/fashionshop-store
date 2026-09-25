import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class CustomersTable extends StatelessWidget {
  final String activeTab;
  
  const CustomersTable({
    super.key,
    required this.activeTab,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> allCustomers = [
      {
        'id': 'CLT-001',
        'name': 'Nguyễn Lan Phương',
        'email': 'lanphuong@email.com',
        'phone': '0912 345 678',
        'tier': 'vip',
        'totalOrders': 14,
        'totalSpend': '42.500.000 ₫',
        'lastOrder': '14 Sep 2026',
      },
      {
        'id': 'CLT-002',
        'name': 'Trần Hải Đăng',
        'email': 'haidang@email.com',
        'phone': '0908 765 432',
        'tier': 'regular',
        'totalOrders': 5,
        'totalSpend': '12.800.000 ₫',
        'lastOrder': '13 Sep 2026',
      },
      {
        'id': 'CLT-003',
        'name': 'Hoàng Mai Ly',
        'email': 'maily@email.com',
        'phone': '0934 111 222',
        'tier': 'new',
        'totalOrders': 1,
        'totalSpend': '1.200.000 ₫',
        'lastOrder': '12 Sep 2026',
      },
    ];

    final visibleCustomers = activeTab == 'all' 
        ? allCustomers 
        : allCustomers.where((c) => c['tier'] == activeTab).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('Khách hàng', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Liên hệ', style: _headerStyle())),
              Expanded(flex: 1, child: Text('Hạng', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Đơn hàng', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Tổng chi tiêu', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Đơn gần nhất', style: _headerStyle())),
              const SizedBox(width: 48), // Action space
            ],
          ),
        ),
        // Data Rows
        if (visibleCustomers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(48.0),
            child: Center(child: Text('Không có dữ liệu', style: TextStyle(color: AppTheme.textSecondary))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleCustomers.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              final customer = visibleCustomers[index];
              return _buildDataRow(context, customer);
            },
          ),
        // Pagination Footer
        const Divider(height: 1, color: AppTheme.borderLight),
        _buildPagination(),
      ],
    );
  }

  TextStyle _headerStyle() {
    return const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondary,
    );
  }

  Map<String, dynamic> _getTierBadge(String tier) {
    switch (tier) {
      case 'vip':
        return {'label': 'VIP', 'color': const Color(0xFF9333EA)}; // Purple
      case 'new':
        return {'label': 'Mới', 'color': const Color(0xFF2563EB)}; // Blue
      default:
        return {'label': 'Thường', 'color': AppTheme.textSecondary};
    }
  }

  Widget _buildDataRow(BuildContext context, Map<String, dynamic> customer) {
    final badge = _getTierBadge(customer['tier']);

    return InkWell(
      onTap: () {},
      hoverColor: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primary.withAlpha(25),
                    child: Text(
                      customer['name'].substring(0, 1),
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer['name'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          customer['id'],
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer['phone'], style: const TextStyle(fontSize: 13)),
                  Text(customer['email'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badge['color'] as Color).withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge['label'] as String,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: badge['color'] as Color),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${customer['totalOrders']} đơn',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                customer['totalSpend'],
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                customer['lastOrder'],
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            SizedBox(
              width: 48,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Xem hồ sơ'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Hiển thị 1-10 trong số 45 khách hàng',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Row(
            children: [
              _buildPageBtn(Icons.chevron_left, null),
              const SizedBox(width: 8),
              _buildPageBtn('1', true),
              const SizedBox(width: 8),
              _buildPageBtn('2', false),
              const SizedBox(width: 8),
              _buildPageBtn('3', false),
              const SizedBox(width: 8),
              _buildPageBtn(Icons.chevron_right, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageBtn(dynamic content, dynamic actionOrIsActive) {
    final bool isActive = actionOrIsActive == true;
    final bool isDisabled = actionOrIsActive == null;

    return InkWell(
      onTap: isDisabled || isActive ? null : (actionOrIsActive is Function ? actionOrIsActive as void Function() : () {}),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? AppTheme.primary : (isDisabled ? Colors.transparent : AppTheme.borderLight)),
        ),
        alignment: Alignment.center,
        child: content is IconData
            ? Icon(content, size: 18, color: isDisabled ? AppTheme.textMuted : AppTheme.textSecondary)
            : Text(
                content.toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
      ),
    );
  }
}
