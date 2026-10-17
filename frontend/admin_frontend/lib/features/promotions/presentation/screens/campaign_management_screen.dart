import 'package:material_symbols_icons/symbols.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zella_admin_flutter/widgets/common/bulk_action_bar.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/filter_dropdown.dart';
import '../../../../widgets/common/pagination_footer.dart';
import '../../data/models/campaign_model.dart';
import '../dialogs/campaign_form_dialog.dart';
import '../dialogs/campaign_detail_dialog.dart';
import '../providers/campaigns_provider.dart';
import '../widgets/campaign_status_badge.dart';
import '../../../../widgets/common/zella_checkbox.dart';
import '../../../../widgets/common/zella_toast.dart';

class CampaignManagementScreen extends StatefulWidget {
  final CampaignKind kind;
  const CampaignManagementScreen({super.key, required this.kind});
  @override
  State<CampaignManagementScreen> createState() =>
      _CampaignManagementScreenState();
}

class _CampaignManagementScreenState extends State<CampaignManagementScreen> {
  Timer? _timer;
  Set<int> selectedIds = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CampaignsProvider>().load();
    });
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
    if (p.loading && p.items(widget.kind).isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (p.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.error!),
            TextButton(onPressed: p.load, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      icon: const Icon(Symbols.add),
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
                  'Chương trình được lưu trên hệ thống và áp dụng vào giá bán.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                if (voucher) ...[
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Voucher nhập mã'),
                        icon: Icon(Symbols.confirmation_number, size: 18),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Voucher đổi điểm'),
                        icon: Icon(Symbols.redeem, size: 18),
                      ),
                    ],
                    selected: {p.rewardScope},
                    onSelectionChanged: (value) {
                      selectedIds.clear();
                      p.setRewardScope(value.single);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                FeatureToolbar(
                  searchHint: voucher
                      ? 'Tìm mã voucher, tên hoặc mô tả'
                      : 'Tìm tên chương trình hoặc mô tả',
                  initialSearchText: p.query,
                  onSearchChanged: p.setQuery,
                  filterWidget: FilterDropdown<CampaignStatus?>(
                    label: 'Trạng thái',
                    searchHint: 'Tìm trạng thái',
                    value: p.filter,
                    defaultValue: null,
                    options: [
                      for (final state in CampaignStatus.values)
                        if (voucher || state != CampaignStatus.exhausted)
                          FilterOption(value: state, label: state.label),
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
                                  Container(
                                    width: 48,
                                    alignment: Alignment.centerLeft,
                                    child: ZellaCheckbox(
                                      value:
                                          p.pageItems(widget.kind).isNotEmpty &&
                                          selectedIds.length ==
                                              p.pageItems(widget.kind).length,
                                      onChanged: (v) {
                                        setState(() {
                                          if (v == true) {
                                            selectedIds.addAll(
                                              p
                                                  .pageItems(widget.kind)
                                                  .map((e) => e.id),
                                            );
                                          } else {
                                            selectedIds.clear();
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  for (final h in [
                                    'CHƯƠNG TRÌNH',
                                    'MỨC GIẢM',
                                    voucher
                                        ? 'ĐIỀU KIỆN / LƯỢT DÙNG'
                                        : 'SẢN PHẨM',
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
                                  onTap: () => voucher
                                      ? _detail(p, item)
                                      : _form(p, item),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          alignment: Alignment.centerLeft,
                                          child: ZellaCheckbox(
                                            value: selectedIds.contains(
                                              item.id,
                                            ),
                                            onChanged: (v) {
                                              setState(() {
                                                if (v == true) {
                                                  selectedIds.add(item.id);
                                                } else {
                                                  selectedIds.remove(item.id);
                                                }
                                              });
                                            },
                                          ),
                                        ),
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
                                              if (item is VoucherModel &&
                                                  item.name != item.code)
                                                Text(
                                                  item.code,
                                                  style: const TextStyle(
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(item.discountLabel),
                                        ),
                                        Expanded(
                                          child: Text(
                                            item is VoucherModel
                                                ? '${item.redeemable ? '${item.pointsRequired} điểm' : 'Từ ${money(item.minOrderAmount)}'}\n${item.usedCount} / ${item.usageLimit ?? '∞'} lượt'
                                                : '${(item as PromotionModel).products.length} sản phẩm',
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${campaignDate(item.startsAt)}\n${campaignDate(item.endsAt)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
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
                                          onSelected: (action) =>
                                              action == 'view'
                                              ? _detail(p, item)
                                              : _form(p, item),
                                          itemBuilder: (_) => [
                                            if (voucher)
                                              const PopupMenuItem(
                                                value: 'view',
                                                child: Text('Xem chi tiết'),
                                              ),
                                            const PopupMenuItem(
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
                                  : (p.filtered(widget.kind).length /
                                            p.pageSize)
                                        .ceil(),
                              totalElements: p.filtered(widget.kind).length,
                              pageSize: p.pageSize,
                              onPageChanged: (page) =>
                                  p.setPage(widget.kind, page),
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
          BulkActionBar(
            selectedCount: selectedIds.length,
            itemLabel: voucher ? 'voucher' : 'chương trình',
            onClear: () => setState(() => selectedIds.clear()),
            actions: [
              BulkActionButton(
                icon: Symbols.pause,
                tooltip: 'Tạm dừng',
                onPressed: () async {
                  final ids = selectedIds.toList();
                  try {
                    await context.read<CampaignsProvider>().toggleActiveBulk(
                      ids,
                      false,
                    );
                    if (!context.mounted) return;
                    if (true) {
                      ZellaToast.show(
                        context,
                        message: 'Đã tạm dừng ${ids.length} chương trình',
                        type: ToastType.success,
                      );
                    }
                    if (mounted) setState(() => selectedIds.clear());
                  } catch (e) {
                    if (!context.mounted) return;
                    ZellaToast.show(
                      context,
                      message: e.toString(),
                      type: ToastType.error,
                    );
                  }
                },
              ),
              BulkActionButton(
                icon: Symbols.play_arrow,
                tooltip: 'Tiếp tục',
                onPressed: () async {
                  final ids = selectedIds.toList();
                  try {
                    await context.read<CampaignsProvider>().toggleActiveBulk(
                      ids,
                      true,
                    );
                    if (!context.mounted) return;
                    if (true) {
                      ZellaToast.show(
                        context,
                        message: 'Đã tiếp tục ${ids.length} chương trình',
                        type: ToastType.success,
                      );
                    }
                    if (mounted) setState(() => selectedIds.clear());
                  } catch (e) {
                    if (!context.mounted) return;
                    ZellaToast.show(
                      context,
                      message: e.toString(),
                      type: ToastType.error,
                    );
                  }
                },
              ),
            ],
          ),
        ],
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
  Future<void> _detail(CampaignsProvider p, CampaignModel item) async {
    final dialogContext = context;
    try {
      await p.loadDetail(item.id);
    } catch (e) {
      if (!dialogContext.mounted) return;
      ZellaToast.show(
        dialogContext,
        message: e.toString(),
        type: ToastType.error,
      );
      return;
    }
    if (!dialogContext.mounted) return;
    await showDialog(
      context: dialogContext,
      builder: (_) => ChangeNotifierProvider.value(
        value: p,
        child: CampaignDetailDialog(id: item.id),
      ),
    );
  }
}
