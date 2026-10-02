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
  final DateTime Function() _clock;
  String query = '';
  CampaignStatus? filter;
  int currentPage = 0;
  final int pageSize = 10;
  List<CampaignModel> items(CampaignKind kind) =>
      _repository.items.where((r) => r.kind == kind).toList();
  CampaignStatus status(CampaignModel item) => item.statusAt(_clock());
  List<CampaignModel> filtered(CampaignKind kind) => items(kind)
      .where(
        (r) =>
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
  void save(CampaignModel item, {bool creating = false}) {
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
      if (item.discountValue <= 0 ||
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
    }
    if (item is PromotionModel &&
        (item.discountPercent < 1 ||
            item.discountPercent > 100 ||
            item.products.isEmpty)) {
      throw ArgumentError(
        'Khuyến mãi cần giảm 1–100% và chọn ít nhất một sản phẩm.',
      );
    }
    final existingHistory = creating
        ? <CampaignHistoryModel>[]
        : detail(item.id).history;
    _repository.save(
      item.withState(item.enabled, [
        ...existingHistory,
        CampaignHistoryModel(
          creating ? 'Tạo chương trình' : 'Cập nhật chương trình',
          '${item.name} • ${item.discountLabel} • CSKH (mẫu)',
          _clock(),
        ),
      ]),
    );
    setPage(item.kind, currentPage);
  }

  void toggle(int id, String reason) {
    if (reason.trim().isEmpty || reason.length > 500) {
      throw ArgumentError('Cần lý do từ 1–500 ký tự.');
    }
    final item = detail(id);
    _repository.save(
      item.withState(!item.enabled, [
        ...item.history,
        CampaignHistoryModel(
          item.enabled ? 'Tắt chương trình' : 'Bật chương trình',
          '${reason.trim()} • CSKH (mẫu)',
          _clock(),
        ),
      ]),
    );
    setPage(item.kind, currentPage);
  }

  void refreshStatuses() => notifyListeners();
}
