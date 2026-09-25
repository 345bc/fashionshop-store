import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class PromotionsTable extends StatelessWidget {
  final String activeTab;
  
  const PromotionsTable({
    super.key,
    required this.activeTab,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> allPromos = [
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

    final visiblePromos = activeTab == 'all' 
        ? allPromos 
        : allPromos.where((p) => p['status'] == activeTab).toList();

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
              Expanded(flex: 2, child: Text('Mã KM', style: _headerStyle())),
              Expanded(flex: 3, child: Text('Tên chương trình', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Giá trị', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Điều kiện', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Đã dùng', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Thời gian', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Trạng thái', style: _headerStyle())),
              const SizedBox(width: 48), // Action space
            ],
          ),
        ),
        // Data Rows
        if (visiblePromos.isEmpty)
          const Padding(
            padding: EdgeInsets.all(48.0),
            child: Center(child: Text('Không có dữ liệu', style: TextStyle(color: AppTheme.textSecondary))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visiblePromos.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              final promo = visiblePromos[index];
              return _buildDataRow(context, promo);
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
      case 'active':
        return {'label': 'Đang chạy', 'color': AppTheme.success};
      case 'scheduled':
        return {'label': 'Sắp diễn ra', 'color': const Color(0xFF4338CA)};
      case 'expired':
        return {'label': 'Đã hết hạn', 'color': AppTheme.textSecondary};
      default:
        return {'label': 'Chưa rõ', 'color': AppTheme.textSecondary};
    }
  }

  Widget _buildDataRow(BuildContext context, Map<String, dynamic> promo) {
    final badge = _getStatusBadge(promo['status']);
    
    // Usage progress
    final int used = promo['used'];
    final int? maxUses = promo['maxUses'];
    final double progress = maxUses != null ? (used / maxUses).clamp(0.0, 1.0) : 0.0;

    return InkWell(
      onTap: () {},
      hoverColor: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Text(
                  promo['code'],
                  style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                promo['name'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                promo['value'],
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Min ${promo['minOrder']}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    maxUses != null ? '$used / $maxUses' : '$used',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (maxUses != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      height: 4,
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: progress > 0.9 ? AppTheme.danger : AppTheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(promo['validFrom'], style: const TextStyle(fontSize: 13)),
                  Text(promo['validTo'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Sửa khuyến mãi'),
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
            'Hiển thị 1-10 trong số 12 khuyến mãi',
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
