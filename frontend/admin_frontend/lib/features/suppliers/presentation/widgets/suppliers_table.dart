// GENERATED FROM TEMPLATE: templates/feature_table.dart.template
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import 'supplier_status_badge.dart';
import 'supplier_action_menu.dart';

class SuppliersTable extends StatelessWidget {
  const SuppliersTable({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data cho UI
    final List<Map<String, dynamic>> suppliers = [
      {
        'id': 'SUP-001',
        'name': 'Công ty Vải Hà Nội',
        'contactPerson': 'Nguyễn Văn Hùng',
        'email': 'import@vaihani.vn',
        'category': 'Vải cao cấp',
        'totalValue': '312.000.000 ₫',
        'status': 'Đang hợp tác',
      },
      {
        'id': 'SUP-002',
        'name': 'Milano Fabrics Import',
        'contactPerson': 'Marco Rossi',
        'email': 'sales@milanofabrics.it',
        'category': 'Vải Ý nhập khẩu',
        'totalValue': '187.500.000 ₫',
        'status': 'Đang hợp tác',
      },
      {
        'id': 'SUP-003',
        'name': 'Leather House HCM',
        'contactPerson': 'Trần Thị Mai',
        'email': 'orders@leatherhouse.vn',
        'category': 'Da thuộc',
        'totalValue': '241.000.000 ₫',
        'status': 'Đang hợp tác',
      },
      {
        'id': 'SUP-005',
        'name': 'Korea Fabric Ltd.',
        'contactPerson': 'Kim Ji-Hoon',
        'email': 'trade@koreafabric.kr',
        'category': 'Vải Hàn Quốc',
        'totalValue': '95.000.000 ₫',
        'status': 'Ngừng hợp tác',
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
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
                Expanded(flex: 3, child: Text('Nhà cung cấp', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Liên hệ', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Danh mục', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Trạng thái', style: _headerStyle())),
                Expanded(flex: 2, child: Text('Tổng giá trị', style: _headerStyle())),
                const SizedBox(width: 48), // Action space
              ],
            ),
          ),
          // Data Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: suppliers.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              return _buildDataRow(context, supplier);
            },
          ),
          // Pagination Footer
          const Divider(height: 1, color: AppTheme.borderLight),
          _buildPagination(),
        ],
      ),
    );
  }

  TextStyle _headerStyle() {
    return const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondary,
    );
  }

  Widget _buildDataRow(BuildContext context, Map<String, dynamic> supplier) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        hoverColor: AppTheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // Supplier Info
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primary.withAlpha(25),
                      radius: 16,
                      child: Text(
                        supplier['name'].toString().substring(0, 1),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            supplier['id'],
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Contact
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier['contactPerson'],
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      supplier['email'],
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Category
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Text(
                      supplier['category'],
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              ),
              // Status
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SupplierStatusBadge(status: supplier['status']),
                ),
              ),
              // Total Value
              Expanded(
                flex: 2,
                child: Text(
                  supplier['totalValue'],
                  style: const TextStyle(
                    color: AppTheme.text, 
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Actions
              const SizedBox(
                width: 48,
                child: SupplierActionMenu(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Hiển thị 1-10 trong số 48 nhà cung cấp',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Row(
            children: [
              _buildPageButton(Icons.chevron_left, onPressed: null), // Disabled
              const SizedBox(width: 8),
              _buildPageNumber('1', isActive: true),
              const SizedBox(width: 4),
              _buildPageNumber('2'),
              const SizedBox(width: 4),
              _buildPageNumber('3'),
              const SizedBox(width: 4),
              const Text('...', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(width: 4),
              _buildPageNumber('5'),
              const SizedBox(width: 8),
              _buildPageButton(Icons.chevron_right, onPressed: () {}),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPageNumber(String text, {bool isActive = false}) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.white : AppTheme.text,
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton(IconData icon, {VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(8),
          color: onPressed == null ? AppTheme.surface : Colors.white,
        ),
        child: Icon(
          icon,
          size: 18,
          color: onPressed == null ? AppTheme.border : AppTheme.text,
        ),
      ),
    );
  }
}

