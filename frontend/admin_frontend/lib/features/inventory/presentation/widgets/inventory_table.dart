import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class InventoryTable extends StatelessWidget {
  final String activeTab;
  
  const InventoryTable({
    super.key,
    required this.activeTab,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> allItems = [
      {'sku': 'MA-COAT-01', 'name': 'Cashmere Double-Breasted Coat', 'category': 'Áo khoác', 'warehouse': 'HN-01', 'qty': 12, 'reserved': 2, 'reorderPoint': 5, 'stockStatus': 'ok', 'updatedAt': '14 Sep'},
      {'sku': 'LEA-BAG-09', 'name': 'Smooth Calfskin Shoulder Bag', 'category': 'Phụ kiện', 'warehouse': 'HCM-02', 'qty': 4, 'reserved': 1, 'reorderPoint': 6, 'stockStatus': 'low', 'updatedAt': '13 Sep'},
      {'sku': 'FTW-DRB-42', 'name': 'Sculpted Derby Shoes', 'category': 'Giày', 'warehouse': 'HN-01', 'qty': 18, 'reserved': 3, 'reorderPoint': 5, 'stockStatus': 'ok', 'updatedAt': '12 Sep'},
      {'sku': 'RTW-DRS-07', 'name': 'Silk Wrap Midi Dress', 'category': 'RTW', 'warehouse': 'HCM-02', 'qty': 0, 'reserved': 0, 'reorderPoint': 4, 'stockStatus': 'out', 'updatedAt': '10 Sep'},
      {'sku': 'ACC-SCF-15', 'name': 'Cashmere Houndstooth Scarf', 'category': 'Phụ kiện', 'warehouse': 'HN-01', 'qty': 3, 'reserved': 0, 'reorderPoint': 5, 'stockStatus': 'low', 'updatedAt': '09 Sep'},
      {'sku': 'RTW-JKT-22', 'name': 'Wool-Blend Structured Jacket', 'category': 'RTW', 'warehouse': 'HN-01', 'qty': 21, 'reserved': 4, 'reorderPoint': 5, 'stockStatus': 'ok', 'updatedAt': '08 Sep'},
    ];

    final visibleItems = activeTab == 'all' 
        ? allItems 
        : allItems.where((i) => i['stockStatus'] == activeTab).toList();

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
              Expanded(flex: 3, child: Text('Sản phẩm', style: _headerStyle())),
              Expanded(flex: 1, child: Text('Kho', style: _headerStyle())),
              Expanded(flex: 1, child: Text('Tồn', style: _headerStyle())),
              Expanded(flex: 1, child: Text('Chờ xuất', style: _headerStyle())),
              Expanded(flex: 1, child: Text('Điểm đặt lại', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Cập nhật', style: _headerStyle())),
              Expanded(flex: 1, child: Text('Trạng thái', style: _headerStyle())),
              const SizedBox(width: 48), // Action space
            ],
          ),
        ),
        // Data Rows
        if (visibleItems.isEmpty)
          const Padding(
            padding: EdgeInsets.all(48.0),
            child: Center(child: Text('Không có dữ liệu', style: TextStyle(color: AppTheme.textSecondary))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleItems.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              final item = visibleItems[index];
              return _buildDataRow(context, item);
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

  Map<String, dynamic> _getStockBadge(String stockStatus) {
    switch (stockStatus) {
      case 'ok':
        return {'label': 'Đang có', 'color': AppTheme.success};
      case 'low':
        return {'label': 'Tồn ít', 'color': AppTheme.warning};
      case 'out':
        return {'label': 'Hết hàng', 'color': AppTheme.danger};
      default:
        return {'label': 'Chưa rõ', 'color': AppTheme.textSecondary};
    }
  }

  Widget _buildDataRow(BuildContext context, Map<String, dynamic> item) {
    final badge = _getStockBadge(item['stockStatus']);

    return InkWell(
      onTap: () {},
      hoverColor: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    item['sku'],
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                item['warehouse'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${item['qty']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${item['reserved']}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${item['reorderPoint']}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item['updatedAt'],
                style: const TextStyle(color: AppTheme.textSecondary),
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
                        Text('Cập nhật tồn kho'),
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
            'Hiển thị 1-10 trong số 85 sản phẩm',
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
