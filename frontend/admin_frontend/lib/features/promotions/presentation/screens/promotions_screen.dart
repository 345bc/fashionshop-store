import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../main.dart';
import '../../../../theme/app_theme.dart';
import '../../data/models/campaign_model.dart';
import '../providers/campaigns_provider.dart';

class PromotionsScreen extends StatelessWidget {
  const PromotionsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CampaignsProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Voucher & Khuyến mãi',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chọn phần cần quản lý',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Dữ liệu mẫu • Chưa áp dụng vào giá sản phẩm hoặc đơn hàng thực tế.',
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 2 : 1;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final kind in CampaignKind.values)
                    SizedBox(
                      width:
                          (constraints.maxWidth - (columns - 1) * 16) / columns,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            provider.resetFilters();
                            MainScreen.of(context).navigate(
                              kind == CampaignKind.voucher
                                  ? '/vouchers'
                                  : '/promotion-programs',
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.borderLight),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  kind == CampaignKind.voucher
                                      ? Icons.confirmation_number_outlined
                                      : Icons.local_offer_outlined,
                                  size: 32,
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        kind.label,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        kind == CampaignKind.voucher
                                            ? 'Mã giảm giá, điều kiện đơn hàng và lượt sử dụng'
                                            : 'Tự động giảm giá theo sản phẩm và thời gian',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        '${provider.items(kind).length} chương trình mẫu',
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
