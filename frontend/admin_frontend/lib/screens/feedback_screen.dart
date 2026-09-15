import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import '../widgets/detail_drawer.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String _activeFilter = 'all';

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'label': 'Tất cả', 'count': 34},
    {'id': 'pending', 'label': 'Chờ duyệt', 'count': 7},
    {'id': 'published', 'label': 'Đã duyệt', 'count': 24},
    {'id': 'rejected', 'label': 'Từ chối', 'count': 3},
  ];

  final List<Map<String, dynamic>> _feedbacks = [
    {
      'id': 'FB-034',
      'customer': 'Nguyễn Lan Phương',
      'customerEmail': 'lanphuong@email.com',
      'product': 'Cashmere Double-Breasted Coat',
      'productSku': 'COAT-CASH-001',
      'rating': 5,
      'comment': 'Sản phẩm tuyệt vời, chất vải rất cao cấp và đường may tinh tế. Sẽ quay lại mua thêm.',
      'sentiment': 'positive',
      'status': 'published',
      'createdAt': '13 Sep 2026',
      'responses': [
        {'author': 'Admin (Hệ thống)', 'text': 'Cảm ơn chị Phương đã tin tưởng và ủng hộ Zella. Chúc chị một ngày tốt lành!', 'date': '14 Sep 2026 09:30'}
      ]
    },
    {
      'id': 'FB-033',
      'customer': 'Trần Hải Đăng',
      'customerEmail': 'haidang@email.com',
      'product': 'Wool-Blend Structured Jacket',
      'productSku': 'JKT-WOOL-002',
      'rating': 4,
      'comment': 'Áo đẹp, giao hàng nhanh. Kích cỡ hơi rộng so với bảng size.',
      'sentiment': 'positive',
      'status': 'published',
      'createdAt': '12 Sep 2026',
      'responses': []
    },
    {
      'id': 'FB-032',
      'customer': 'Hoàng Mai Ly',
      'customerEmail': 'maily@email.com',
      'product': 'Silk Wrap Midi Dress',
      'productSku': 'DRS-SILK-003',
      'rating': 2,
      'comment': 'Màu sắc thực tế khác khá nhiều so với ảnh trên web. Không hài lòng lắm.',
      'sentiment': 'negative',
      'status': 'pending',
      'createdAt': '11 Sep 2026',
      'responses': []
    },
    {
      'id': 'FB-031',
      'customer': 'Lê Gia Bảo',
      'customerEmail': 'giabao@email.com',
      'product': 'Sculpted Derby Shoes',
      'productSku': 'SHO-DERB-004',
      'rating': 5,
      'comment': 'Đôi giày hoàn hảo. Chất da mềm, kiểu dáng lịch lãm và rất thoải mái khi đi.',
      'sentiment': 'positive',
      'status': 'published',
      'createdAt': '10 Sep 2026',
      'responses': []
    },
    {
      'id': 'FB-029',
      'customer': 'Phạm Minh Anh',
      'customerEmail': 'minhanh@email.com',
      'product': 'Cashmere Houndstooth Scarf',
      'productSku': 'ACC-HOUND-006',
      'rating': 1,
      'comment': 'Sản phẩm không đúng mô tả, yêu cầu đổi trả.',
      'sentiment': 'negative',
      'status': 'rejected',
      'createdAt': '08 Sep 2026',
      'responses': [
        {'author': 'CSKH - Ngọc Anh', 'text': 'Chào bạn, Zella rất xin lỗi về trải nghiệm này. Bộ phận CSKH đã liên hệ qua số điện thoại để hỗ trợ đổi trả ạ.', 'date': '08 Sep 2026 14:20'}
      ]
    },
  ];

  final Map<String, Map<String, dynamic>> _statusMap = {
    'published': {'label': 'Đã duyệt', 'color': AppTheme.success},
    'pending': {'label': 'Chờ duyệt', 'color': AppTheme.warning},
    'rejected': {'label': 'Từ chối', 'color': AppTheme.danger},
  };

  final Map<String, Map<String, dynamic>> _sentimentMap = {
    'positive': {'label': 'Tích cực', 'color': AppTheme.success, 'bgColor': const Color(0xFFDCFCE7)},
    'neutral': {'label': 'Trung lập', 'color': AppTheme.warning, 'bgColor': const Color(0xFFFEF9C3)},
    'negative': {'label': 'Tiêu cực', 'color': AppTheme.danger, 'bgColor': const Color(0xFFFEE2E2)},
  };

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          Icons.star,
          size: 14,
          color: index < rating ? const Color(0xFFFBBF24) : AppTheme.border,
        );
      }),
    );
  }

  void _openFeedbackDrawer(Map<String, dynamic> feedback) {
    final statusInfo = _statusMap[feedback['status']]!;
    final sentimentInfo = _sentimentMap[feedback['sentiment']]!;

    MainScreen.of(context).openDrawer(
      DetailDrawer(
        title: 'Chi tiết Đánh giá\n${feedback['id']}',
        onClose: () => MainScreen.of(context).closeDrawer(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin chung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow('Khách hàng', feedback['customer']),
            _buildInfoRow('Sản phẩm', feedback['product']),
            _buildInfoRow('Trạng thái', statusInfo['label'], valueStyle: TextStyle(color: statusInfo['color'], fontWeight: FontWeight.bold)),
            _buildInfoRow('Ngày đánh giá', feedback['createdAt']),
            
            const SizedBox(height: 32),
            const Text('Nội dung Đánh giá', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStarRating(feedback['rating']),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: sentimentInfo['bgColor'],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          sentimentInfo['label'],
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sentimentInfo['color']),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('"${feedback['comment']}"', style: const TextStyle(fontSize: 14, height: 1.5, fontStyle: FontStyle.italic)),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text('Phản hồi từ Cửa hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            if ((feedback['responses'] as List).isNotEmpty)
              Column(
                children: (feedback['responses'] as List).map((resp) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: const Border(
                        left: BorderSide(color: AppTheme.primary, width: 4),
                        top: BorderSide(color: AppTheme.border),
                        right: BorderSide(color: AppTheme.border),
                        bottom: BorderSide(color: AppTheme.border),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(resp['author'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(resp['date'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(resp['text'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
                      ],
                    ),
                  );
                }).toList(),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Chưa có phản hồi.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted)),
              ),
              
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung phản hồi khách hàng...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Gửi phản hồi'),
              ),
            ),
            
            if (feedback['status'] == 'pending') ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white),
                      child: const Text('Duyệt hiển thị'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger, side: const BorderSide(color: AppTheme.danger)),
                      child: const Text('Từ chối'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              style: valueStyle ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleFeedbacks = _activeFilter == 'all'
        ? _feedbacks
        : _feedbacks.where((f) => f['status'] == _activeFilter).toList();

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
                  Text('Đánh giá khách hàng', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('Xem và kiểm duyệt feedback của khách hàng trên sản phẩm.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Xuất'),
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
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Khách hàng')),
                  DataColumn(label: Text('Sản phẩm')),
                  DataColumn(label: Text('Sao')),
                  DataColumn(label: Text('Nội dung')),
                  DataColumn(label: Text('Cảm xúc')),
                  DataColumn(label: Text('Ngày')),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('')),
                ],
                rows: visibleFeedbacks.map((fb) {
                  final statusInfo = _statusMap[fb['status']]!;
                  final sentimentInfo = _sentimentMap[fb['sentiment']]!;
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(fb['id'], style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(fb['customer'], style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(SizedBox(
                        width: 150,
                        child: Text(fb['product'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis),
                      )),
                      DataCell(_buildStarRating(fb['rating'])),
                      DataCell(SizedBox(
                        width: 250,
                        child: Text(fb['comment'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                      )),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: sentimentInfo['bgColor'],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            sentimentInfo['label'] as String,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sentimentInfo['color'] as Color),
                          ),
                        ),
                      ),
                      DataCell(Text(fb['createdAt'], style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (statusInfo['color'] as Color).withOpacity(0.1),
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
                          if (fb['status'] == 'pending') ...[
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, size: 20),
                              color: AppTheme.success,
                              onPressed: () => _openFeedbackDrawer(fb),
                              tooltip: 'Xem & Duyệt',
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined, size: 20),
                              color: AppTheme.danger,
                              onPressed: () {},
                              tooltip: 'Từ chối',
                            ),
                          ] else
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 20),
                              color: AppTheme.textSecondary,
                              onPressed: () => _openFeedbackDrawer(fb),
                              tooltip: 'Xem chi tiết',
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
