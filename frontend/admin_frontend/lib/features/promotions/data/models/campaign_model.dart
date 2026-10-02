import 'package:intl/intl.dart';

enum CampaignKind {
  voucher('Voucher'),
  promotion('Khuyến mãi');

  const CampaignKind(this.label);
  final String label;
}

enum CampaignStatus {
  scheduled('Sắp diễn ra'),
  active('Đang diễn ra'),
  paused('Đã tắt'),
  expired('Đã hết hạn'),
  exhausted('Hết lượt');

  const CampaignStatus(this.label);
  final String label;
}

enum DiscountType {
  percent('Phần trăm'),
  fixed('Số tiền');

  const DiscountType(this.label);
  final String label;
}

String money(int value) =>
    '${NumberFormat.decimalPattern('vi').format(value)} đ';
String campaignDate(DateTime value) =>
    DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());

class CampaignHistoryModel {
  final String action, note;
  final DateTime createdAt;
  const CampaignHistoryModel(this.action, this.note, this.createdAt);
}

abstract class CampaignModel {
  final int id;
  final String name, description;
  final DateTime startsAt, endsAt;
  final bool enabled;
  final List<CampaignHistoryModel> history;
  const CampaignModel({
    required this.id,
    required this.name,
    required this.description,
    required this.startsAt,
    required this.endsAt,
    required this.enabled,
    this.history = const [],
  });
  CampaignKind get kind;
  String get discountLabel;
  CampaignStatus statusAt(DateTime now) {
    if (!now.isBefore(endsAt)) return CampaignStatus.expired;
    if (!enabled) return CampaignStatus.paused;
    if (now.isBefore(startsAt)) return CampaignStatus.scheduled;
    return CampaignStatus.active;
  }

  CampaignModel withState(bool enabled, List<CampaignHistoryModel> history);
}

class VoucherUsageModel {
  final String orderCode, buyer;
  final int discountAmount;
  final DateTime usedAt;
  const VoucherUsageModel(
    this.orderCode,
    this.buyer,
    this.discountAmount,
    this.usedAt,
  );
}

class VoucherModel extends CampaignModel {
  final String code;
  final DiscountType discountType;
  final int discountValue, minOrderAmount, usedCount;
  final int? maxDiscountAmount, usageLimit;
  final List<VoucherUsageModel> usages;
  const VoucherModel({
    required super.id,
    required super.name,
    required super.description,
    required super.startsAt,
    required super.endsAt,
    required super.enabled,
    super.history,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount = 0,
    this.maxDiscountAmount,
    this.usageLimit,
    this.usedCount = 0,
    this.usages = const [],
  });
  @override
  CampaignKind get kind => CampaignKind.voucher;
  @override
  String get discountLabel => discountType == DiscountType.percent
      ? '$discountValue%'
      : money(discountValue);
  @override
  CampaignStatus statusAt(DateTime now) {
    final state = super.statusAt(now);
    return state == CampaignStatus.active &&
            usageLimit != null &&
            usedCount >= usageLimit!
        ? CampaignStatus.exhausted
        : state;
  }

  @override
  VoucherModel withState(bool enabled, List<CampaignHistoryModel> history) =>
      VoucherModel(
        id: id,
        name: name,
        description: description,
        startsAt: startsAt,
        endsAt: endsAt,
        enabled: enabled,
        history: history,
        code: code,
        discountType: discountType,
        discountValue: discountValue,
        minOrderAmount: minOrderAmount,
        maxDiscountAmount: maxDiscountAmount,
        usageLimit: usageLimit,
        usedCount: usedCount,
        usages: usages,
      );
}

class PromotionProductModel {
  final int id;
  final String name;
  const PromotionProductModel(this.id, this.name);
}

class PromotionModel extends CampaignModel {
  final int discountPercent;
  final List<PromotionProductModel> products;
  const PromotionModel({
    required super.id,
    required super.name,
    required super.description,
    required super.startsAt,
    required super.endsAt,
    required super.enabled,
    super.history,
    required this.discountPercent,
    required this.products,
  });
  @override
  CampaignKind get kind => CampaignKind.promotion;
  @override
  String get discountLabel => '$discountPercent%';
  @override
  PromotionModel withState(bool enabled, List<CampaignHistoryModel> history) =>
      PromotionModel(
        id: id,
        name: name,
        description: description,
        startsAt: startsAt,
        endsAt: endsAt,
        enabled: enabled,
        history: history,
        discountPercent: discountPercent,
        products: products,
      );
}
