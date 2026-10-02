import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../main.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/pagination_footer.dart';
import '../../data/models/campaign_model.dart';
import '../dialogs/campaign_form_dialog.dart';
import '../dialogs/campaign_detail_dialog.dart';
import '../providers/campaigns_provider.dart';
import '../widgets/campaign_status_badge.dart';

class CampaignManagementScreen extends StatefulWidget {
  final CampaignKind kind;
  const CampaignManagementScreen({super.key, required this.kind});
  @override
  State<CampaignManagementScreen> createState() =>
      _CampaignManagementScreenState();
}

class _CampaignManagementScreenState extends State<CampaignManagementScreen> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) context.read<CampaignsProvider>().refreshStatuses();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CampaignsProvider>();
    final voucher = widget.kind == CampaignKind.voucher;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => MainScreen.of(context).navigate('/promotions'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voucher & Khuyến mãi'),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 24,
              runSpacing: 16,
              children: [
                Text(
                  'Quản lý ${widget.kind.label.toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _form(p),
                  icon: const Icon(Icons.add),
                  label: Text('Thêm ${widget.kind.label.toLowerCase()}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              voucher
                  ? 'Mã khách nhập ở bước đặt hàng; kiểm tra điều kiện và giới hạn lượt dùng.'
                  : 'Giảm giá tự động cho sản phẩm được chọn; áp dụng cho các biến thể của sản phẩm.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Dữ liệu mẫu • Thay đổi chỉ lưu trong lần mở ứng dụng này.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            FeatureToolbar(
              searchHint: voucher
                  ? 'Tìm mã voucher, tên hoặc mô tả...'
                  : 'Tìm tên chương trình hoặc mô tả...',
              initialSearchText: p.query,
              onSearchChanged: p.setQuery,
              filterWidget: DropdownButton<CampaignStatus>(
                value: p.filter,
                hint: const Text('Tất cả trạng thái'),
                items: [
                  const DropdownMenuItem<CampaignStatus>(
                    value: null,
                    child: Text('Tất cả trạng thái'),
                  ),
                  for (final state in CampaignStatus.values)
                    if (voucher || state != CampaignStatus.exhausted)
                      DropdownMenuItem(value: state, child: Text(state.label)),
                ],
                onChanged: p.setFilter,
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: c.maxWidth < 1050 ? 1050 : c.maxWidth,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              for (final h in [
                                'CHƯƠNG TRÌNH',
                                'MỨC GIẢM',
                                voucher ? 'ĐIỀU KIỆN / LƯỢT DÙNG' : 'SẢN PHẨM',
                                'THỜI GIAN',
                                'TRẠNG THÁI',
                              ])
                                Expanded(
                                  flex: h == 'CHƯƠNG TRÌNH' ? 2 : 1,
                                  child: Text(
                                    h,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 40),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        if (p.pageItems(widget.kind).isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(48),
                            child: Text('Không có chương trình phù hợp.'),
                          ),
                        for (final item in p.pageItems(widget.kind)) ...[
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              hoverColor: AppTheme.surface,
                              onTap: () => _detail(p, item),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (item is VoucherModel)
                                            Text(
                                              item.code,
                                              style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Expanded(child: Text(item.discountLabel)),
                                    Expanded(
                                      child: Text(
                                        item is VoucherModel
                                            ? 'Từ ${money(item.minOrderAmount)}\n${item.usedCount} / ${item.usageLimit ?? '∞'} lượt'
                                            : '${(item as PromotionModel).products.length} sản phẩm',
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${campaignDate(item.startsAt)}\n${campaignDate(item.endsAt)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: CampaignStatusBadge(
                                          status: p.status(item),
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (action) => action == 'view'
                                          ? _detail(p, item)
                                          : _form(p, item),
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'view',
                                          child: Text('Xem chi tiết'),
                                        ),
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Chỉnh sửa'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                        PaginationFooter(
                          currentPage: p.currentPage,
                          totalPages: p.filtered(widget.kind).isEmpty
                              ? 1
                              : (p.filtered(widget.kind).length / p.pageSize)
                                    .ceil(),
                          totalElements: p.filtered(widget.kind).length,
                          pageSize: p.pageSize,
                          onPageChanged: (page) => p.setPage(widget.kind, page),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _form(CampaignsProvider p, [CampaignModel? item]) => showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: p,
      child: CampaignFormDialog(kind: widget.kind, item: item),
    ),
  );
  void _detail(CampaignsProvider p, CampaignModel item) => showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: p,
      child: CampaignDetailDialog(id: item.id),
    ),
  );
}
