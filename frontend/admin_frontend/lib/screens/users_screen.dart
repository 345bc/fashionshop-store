import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _activeFilter = 'all';

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'label': 'Tất cả', 'count': 6},
    {'id': 'active', 'label': 'Hoạt động', 'count': 5},
    {'id': 'suspended', 'label': 'Bị khóa', 'count': 1},
  ];

  final Map<String, Map<String, dynamic>> _roleMap = {
    'superadmin': {'label': 'Super Admin', 'bgColor': const Color(0xFFFFEDD5), 'color': const Color(0xFFC2410C)},
    'admin': {'label': 'Admin', 'bgColor': const Color(0xFFFFEDD5), 'color': const Color(0xFFC2410C)},
    'manager': {'label': 'Manager', 'bgColor': const Color(0xFFF3E8FF), 'color': const Color(0xFF7E22CE)},
    'viewer': {'label': 'Viewer', 'bgColor': const Color(0xFFF1F5F9), 'color': const Color(0xFF475569)},
  };

  final List<Map<String, dynamic>> _users = [
    {
      'id': 'USR-001',
      'displayName': 'Đinh Thùy Linh',
      'email': 'thuylinh@zella.vn',
      'role': 'superadmin',
      'twoFa': true,
      'lastLogin': '14 Sep 2026, 09:12',
      'status': 'active',
    },
    {
      'id': 'USR-002',
      'displayName': 'Hoàng Anh Đức',
      'email': 'anhduc@zella.vn',
      'role': 'admin',
      'twoFa': true,
      'lastLogin': '14 Sep 2026, 08:55',
      'status': 'active',
    },
    {
      'id': 'USR-003',
      'displayName': 'Trần Thị Ngọc',
      'email': 'thingoc@zella.vn',
      'role': 'manager',
      'twoFa': false,
      'lastLogin': '13 Sep 2026, 17:30',
      'status': 'active',
    },
    {
      'id': 'USR-004',
      'displayName': 'Phùng Minh Tú',
      'email': 'minhtu@zella.vn',
      'role': 'manager',
      'twoFa': true,
      'lastLogin': '13 Sep 2026, 14:02',
      'status': 'active',
    },
    {
      'id': 'USR-005',
      'displayName': 'Bùi Khánh Linh',
      'email': 'khanhlinh@zella.vn',
      'role': 'viewer',
      'twoFa': false,
      'lastLogin': '01 Sep 2026, 11:00',
      'status': 'active',
    },
    {
      'id': 'USR-006',
      'displayName': 'Cựu NV - Nguyễn X',
      'email': 'former@zella.vn',
      'role': 'viewer',
      'twoFa': false,
      'lastLogin': '10 Aug 2026, 09:00',
      'status': 'suspended',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final visibleUsers = _activeFilter == 'all'
        ? _users
        : _users.where((u) => u['status'] == _activeFilter).toList();

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
                  Text('Tài khoản hệ thống', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('Quản lý tài khoản admin và phân quyền truy cập.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
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
                    label: const Text('Tạo tài khoản'),
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
                  DataColumn(label: Text('User ID')),
                  DataColumn(label: Text('Họ tên')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Vai trò')),
                  DataColumn(label: Text('2FA')),
                  DataColumn(label: Text('Đăng nhập lần cuối')),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('')),
                ],
                rows: visibleUsers.map((u) {
                  final role = _roleMap[u['role']]!;
                  final isActive = u['status'] == 'active';
                  final twoFa = u['twoFa'] as bool;
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(u['id'], style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(u['displayName'], style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(u['email'], style: const TextStyle(color: AppTheme.textSecondary))),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (twoFa ? AppTheme.success : AppTheme.border).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: twoFa ? AppTheme.success.withOpacity(0.3) : AppTheme.border),
                          ),
                          child: Text(
                            twoFa ? 'Bật' : 'Tắt',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: twoFa ? AppTheme.success : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(u['lastLogin'], style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isActive ? AppTheme.success : AppTheme.danger).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isActive ? 'Hoạt động' : 'Bị khóa',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? AppTheme.success : AppTheme.danger),
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
                            icon: const Icon(Icons.shield_outlined, size: 20), // Placeholder for shield_off
                            color: !isActive ? AppTheme.success : AppTheme.textSecondary,
                            onPressed: () {},
                            tooltip: 'Khóa tài khoản',
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
