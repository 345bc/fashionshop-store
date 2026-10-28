import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/zella_toast.dart';
import '../../../../widgets/dialogs/zella_confirm_dialog.dart';
import '../../../../widgets/dialogs/zella_dialog.dart';
import '../../data/models/campaign_model.dart';
import '../providers/campaigns_provider.dart';
import '../widgets/campaign_status_badge.dart';
import 'campaign_form_dialog.dart';
import 'voucher_email_dialog.dart';

class CampaignDetailDialog extends StatefulWidget {
  final int id;
  const CampaignDetailDialog({super.key, required this.id});

  @override
  State<CampaignDetailDialog> createState() => _CampaignDetailDialogState();
}

class _CampaignDetailDialogState extends State<CampaignDetailDialog> {
  bool _toggling = false;

  String _imageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) return url;
    final base = Uri.parse(ApiEndpoints.baseUrl);
    return base.origin + (url.startsWith('/') ? url : '/$url');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CampaignsProvider>();
    final item = p.detail(widget.id);
    final size = MediaQuery.sizeOf(context);

    final dialogWidth = (size.width * 0.85).clamp(860.0, 1160.0);
    final dialogHeight = (size.height * 0.88).clamp(600.0, 840.0);

    return ZellaDialog(
      width: dialogWidth,
      height: dialogHeight,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, p, item),
          const Divider(height: 1, color: AppTheme.border),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 760;
                  if (item is VoucherModel) {
                    return isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildVoucherOverviewCard(item),
                                    const SizedBox(height: 16),
                                    _buildUsageStatsCard(item),
                                    const SizedBox(height: 16),
                                    _buildUsageHistoryCard(item),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildScheduleCard(p, item),
                                    const SizedBox(height: 16),
                                    _buildRulesCard(item),
                                    if (item.imageUrl != null &&
                                        item.imageUrl!.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      _buildBannerCard(item),
                                    ],
                                    if (item.history.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      _buildHistoryCard(item),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildVoucherOverviewCard(item),
                              const SizedBox(height: 16),
                              _buildUsageStatsCard(item),
                              const SizedBox(height: 16),
                              _buildScheduleCard(p, item),
                              const SizedBox(height: 16),
                              _buildRulesCard(item),
                              if (item.imageUrl != null &&
                                  item.imageUrl!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildBannerCard(item),
                              ],
                              const SizedBox(height: 16),
                              _buildUsageHistoryCard(item),
                              if (item.history.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildHistoryCard(item),
                              ],
                            ],
                          );
                  } else if (item is PromotionModel) {
                    return isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildPromotionOverviewCard(item),
                                    const SizedBox(height: 16),
                                    _buildPromotionProductsCard(item),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildScheduleCard(p, item),
                                    if (item.imageUrl != null &&
                                        item.imageUrl!.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      _buildBannerCard(item),
                                    ],
                                    if (item.history.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      _buildHistoryCard(item),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildPromotionOverviewCard(item),
                              const SizedBox(height: 16),
                              _buildScheduleCard(p, item),
                              const SizedBox(height: 16),
                              _buildPromotionProductsCard(item),
                              if (item.history.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildHistoryCard(item),
                              ],
                            ],
                          );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          _buildFooter(context, p, item),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    CampaignsProvider p,
    CampaignModel item,
  ) {
    final isVoucher = item is VoucherModel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  isVoucher ? 'Chi tiết voucher' : 'Chi tiết khuyến mãi',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(width: 12),
                CampaignStatusBadge(status: p.status(item)),
                const SizedBox(width: 8),
                if (isVoucher)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      item.redeemable ? 'Đổi điểm thưởng' : 'Nhập mã checkout',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Symbols.close, size: 20),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }

  Widget _cardTitle(String title, {Widget? trailing}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.text,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing],
      ],
    );
  }

  Widget _buildVoucherOverviewCard(VoucherModel item) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text,
                      ),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 1.0,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Sao chép mã',
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: item.code));
                          ZellaToast.show(
                            context,
                            message: 'Đã sao chép: ${item.code}',
                            type: ToastType.success,
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Symbols.content_copy,
                            size: 15,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _dataField(
                  'MỨC GIẢM',
                  item.discountLabel,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dataField('LOẠI CHIẾT KHẤU', item.discountType.label),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dataField(
                  'ĐƠN TỐI THIỂU',
                  item.minOrderAmount > 0 ? money(item.minOrderAmount) : '0 đ',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dataField(
                  'GIẢM TỐI ĐA',
                  item.maxDiscountAmount != null
                      ? money(item.maxDiscountAmount!)
                      : 'Không giới hạn',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dataField(String label, String value, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isPrimary ? 15 : 13,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
              color: AppTheme.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStatsCard(VoucherModel item) {
    final hasLimit = item.usageLimit != null && item.usageLimit! > 0;
    final remaining = hasLimit
        ? (item.usageLimit! - item.usedCount).clamp(0, item.usageLimit!)
        : null;
    final progress = hasLimit
        ? (item.usedCount / item.usageLimit!).clamp(0.0, 1.0)
        : 0.0;
    final percentage = (progress * 100).toStringAsFixed(1);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Lượt sử dụng & Giới hạn'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  'ĐÃ SỬ DỤNG',
                  '${item.usedCount}',
                  'lượt',
                  AppTheme.text,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statTile(
                  'TỔNG GIỚI HẠN',
                  hasLimit ? '${item.usageLimit}' : '∞',
                  hasLimit ? 'lượt' : 'Vô hạn',
                  AppTheme.text,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statTile(
                  'CÒN LẠI',
                  hasLimit ? '$remaining' : '∞',
                  hasLimit ? 'lượt' : 'Không giới hạn',
                  hasLimit && remaining == 0 ? AppTheme.danger : AppTheme.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasLimit) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tiến độ: $percentage%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  'Đã dùng ${item.usedCount} / ${item.usageLimit} lượt',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppTheme.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? AppTheme.danger : AppTheme.primary,
                ),
              ),
            ),
          ] else
            const Text(
              'Chương trình không giới hạn số lượt sử dụng trong thời gian áp dụng.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, String unit, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageHistoryCard(VoucherModel item) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            item.redeemable ? 'Lịch sử đổi điểm' : 'Đơn hàng áp dụng mã',
            trailing: Text(
              '${item.usages.length} bản ghi gần nhất',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (item.usages.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Chưa có đơn hàng nào áp dụng mã voucher này.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(6),
              ),
              clipBehavior: Clip.antiAlias,
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.5),
                  1: FlexColumnWidth(3),
                  2: FlexColumnWidth(2.5),
                  3: FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AppTheme.surface),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Text(
                          'MÃ ĐƠN HÀNG',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Text(
                          'KHÁCH HÀNG',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Text(
                          'THỜI GIAN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Text(
                          'MỨC GIẢM',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  for (final usage in item.usages)
                    TableRow(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          child: Text(
                            usage.orderCode,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          child: Text(
                            usage.buyer,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          child: Text(
                            campaignDate(usage.usedAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          child: Text(
                            usage.discountType == 'GIFT'
                                ? 'Gói quà'
                                : usage.discountType == 'PERCENT'
                                ? '${usage.discountAmount}%'
                                : money(usage.discountAmount),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(CampaignsProvider p, CampaignModel item) {
    final now = DateTime.now();
    final status = p.status(item);

    String statusText;
    Color statusColor;
    if (now.isBefore(item.startsAt)) {
      statusText = 'Sắp diễn ra';
      statusColor = AppTheme.warning;
    } else if (now.isAfter(item.endsAt)) {
      statusText = 'Đã kết thúc';
      statusColor = AppTheme.danger;
    } else {
      statusText = status == CampaignStatus.paused ? 'Đã tắt' : 'Đang hiệu lực';
      statusColor = status == CampaignStatus.paused
          ? AppTheme.textSecondary
          : AppTheme.success;
    }

    final totalDays = item.endsAt.difference(item.startsAt).inDays;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            'Thời gian hiệu lực',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _infoLine('Bắt đầu', campaignDate(item.startsAt)),
          const SizedBox(height: 8),
          _infoLine('Kết thúc', campaignDate(item.endsAt)),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 10),
          _infoLine(
            'Tổng thời gian',
            totalDays > 0 ? '$totalDays ngày' : 'Trong ngày',
          ),
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildRulesCard(VoucherModel item) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Cài đặt & Điều kiện'),
          const SizedBox(height: 14),
          _ruleItem(
            'Hình thức áp dụng',
            item.redeemable
                ? 'Đổi bằng điểm (${item.pointsRequired ?? 0} điểm)'
                : 'Nhập mã tại bước thanh toán',
          ),
          _ruleItem(
            'Kênh hiển thị',
            item.isDisplay
                ? 'Công khai (Kho voucher)'
                : 'Riêng tư (Chỉ nhập mã)',
          ),
          _ruleItem(
            'Trạng thái',
            item.enabled ? 'Đang kích hoạt' : 'Đang tạm dừng',
            valueColor: item.enabled ? AppTheme.success : AppTheme.danger,
          ),
        ],
      ),
    );
  }

  Widget _ruleItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppTheme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(CampaignModel item) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Ảnh biểu ngữ'),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              _imageUrl(item.imageUrl!),
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 90,
                color: AppTheme.surface,
                child: const Center(
                  child: Icon(
                    Symbols.broken_image,
                    size: 24,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(CampaignModel item) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            'Nhật ký thao tác',
            trailing: Text(
              '${item.history.length} bản ghi',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: item.history.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              final event = item.history.reversed.toList()[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.action,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (event.note.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              event.note,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      campaignDate(event.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionOverviewCard(PromotionModel item) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.text,
            ),
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _dataField(
                  'MỨC GIẢM',
                  '${item.discountPercent}%',
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dataField('CHẾ ĐỘ ÁP DỤNG', 'Sản phẩm chỉ định'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionProductsCard(PromotionModel item) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Sản phẩm áp dụng (${item.products.length})'),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: item.products.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              final p = item.products[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Symbols.check_circle,
                      size: 15,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(p.name, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    CampaignsProvider p,
    CampaignModel item,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Text(
            'Mã ID: #${item.id}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          if (item is VoucherModel && !item.redeemable) ...[
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _toggling || p.status(item) != CampaignStatus.active
                  ? null
                  : () => showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          VoucherEmailDialog(voucher: item, provider: p),
                    ),
              icon: const Icon(Icons.mail_outline, size: 16),
              label: const Text('Gửi theo hạng'),
            ),
          ],
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: _toggling
                ? null
                : () => _confirmToggle(context, p, item),
            child: Text(item.enabled ? 'Tắt voucher' : 'Bật voucher'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => ChangeNotifierProvider.value(
                  value: p,
                  child: CampaignFormDialog(kind: item.kind, item: item),
                ),
              );
              if (context.mounted) {
                await p.loadDetail(item.id);
              }
            },
            icon: const Icon(Symbols.edit, size: 16),
            label: const Text('Chỉnh sửa'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmToggle(
    BuildContext context,
    CampaignsProvider p,
    CampaignModel item,
  ) async {
    final willEnable = !item.enabled;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ZellaConfirmDialog(
        title: willEnable ? 'Bật voucher này?' : 'Tắt voucher này?',
        content: Text(
          willEnable
              ? 'Khi bật lại, voucher "${item.name}" sẽ có hiệu lực ngay theo thời gian đã định.'
              : 'Khi tắt, khách hàng sẽ không thể tiếp tục áp dụng mã "${item.name}".',
        ),
        icon: willEnable ? Symbols.check_circle : Symbols.warning,
        iconColor: willEnable ? AppTheme.success : AppTheme.warning,
        confirmText: willEnable ? 'Bật voucher' : 'Tắt voucher',
        onCancel: () => Navigator.pop(ctx, false),
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );

    if (agreed != true || !mounted) return;

    setState(() => _toggling = true);
    try {
      await p.toggle(item.id);
      if (mounted) {
        await p.loadDetail(item.id);
        if (context.mounted) {
          ZellaToast.show(
            context,
            message: willEnable ? 'Đã bật voucher' : 'Đã tắt voucher',
            type: ToastType.success,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ZellaToast.show(context, message: e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }
}
