import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_dialog.dart';
import '../../data/models/customer_response_model.dart';
import '../providers/customers_provider.dart';

class CustomerDetailDialog extends StatefulWidget {
  final int customerId;
  const CustomerDetailDialog({super.key, required this.customerId});

  @override
  State<CustomerDetailDialog> createState() => _CustomerDetailDialogState();
}

class _CustomerDetailDialogState extends State<CustomerDetailDialog> {
  late Future<CustomerResponseModel> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<CustomersProvider>().loadDetail(widget.customerId);
  }

  String _value(String? text) =>
      text == null || text.trim().isEmpty ? '—' : text;

  @override
  Widget build(BuildContext context) {
    return ZellaDialog(
      width: 700,
      height: (MediaQuery.sizeOf(context).height * 0.84).clamp(0.0, 700.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Chi tiết khách hàng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Đóng',
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(backgroundColor: AppTheme.surface),
                icon: const Icon(Symbols.close, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<CustomerResponseModel>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Symbols.person_off,
                          color: AppTheme.textMuted,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        const Text('Không tải được thông tin khách hàng.'),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => setState(
                            () => _future = context
                                .read<CustomersProvider>()
                                .loadDetail(widget.customerId),
                          ),
                          icon: const Icon(Symbols.refresh, size: 18),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                final customer = snapshot.data!;
                final name = customer.fullName.trim().isNotEmpty
                    ? customer.fullName.trim()
                    : customer.username.trim();
                final tier = switch (customer.membershipTier.toUpperCase()) {
                  'STANDARD' => 'Thành viên',
                  'SILVER' => 'Hạng Bạc',
                  'GOLD' => 'Hạng Vàng',
                  _ => customer.membershipTier,
                };
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 4, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.primary,
                              child: Text(
                                name.isEmpty
                                    ? '?'
                                    : name.characters.first.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectableText(
                                    _value(name),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _badge(
                                        tier,
                                        AppTheme.textSecondary,
                                        Colors.white,
                                      ),
                                      _badge(
                                        customer.isActive
                                            ? 'Hoạt động'
                                            : 'Đã khóa',
                                        customer.isActive
                                            ? AppTheme.success
                                            : AppTheme.danger,
                                        customer.isActive
                                            ? AppTheme.success.withValues(
                                                alpha: 0.08,
                                              )
                                            : AppTheme.danger.withValues(
                                                alpha: 0.08,
                                              ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth < 380
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 12) / 2;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: width,
                                child: _metric(
                                  'Điểm thưởng',
                                  NumberFormat.decimalPattern('vi_VN')
                                      .format(customer.rewardPoints),
                                  Symbols.loyalty,
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: _metric(
                                  'Tổng chi tiêu',
                                  '${NumberFormat.decimalPattern('vi_VN').format(customer.totalSpending)} VND',
                                  Symbols.payments,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Thông tin liên hệ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _row('Email', customer.email),
                      _row('Số điện thoại', customer.phone),
                      _row('Địa chỉ', customer.address),
                      const SizedBox(height: 20),
                      const Text(
                        'Thông tin tài khoản',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _row('Tên đăng nhập', customer.username),
                      _row(
                        'Ngày tạo',
                        customer.createdAt == null
                            ? null
                            : DateFormat('dd/MM/yyyy · HH:mm')
                                  .format(customer.createdAt!.toLocal()),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color, Color background) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      _value(text),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
    ),
  );

  Widget _metric(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: AppTheme.borderLight),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SelectableText(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _row(String label, String? value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final title = Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        );
        final detail = SelectableText(
          _value(value),
          style: const TextStyle(fontSize: 13, color: AppTheme.text),
        );
        if (constraints.maxWidth < 400) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 6), detail],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 150, child: title),
            const SizedBox(width: 12),
            Expanded(child: detail),
          ],
        );
      },
    ),
  );
}
