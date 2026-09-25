import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class PurchasesTable extends StatelessWidget {
  final String activeTab;
  
  const PurchasesTable({
    super.key,
    required this.activeTab,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> allReceipts = [
      {
        'id': 'PO-2026-024',
        'supplier': 'Công ty Vải Hà Nội',
        'items': 5,
        'totalCost': '48.500.000 ₫',
        'status': 'received',
        'receivedAt': '13 Sep 2026',
        'note': 'Lô cashmere FW26',
      },
      {
        'id': 'PO-2026-023',
        'supplier': 'Milano Fabrics Import',
        'items': 3,
        'totalCost': '32.000.000 ₫',
        'status': 'pending',
        'receivedAt': '—',
        'note': 'Vải len Biella cao cấp',
      },
      {
        'id': 'PO-2026-022',
        'supplier': 'Leather House HCM',
        'items': 8,
        'totalCost': '76.200.000 ₫',
        'status': 'received',
        'receivedAt': '10 Sep 2026',
        'note': 'Da bê thuộc Pháp',
      },
    ];

    final visibleReceipts = activeTab == 'all' 
        ? allReceipts 
        : allReceipts.where((r) => r['status'] == activeTab).toList();

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
              Expanded(flex: 2, child: Text('Mã Phiếu', style: _headerStyle())),
              Expanded(flex: 3, child: Text('Nhà cung cấp', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Chi tiết', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Tổng tiền', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Ngày nhận', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Trạng thái', style: _headerStyle())),
              const SizedBox(width: 48), // Action space
            ],
          ),
        ),
        // Data Rows
        if (visibleReceipts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(48.0),
            child: Center(child: Text('Không có dữ liệu', style: TextStyle(color: AppTheme.textSecondary))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleReceipts.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              final receipt = visibleReceipts[index];
              return _buildDataRow(context, receipt);
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

  Map<String, dynamic> _getStatusBadge(String status) {
    switch (status) {
      case 'received':
        return {'label': 'Đã nhận', 'color': AppTheme.success};
      case 'pending':
        return {'label': 'Chờ nhận', 'color': AppTheme.warning};
      case 'cancelled':
        return {'label': 'Đã hủy', 'color': AppTheme.danger};
      default:
        return {'label': 'Chưa rõ', 'color': AppTheme.textSecondary};
    }
  }

  Widget _buildDataRow(BuildContext context, Map<String, dynamic> receipt) {
    final badge = _getStatusBadge(receipt['status']);

    return InkWell(
      onTap: () {},
      hoverColor: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                receipt['id'],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                receipt['supplier'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${receipt['items']} SP', style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    receipt['note'],
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                receipt['totalCost'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                receipt['receivedAt'],
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        Text('Xem phiếu'),
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
            'Hiển thị 1-10 trong số 24 phiếu nhập',
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
