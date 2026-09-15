import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  String _activeFilter = 'all';

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'label': 'Tất cả', 'count': 9},
    {'id': 'active', 'label': 'Đang làm', 'count': 7},
    {'id': 'leave', 'label': 'Nghỉ phép', 'count': 2},
  ];

  final Map<String, Map<String, dynamic>> _roleMap = {
    'manager': {'label': 'Quản lý', 'bgColor': const Color(0xFFF3E8FF), 'color': const Color(0xFF7E22CE)},
    'sales': {'label': 'Bán hàng', 'bgColor': const Color(0xFFE0E7FF), 'color': const Color(0xFF4338CA)},
    'warehouse': {'label': 'Kho', 'bgColor': const Color(0xFFE0E7FF), 'color': const Color(0xFF4338CA)},
    'designer': {'label': 'Thiết kế', 'bgColor': const Color(0xFFFFEDD5), 'color': const Color(0xFFC2410C)},
    'accountant': {'label': 'Kế toán', 'bgColor': const Color(0xFFF3E8FF), 'color': const Color(0xFF7E22CE)},
  };

  final List<Map<String, dynamic>> _staff = [
    {
      'id': 'NV-001',
      'name': 'Đinh Thùy Linh',
      'role': 'manager',
      'email': 'thuylinh@zella.vn',
      'phone': '0912 001 001',
      'shift': 'Hành chính',
      'startDate': '01 Mar 2024',
      'status': 'active',
    },
    {
      'id': 'NV-002',
      'name': 'Phùng Minh Tú',
      'role': 'sales',
      'email': 'minhtu@zella.vn',
      'phone': '0935 002 002',
      'shift': 'Ca sáng',
      'startDate': '15 Jun 2024',
      'status': 'active',
    },
    {
      'id': 'NV-003',
      'name': 'Bùi Khánh Linh',
      'role': 'warehouse',
      'email': 'khanhlinh@zella.vn',
      'phone': '0978 003 003',
      'shift': 'Ca chiều',
      'startDate': '01 Jan 2025',
      'status': 'leave',
    },
    {
      'id': 'NV-004',
      'name': 'Hoàng Anh Đức',
      'role': 'designer',
      'email': 'anhduc@zella.vn',
      'phone': '0901 004 004',
      'shift': 'Hành chính',
      'startDate': '01 Sep 2023',
      'status': 'active',
    },
    {
      'id': 'NV-005',
      'name': 'Trần Thị Ngọc',
      'role': 'accountant',
      'email': 'thingoc@zella.vn',
      'phone': '0987 005 005',
      'shift': 'Hành chính',
      'startDate': '15 Apr 2022',
      'status': 'active',
    },
    {
      'id': 'NV-006',
      'name': 'Lê Bảo Châu',
      'role': 'sales',
      'email': 'baochau@zella.vn',
      'phone': '0962 006 006',
      'shift': 'Ca sáng',
      'startDate': '20 Nov 2025',
      'status': 'leave',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final visibleStaff = _activeFilter == 'all'
        ? _staff
        : _staff.where((s) => s['status'] == _activeFilter).toList();

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
                  Text('Nhân viên', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('Quản lý hồ sơ và ca làm việc của nhân viên.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
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
                    label: const Text('Thêm nhân viên'),
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
                  DataColumn(label: Text('Mã NV')),
                  DataColumn(label: Text('Họ tên')),
                  DataColumn(label: Text('Vị trí')),
                  DataColumn(label: Text('Liên hệ')),
                  DataColumn(label: Text('Ca làm việc')),
                  DataColumn(label: Text('Ngày vào làm')),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('')),
                ],
                rows: visibleStaff.map((s) {
                  final role = _roleMap[s['role']]!;
                  final isActive = s['status'] == 'active';
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(s['id'], style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(s['name'], style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: role['bgColor'] as Color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            role['label'] as String,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: role['color'] as Color),
                          ),
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(s['email'], style: const TextStyle(fontSize: 13)),
                            Text(s['phone'], style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      DataCell(Text(s['shift'], style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(Text(s['startDate'], style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isActive ? AppTheme.success : AppTheme.warning).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isActive ? 'Đang làm' : 'Nghỉ phép',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? AppTheme.success : AppTheme.warning),
                          ),
                        ),
                      ),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.how_to_reg_outlined, size: 20),
                            color: AppTheme.textSecondary,
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
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
