import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng quan',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.text),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Theo dõi hoạt động kinh doanh, đơn hàng và doanh thu hôm nay.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('Xuất báo cáo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.text,
                        side: const BorderSide(color: AppTheme.borderLight),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tạo đơn hàng'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.text,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // KPI Grid
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Doanh thu tháng',
                    badgeText: '+8.5%',
                    badgeColor: AppTheme.success,
                    value: '145.000.000 ₫',
                    footerText: 'Cập nhật lúc 10:30',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Đơn hàng',
                    badgeText: 'Tháng này',
                    badgeColor: AppTheme.textSecondary,
                    value: '38 đơn',
                    footerText: '6 đơn đang chuẩn bị',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Tồn kho',
                    badgeText: 'Hiện tại',
                    badgeColor: AppTheme.textSecondary,
                    value: '85 SP',
                    footerText: '4 sản phẩm sắp hết',
                    footerColor: AppTheme.warning,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Khách hàng',
                    badgeText: 'Khách VIP',
                    badgeColor: AppTheme.textSecondary,
                    value: '45 người',
                    footerText: '12 lịch hẹn tư vấn',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Layout Bottom
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF0F0F0)),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Đơn hàng gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Xem tất cả', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildRecentOrderRow('ORD-1042', 'Nguyễn Lan Phương', '14 Sep', '3.100.000 ₫', 'Đã giao', AppTheme.success),
                        const Divider(color: AppTheme.borderLight, height: 24),
                        _buildRecentOrderRow('ORD-1041', 'Trần Hải Đăng', '13 Sep', '2.500.000 ₫', 'Đang xử lý', AppTheme.warning),
                        const Divider(color: AppTheme.borderLight, height: 24),
                        _buildRecentOrderRow('ORD-1040', 'Lê Gia Bảo', '12 Sep', '600.000 ₫', 'Đã hủy', AppTheme.danger),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF0F0F0)),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sản phẩm bán chạy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        _buildBestsellerRow('MA-COAT-01', 'Cashmere Double-Breasted Coat', 'Áo khoác', 9),
                        const SizedBox(height: 16),
                        _buildBestsellerRow('RTW-JKT-22', 'Wool-Blend Structured Jacket', 'RTW', 7),
                        const SizedBox(height: 16),
                        _buildBestsellerRow('LEA-BAG-09', 'Smooth Calfskin Shoulder Bag', 'Phụ kiện', 6),
                        const SizedBox(height: 16),
                        _buildBestsellerRow('FTW-DRB-42', 'Sculpted Derby Shoes', 'Giày', 5),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrderRow(String id, String customer, String date, String total, String status, Color statusColor) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(id, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customer, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(total, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBestsellerRow(String sku, String name, String category, int qty) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: const Icon(Icons.image_outlined, color: AppTheme.textMuted, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(sku, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('$qty đã bán', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required String value,
    required String footerText,
    Color footerColor = AppTheme.textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor == AppTheme.textSecondary ? AppTheme.surface : badgeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            footerText,
            style: TextStyle(color: footerColor, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
