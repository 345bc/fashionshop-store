import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class FeedbackTable extends StatelessWidget {
  final String activeTab;
  
  const FeedbackTable({
    super.key,
    required this.activeTab,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> allFeedbacks = [
      {
        'id': 'FB-034',
        'customer': 'Nguyễn Lan Phương',
        'customerEmail': 'lanphuong@email.com',
        'product': 'Cashmere Double-Breasted Coat',
        'productSku': 'COAT-CASH-001',
        'rating': 5,
        'comment': 'Sản phẩm tuyệt vời, chất vải rất cao cấp và đường may tinh tế. Sẽ quay lại mua thêm.',
        'status': 'published',
        'createdAt': '13 Sep 2026',
      },
      {
        'id': 'FB-033',
        'customer': 'Trần Hải Đăng',
        'customerEmail': 'haidang@email.com',
        'product': 'Wool-Blend Structured Jacket',
        'productSku': 'JKT-WOOL-002',
        'rating': 4,
        'comment': 'Áo đẹp, giao hàng nhanh. Kích cỡ hơi rộng so với bảng size.',
        'status': 'published',
        'createdAt': '12 Sep 2026',
      },
      {
        'id': 'FB-032',
        'customer': 'Hoàng Mai Ly',
        'customerEmail': 'maily@email.com',
        'product': 'Silk Wrap Midi Dress',
        'productSku': 'DRS-SILK-003',
        'rating': 2,
        'comment': 'Màu sắc thực tế khác khá nhiều so với ảnh trên web. Không hài lòng lắm.',
        'status': 'pending',
        'createdAt': '11 Sep 2026',
      },
      {
        'id': 'FB-031',
        'customer': 'Lê Gia Bảo',
        'customerEmail': 'giabao@email.com',
        'product': 'Sculpted Derby Shoes',
        'productSku': 'SHO-DERB-004',
        'rating': 5,
        'comment': 'Đôi giày hoàn hảo. Chất da mềm, kiểu dáng lịch lãm và rất thoải mái khi đi.',
        'status': 'published',
        'createdAt': '10 Sep 2026',
      },
      {
        'id': 'FB-029',
        'customer': 'Phạm Minh Anh',
        'customerEmail': 'minhanh@email.com',
        'product': 'Cashmere Houndstooth Scarf',
        'productSku': 'ACC-HOUND-006',
        'rating': 1,
        'comment': 'Sản phẩm không đúng mô tả, yêu cầu đổi trả.',
        'status': 'rejected',
        'createdAt': '08 Sep 2026',
      },
    ];

    final visibleFeedbacks = activeTab == 'all' 
        ? allFeedbacks 
        : allFeedbacks.where((f) => f['status'] == activeTab).toList();

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
              Expanded(flex: 3, child: Text('Sản phẩm', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Đánh giá', style: _headerStyle())),
              Expanded(flex: 4, child: Text('Nội dung', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Trạng thái', style: _headerStyle())),
              Expanded(flex: 2, child: Text('Ngày gửi', style: _headerStyle())),
              const SizedBox(width: 48), // Action space
            ],
          ),
        ),
        // Data Rows
        if (visibleFeedbacks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(48.0),
            child: Center(child: Text('Không có dữ liệu', style: TextStyle(color: AppTheme.textSecondary))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleFeedbacks.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              final feedback = visibleFeedbacks[index];
              return _buildDataRow(context, feedback);
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
      case 'published':
        return {'label': 'Đã duyệt', 'color': AppTheme.success};
      case 'pending':
        return {'label': 'Chờ duyệt', 'color': AppTheme.warning};
      case 'rejected':
        return {'label': 'Từ chối', 'color': AppTheme.danger};
      default:
        return {'label': 'Chưa rõ', 'color': AppTheme.textSecondary};
    }
  }

  Widget _buildDataRow(BuildContext context, Map<String, dynamic> feedback) {
    final badge = _getStatusBadge(feedback['status']);

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
                  Text(feedback['customer'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(feedback['customerEmail'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feedback['product'],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(feedback['productSku'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('${feedback['rating']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                feedback['comment'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
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
            Expanded(
              flex: 2,
              child: Text(
                feedback['createdAt'],
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
                        Text('Xem chi tiết'),
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
            'Hiển thị 1-10 trong số 34 phản hồi',
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
