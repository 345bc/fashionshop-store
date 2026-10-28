import '../../../../core/network/api_client.dart';
import '../../../inventory/data/api/inventory_repository.dart';
import '../models/campaign_model.dart';
import '../models/voucher_email_model.dart';

class CampaignRepository {
  Future<VoucherEmailPreview> previewVoucherEmail(int id, Set<String> tiers) =>
      warehouseRequest(() async {
        final response = await _api.post(
          '/campaigns/voucher/$id/email/preview',
          data: {'tiers': tiers.toList()..sort()},
        );
        return VoucherEmailPreview.fromJson(
          Map<String, dynamic>.from(response.data['data']),
        );
      });

  Future<VoucherEmailSendResult> sendVoucherEmail(
    int id,
    Set<String> tiers,
    String audienceKey,
  ) => warehouseRequest(() async {
    final response = await _api.post(
      '/campaigns/voucher/$id/email/send',
      data: {'tiers': tiers.toList()..sort(), 'audienceKey': audienceKey},
    );
    return VoucherEmailSendResult.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  });
  final _api = ApiClient();
  final List<CampaignModel> _items = [];
  List<CampaignModel> get items => List.unmodifiable(_items);
  List<PromotionProductModel> catalog = [];
  int nextId() => 0;
  String kind(CampaignModel item) => item.kind.name;
  void replace(CampaignModel item) {
    final index = _items.indexWhere((r) => r.id == item.id);
    if (index < 0) {
      _items.add(item);
    } else {
      _items[index] = item;
    }
  }

  Future<void> load() => warehouseRequest(() async {
    final results = await Future.wait([
      _api.get('/campaigns/voucher'),
      _api.get('/campaigns/promotion'),
      _api.get('/campaigns/products'),
    ]);
    final campaigns = [
      for (final response in results.take(2))
        for (final json in response.data['data'] as List)
          _parse(Map<String, dynamic>.from(json)),
    ];
    catalog = [
      for (final json in results[2].data['data'] as List)
        PromotionProductModel(
          (json['id'] as num).toInt(),
          json['name'] as String,
          categoryId: (json['categoryId'] as num?)?.toInt(),
          categoryName: json['categoryName'] as String?,
        ),
    ];
    _items
      ..clear()
      ..addAll(campaigns);
  });
  Future<void> detail(CampaignModel item) => warehouseRequest(() async {
    final response = await _api.get(
      '/campaigns/${kind(item)}/${item.id.abs()}',
    );
    replace(_parse(Map<String, dynamic>.from(response.data['data'])));
  });
  Future<void> save(CampaignModel item, {required bool creating}) =>
      warehouseRequest(() async {
        final data = <String, dynamic>{
          'name': item.name,
          'description': item.description,
          'startsAt': item.startsAt.toUtc().toIso8601String(),
          'endsAt': item.endsAt.toUtc().toIso8601String(),
          'enabled': item.enabled,
          'imageUrl': item.imageUrl,
          'isDisplay': item.isDisplay,
          if (item is VoucherModel) ...{
            'code': item.code,
            'discountType': item.discountType == DiscountType.percent
                ? 'PERCENT'
                : item.discountType == DiscountType.gift
                ? 'GIFT'
                : 'FIXED',
            'discountValue': item.discountValue,
            'minOrderAmount': item.minOrderAmount,
            'maxDiscountAmount': item.maxDiscountAmount,
            'usageLimit': item.usageLimit,
            'redeemable': item.redeemable,
            'pointsRequired': item.pointsRequired,
          },
          if (item is PromotionModel) ...{
            'redeemable': false,
            'discountPercent': item.discountPercent,
            'targetMode': item.targetMode,
            'productIds': item.products.map((p) => p.id).toList(),
          },
        };
        final path = '/campaigns/${kind(item)}';
        final response = creating
            ? await _api.post(path, data: data)
            : await _api.put('$path/${item.id.abs()}', data: data);
        replace(_parse(Map<String, dynamic>.from(response.data['data'])));
      });
  Future<void> state(CampaignModel item, bool enabled) =>
      warehouseRequest(() async {
        final response = await _api.patch(
          '/campaigns/${kind(item)}/${item.id.abs()}/state',
          data: {'enabled': enabled},
        );
        replace(_parse(Map<String, dynamic>.from(response.data['data'])));
      });
  CampaignModel _parse(Map<String, dynamic> j) {
    final voucher = j['kind'] == 'voucher';
    final id = (j['id'] as num).toInt();
    final start = DateTime.parse(j['startsAt']).toLocal(),
        end = DateTime.parse(j['endsAt']).toLocal();
    if (voucher) {
      return VoucherModel(
        id: id,
        name: j['name'],
        description: j['description'] ?? '',
        startsAt: start,
        endsAt: end,
        enabled: j['enabled'],
        imageUrl: j['imageUrl'],
        isDisplay: j['isDisplay'] == true,
        code: j['code'],
        discountType: j['discountType'] == 'PERCENT'
            ? DiscountType.percent
            : j['discountType'] == 'GIFT'
            ? DiscountType.gift
            : DiscountType.fixed,
        redeemable: j['redeemable'] ?? false,
        pointsRequired: j['pointsRequired'],
        discountValue: (j['discountValue'] as num).toInt(),
        minOrderAmount: (j['minOrderAmount'] as num?)?.toInt() ?? 0,
        maxDiscountAmount: ((j['maxDiscountAmount'] as num?)?.toInt() ?? 0) > 0
            ? (j['maxDiscountAmount'] as num).toInt()
            : null,
        usageLimit: j['usageLimit'],
        usedCount: j['usedCount'] ?? 0,
        usages: [
          for (final u in (j['usages'] as List? ?? []))
            VoucherUsageModel(
              u['orderCode'],
              u['buyer'] ?? '',
              (u['discountAmount'] as num).toInt(),
              DateTime.parse(u['usedAt']).toLocal(),
              discountType: u['discountType'] ?? 'FIXED',
              pointsRequired: u['pointsRequired'],
              status: u['paymentStatus'] ?? '',
            ),
        ],
      );
    }
    return PromotionModel(
      id: -id,
      name: j['name'],
      description: j['description'] ?? '',
      startsAt: start,
      endsAt: end,
      enabled: j['enabled'],
      imageUrl: j['imageUrl'],
      isDisplay: j['isDisplay'] == true,
      discountPercent: (j['discountPercent'] as num).toInt(),
      targetMode: j['targetMode'] ?? 'SELECTED',
      products: [
        for (final p in (j['products'] as List? ?? []))
          PromotionProductModel((p['id'] as num).toInt(), p['name']),
      ],
    );
  }
}
