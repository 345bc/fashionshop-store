import '../models/campaign_model.dart';

/// Demo catalog and campaigns; does not access product/order APIs.
class CampaignRepository {
  static const catalog = [
    PromotionProductModel(1, 'Áo sơ mi nam Oxford trắng'),
    PromotionProductModel(2, 'Áo sơ mi nữ lụa cổ nơ'),
    PromotionProductModel(3, 'Váy nữ midi xếp ly'),
    PromotionProductModel(4, 'Quần jeans nữ ống đứng'),
  ];
  final List<CampaignModel> _items;
  CampaignRepository({DateTime? now}) : _items = _seed(now ?? DateTime.now());
  List<CampaignModel> get items => List.unmodifiable(_items);
  int nextId() => _items.fold<int>(0, (v, r) => v > r.id ? v : r.id) + 1;
  void save(CampaignModel item) {
    final index = _items.indexWhere((r) => r.id == item.id);
    if (index < 0) {
      _items.add(item);
    } else {
      _items[index] = item;
    }
  }

  static List<CampaignModel> _seed(DateTime now) => [
    for (var i = 0; i < 5; i++)
      VoucherModel(
        id: i + 1,
        name: [
          'Chào khách mới',
          'Giảm 50.000 đ',
          'Ưu đãi tháng tới',
          'Mã đã tắt',
          'Ưu đãi đã kết thúc',
        ][i],
        code: ['WELCOME10', 'SAVE50K', 'NEXTMONTH', 'MEMBER15', 'SUMMER20'][i],
        description: 'Voucher mẫu áp dụng trên giá trị hàng đủ điều kiện, không gồm phí vận chuyển.',
        startsAt: now.add(Duration(days: i == 2 ? 7 : -7)),
        endsAt: now.add(Duration(days: i == 4 ? -1 : 30)),
        enabled: i != 3,
        discountType: i == 1 ? DiscountType.fixed : DiscountType.percent,
        discountValue: i == 1 ? 50000 : 10,
        minOrderAmount: 300000,
        maxDiscountAmount: i == 1 ? null : 100000,
        usageLimit: 100,
        usedCount: i == 1 ? 100 : 1,
        usages: [
          VoucherUsageModel(
            'ORD-DEMO-${100 + i}',
            'Khách mẫu',
            i == 1 ? 50000 : 30000,
            now.subtract(const Duration(days: 1)),
          ),
        ],
        history: [
          CampaignHistoryModel(
            'Tạo voucher',
            'CSKH (mẫu)',
            now.subtract(const Duration(days: 8)),
          ),
        ],
      ),
    for (var i = 0; i < 4; i++)
      PromotionModel(
        id: 10 + i,
        name: [
          'Ưu đãi áo sơ mi',
          'Bộ sưu tập nữ',
          'Chương trình đã tắt',
          'Sale đã kết thúc',
        ][i],
        description: 'Tự động giảm giá cho các sản phẩm được chọn và tất cả biến thể của chúng.',
        startsAt: now.add(Duration(days: i == 1 ? 5 : -5)),
        endsAt: now.add(Duration(days: i == 3 ? -1 : 20)),
        enabled: i != 2,
        discountPercent: 15 + i * 5,
        products: [catalog[i]],
        history: [
          CampaignHistoryModel(
            'Tạo khuyến mãi',
            'CSKH (mẫu)',
            now.subtract(const Duration(days: 6)),
          ),
        ],
      ),
  ];
}
