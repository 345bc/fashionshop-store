import 'package:flutter/foundation.dart';

import '../../data/models/campaign_model.dart';
import '../../data/repositories/campaign_repository.dart';

class CampaignsProvider extends ChangeNotifier {
  CampaignsProvider({
    CampaignRepository? repository,
    DateTime Function()? clock,
  }) : _repository = repository ?? CampaignRepository(),
       _clock = clock ?? DateTime.now;
  final CampaignRepository _repository;
  bool loading = false;
  String? error;
  List<PromotionProductModel> get catalog => _repository.catalog;
  Future<void> load() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _repository.load();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> loadDetail(int id) async {
    await _repository.detail(detail(id));
    notifyListeners();
  }

  final DateTime Function() _clock;
  String query = '';
  CampaignStatus? filter;
  bool rewardScope = false;
  void setRewardScope(bool value) {
    rewardScope = value;
    currentPage = 0;
    notifyListeners();
  }

  int currentPage = 0;
  final int pageSize = 10;
  List<CampaignModel> items(CampaignKind kind) => _repository.items
      .where(
        (r) =>
            r.kind == kind &&
            (r is! PromotionModel || r.targetMode == 'SELECTED'),
      )
      .toList();
  CampaignStatus status(CampaignModel item) => item.statusAt(_clock());
  List<CampaignModel> filtered(CampaignKind kind) => items(kind)
      .where(
        (r) =>
            (r is! VoucherModel || r.redeemable == rewardScope) &&
            (filter == null || status(r) == filter) &&
            '${r.name} ${r.description} ${r is VoucherModel ? r.code : ''}'
                .toLowerCase()
                .contains(query.trim().toLowerCase()),
      )
      .toList();
  List<CampaignModel> pageItems(CampaignKind kind) =>
      filtered(kind).skip(currentPage * pageSize).take(pageSize).toList();
  CampaignModel detail(int id) =>
      _repository.items.firstWhere((r) => r.id == id);
  void resetFilters() {
    query = '';
    filter = null;
    currentPage = 0;
  }

  void setQuery(String value) {
    query = value;
    currentPage = 0;
    notifyListeners();
  }

  void setFilter(CampaignStatus? value) {
    filter = value;
    currentPage = 0;
    notifyListeners();
  }

  void setPage(CampaignKind kind, int page) {
    currentPage = page.clamp(
      0,
      ((filtered(kind).length - 1) ~/ pageSize).clamp(0, 999999),
    );
    notifyListeners();
  }

  int nextId() => _repository.nextId();
  Future<void> save(CampaignModel item, {bool creating = false}) async {
    if (item.name.trim().isEmpty ||
        item.name.length > 200 ||
        item.description.length > 500) {
      throw ArgumentError('Tên tối đa 200 ký tự, mô tả tối đa 500 ký tự.');
    }
    if (!item.endsAt.isAfter(item.startsAt)) {
      throw ArgumentError('Thời gian kết thúc phải sau thời gian bắt đầu.');
    }
    if (item is VoucherModel) {
      if (!RegExp(r'^[A-Z0-9_-]{3,50}$').hasMatch(item.code)) {
        throw ArgumentError('Mã voucher cần 3–50 ký tự A–Z, 0–9, _ hoặc -.');
      }
      if (!creating) {
        final original = detail(item.id) as VoucherModel;
        if (original.usedCount > 0 && original.code != item.code) {
          throw ArgumentError('Voucher đã sử dụng không được đổi mã.');
        }
      }
      if (items(CampaignKind.voucher)
          .cast<VoucherModel>()
          .any((v) => v.id != item.id && v.code.toUpperCase() == item.code)) {
        throw ArgumentError('Mã voucher đã tồn tại.');
      }
      if ((item.discountType != DiscountType.gift && item.discountValue <= 0) ||
          (item.discountType == DiscountType.percent &&
              item.discountValue > 100) ||
          item.minOrderAmount < 0 ||
          (item.maxDiscountAmount != null && item.maxDiscountAmount! <= 0) ||
          (item.usageLimit != null &&
              (item.usageLimit! <= 0 || item.usageLimit! < item.usedCount))) {
        throw ArgumentError(
          'Giá trị giảm hoặc giới hạn lượt sử dụng không hợp lệ.',
        );
      }
      if (item.redeemable &&
          (item.pointsRequired == null || item.pointsRequired! <= 0)) {
        throw ArgumentError('Điểm cần đổi phải là số nguyên dương.');
      }
    }
    if (item is PromotionModel && item.targetMode != 'SELECTED') {
      throw ArgumentError(
        'Ưu đãi sản phẩm mới được áp dụng tự động, không quản lý tại đây.',
      );
    }
    if (item is PromotionModel &&
        (item.discountPercent < 1 ||
            item.discountPercent > 100 ||
            (item.targetMode == 'SELECTED' && item.products.isEmpty))) {
      throw ArgumentError(
        'Khuyến mãi cần giảm 1–100% và chọn ít nhất một sản phẩm.',
      );
    }
    await _repository.save(item, creating: creating);
    setPage(item.kind, currentPage);
  }

  Future<void> toggle(int id) async {
    final item = detail(id);
    await _repository.state(item, !item.enabled);
    notifyListeners();
  }

  Future<void> toggleActiveBulk(List<int> ids, bool active) async {
    try {
      for (final id in ids) {
        await _repository.state(detail(id), active);
      }
    } finally {
      notifyListeners();
    }
  }

  void refreshStatuses() => notifyListeners();
}
