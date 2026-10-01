import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class StaffTable extends StatelessWidget {
  final String activeTab;
  
  const StaffTable({
    super.key,
    required this.activeTab,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> allStaff = [
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

    final visibleStaff = activeTab == 'all' 
        ? allStaff 
        : allStaff.where((s) => s['status'] == activeTab).toList();

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
              Expanded(flex: 3, child: Text('Nhân viên', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Liên hệ', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Phòng ban', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Ca làm', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Ngày vào làm', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Trạng thái', style: _headerStyle())),
              const SizedBox(width: 48), // Action space
            ],
          ),
        ),
        // Data Rows
        if (visibleStaff.isEmpty)
          const Padding(
            padding: EdgeInsets.all(48.0),
            child: Center(child: Text('Không có dữ liệu', style: TextStyle(color: AppTheme.textSecondary))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleStaff.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              final staff = visibleStaff[index];
              return _buildDataRow(context, staff);
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

  Map<String, dynamic> _getRoleInfo(String role) {
    switch (role) {
      case 'manager': return {'label': 'Quản lý', 'bgColor': const Color(0xFFF3E8FF), 'color': const Color(0xFF7E22CE)};
      case 'sales': return {'label': 'Bán hàng', 'bgColor': const Color(0xFFE0E7FF), 'color': const Color(0xFF4338CA)};
      case 'warehouse': return {'label': 'Kho', 'bgColor': const Color(0xFFE0E7FF), 'color': const Color(0xFF4338CA)};
      case 'designer': return {'label': 'Thiết kế', 'bgColor': const Color(0xFFFFEDD5), 'color': const Color(0xFFC2410C)};
      case 'accountant': return {'label': 'Kế toán', 'bgColor': const Color(0xFFF3E8FF), 'color': const Color(0xFF7E22CE)};
      default: return {'label': 'Nhân viên', 'bgColor': AppTheme.surface, 'color': AppTheme.textSecondary};
    }
  }

  Widget _buildDataRow(BuildContext context, Map<String, dynamic> staff) {
    final role = _getRoleInfo(staff['role']);

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
                      staff['name'].substring(0, 1),
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff['name'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          staff['id'],
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
                  Text(staff['phone'], style: const TextStyle(fontSize: 13)),
                  Text(staff['email'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: role['bgColor'] as Color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    role['label'] as String,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: role['color'] as Color),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                staff['shift'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                staff['startDate'],
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: staff['status'] == 'active' ? AppTheme.success : AppTheme.warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    staff['status'] == 'active' ? 'Đang làm' : 'Nghỉ phép',
                    style: TextStyle(
                      color: staff['status'] == 'active' ? AppTheme.success : AppTheme.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 48,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Sửa thông tin'),
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
            'Hiển thị 1-6 trong số 9 nhân viên',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Row(
            children: [
              _buildPageBtn(Icons.chevron_left, null),
              const SizedBox(width: 8),
              _buildPageBtn('1', true),
              const SizedBox(width: 8),
              _buildPageBtn(Icons.chevron_right, null),
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
