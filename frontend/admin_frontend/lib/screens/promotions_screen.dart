import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  String _activeFilter = 'all';

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'label': 'Tất cả', 'count': 12},
    {'id': 'active', 'label': 'Đang chạy', 'count': 5},
    {'id': 'scheduled', 'label': 'Sắp diễn ra', 'count': 3},
    {'id': 'expired', 'label': 'Đã hết hạn', 'count': 4},
  ];

  final List<Map<String, dynamic>> _promos = [
    {
      'code': 'FW26LAUNCH',
      'name': 'Ra mắt BST Thu Đông 2026',
      'type': 'percent',
      'value': '15%',
      'minOrder': '2.000.000 ₫',
      'used': 48,
      'maxUses': 100,
      'validFrom': '01 Sep 2026',
      'validTo': '30 Sep 2026',
      'status': 'active',
    },
    {
      'code': 'VIP500K',
      'name': 'Ưu đãi VIP — Giảm 500K',
      'type': 'fixed',
      'value': '500.000 ₫',
      'minOrder': '5.000.000 ₫',
      'used': 12,
      'maxUses': 50,
      'validFrom': '01 Sep 2026',
      'validTo': '31 Dec 2026',
      'status': 'active',
    },
    {
      'code': 'SUMMER20',
      'name': 'Sale Hè 2026',
      'type': 'percent',
      'value': '20%',
      'minOrder': '1.500.000 ₫',
      'used': 200,
      'maxUses': 200,
      'validFrom': '01 Jun 2026',
      'validTo': '31 Aug 2026',
      'status': 'expired',
    },
    {
      'code': 'NEWYR2027',
      'name': 'Tết Nguyên Đán 2027',
      'type': 'percent',
      'value': '10%',
      'minOrder': '3.000.000 ₫',
      'used': 0,
      'maxUses': 500,
      'validFrom': '20 Jan 2027',
      'validTo': '05 Feb 2027',
      'status': 'scheduled',
    },
    {
      'code': 'FRIEND200',
      'name': 'Giới thiệu bạn bè',
      'type': 'fixed',
      'value': '200.000 ₫',
      'minOrder': '1.000.000 ₫',
      'used': 33,
      'maxUses': null,
      'validFrom': '01 Jan 2026',
      'validTo': '31 Dec 2026',
      'status': 'active',
    },
  ];

  final Map<String, Map<String, dynamic>> _statusMap = {
    'active': {'label': 'Đang chạy', 'color': AppTheme.success},
    'scheduled': {'label': 'Sắp diễn ra', 'color': const Color(0xFF4338CA), 'bgColor': const Color(0xFFE0E7FF)},
    'expired': {'label': 'Đã hết hạn', 'color': AppTheme.textSecondary, 'bgColor': AppTheme.border},
  };

  @override
  Widget build(BuildContext context) {
    final visiblePromos = _activeFilter == 'all'
        ? _promos
        : _promos.where((p) => p['status'] == _activeFilter).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Khuyến mãi & Giảm giá', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('Quản lý mã giảm giá và các chiến dịch khuyến mãi.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Xuất'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tạo khuyến mãi'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Filters
          Row(
            children: _filters.map((f) {
              final isActive = _activeFilter == f['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _activeFilter = f['id']),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primary : AppTheme.surface,
                      border: Border.all(color: isActive ? AppTheme.primary : AppTheme.border),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          f['label'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                            color: isActive ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${f['count']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive ? Colors.white70 : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Table
          Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13),
                dataTextStyle: const TextStyle(color: AppTheme.text, fontSize: 14),
                dividerThickness: 1,
                columns: const [
                  DataColumn(label: Text('Mã Code')),
                  DataColumn(label: Text('Tên chương trình')),
                  DataColumn(label: Text('Loại')),
                  DataColumn(label: Text('Mức giảm'), numeric: true),
                  DataColumn(label: Text('ĐH tối thiểu'), numeric: true),
                  DataColumn(label: Text('Đã dùng / Giới hạn'), numeric: true),
                  DataColumn(label: Text('Hiệu lực')),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('')),
                ],
                rows: visiblePromos.map((p) {
                  final statusInfo = _statusMap[p['status']]!;
                  final double usageRatio = p['maxUses'] != null ? (p['used'] / p['maxUses']) : 0.0;
                  final isPercent = p['type'] == 'percent';
                  
                  Color statusBgColor;
                  if (statusInfo.containsKey('bgColor')) {
                    statusBgColor = statusInfo['bgColor'] as Color;
                  } else {
                    statusBgColor = (statusInfo['color'] as Color).withOpacity(0.1);
                  }

                  return DataRow(
                    cells: [
                      DataCell(Text(p['code'], style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                      DataCell(Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPercent ? const Color(0xFFF3E8FF) : const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isPercent ? const Color(0xFFD8B4FE) : const Color(0xFF93C5FD)),
                          ),
                          child: Text(
                            isPercent ? '% Phần trăm' : '₫ Cố định',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPercent ? const Color(0xFF7E22CE) : const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(p['value'], style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(p['minOrder'], style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${p['used']} / ${p['maxUses'] ?? '∞'}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            if (p['maxUses'] != null)
                              Container(
                                width: 72,
                                height: 4,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.border,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 72 * usageRatio,
                                      decoration: BoxDecoration(
                                        color: usageRatio >= 0.9 ? AppTheme.danger : AppTheme.primary,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['validFrom'], style: const TextStyle(fontSize: 13)),
                            Text('→ ${p['validTo']}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusInfo['label'] as String,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusInfo['color'] as Color),
                          ),
                        ),
                      ),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            color: AppTheme.textSecondary,
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: AppTheme.textSecondary,
                            onPressed: () {},
                          ),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
