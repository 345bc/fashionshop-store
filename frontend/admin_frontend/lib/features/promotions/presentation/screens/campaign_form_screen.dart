import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../../theme/app_theme.dart';
import '../../data/models/campaign_model.dart';
import '../providers/campaigns_provider.dart';
import '../../../../widgets/common/searchable_select_field.dart';
import '../../../../widgets/common/zella_toast.dart';

class CampaignFormScreen extends StatefulWidget {
  final CampaignKind kind;
  final CampaignModel? item;

  final VoidCallback onClose;

  const CampaignFormScreen({
    super.key,
    required this.kind,
    this.item,
    required this.onClose,
  });

  @override
  State<CampaignFormScreen> createState() => _CampaignFormScreenState();
}

class _CampaignFormScreenState extends State<CampaignFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _code = TextEditingController();
  final _value = TextEditingController();
  final _min = TextEditingController();
  final _cap = TextEditingController();
  final _limit = TextEditingController();
  final _points = TextEditingController();

  bool _redeemable = false;
  late DateTime _start, _end;
  bool _enabled = true;
  String? _imageUrl;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isDisplay = false;
  DiscountType _type = DiscountType.percent;
  final Set<int> _products = {};
  String? _error;
  bool _saving = false;

  int? _categoryId;

  bool get _voucher => widget.kind == CampaignKind.voucher;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name.text = item?.name ?? '';
    _description.text = item?.description ?? '';
    _start = item?.startsAt ?? DateTime.now();
    _end = item?.endsAt ?? _start.add(const Duration(days: 30));
    _enabled = item?.enabled ?? true;
    _imageUrl = item?.imageUrl;
    _isDisplay = item?.isDisplay ?? false;
    _redeemable = context.read<CampaignsProvider>().rewardScope;

    if (item is VoucherModel) {
      _redeemable = item.redeemable;
      _points.text = item.pointsRequired?.toString() ?? '';
      _code.text = item.code;
      _type = item.discountType;
      if (_type == DiscountType.gift) {
        _redeemable = true;
      }
      _value.text = '${item.discountValue}';
      _min.text = '${item.minOrderAmount}';
      _cap.text = item.maxDiscountAmount?.toString() ?? '';
      _limit.text = item.usageLimit?.toString() ?? '';
    } else {
      _value.text = item is PromotionModel ? '${item.discountPercent}' : '10';
      _min.text = '0';
      if (item is PromotionModel) {
        _products.addAll(item.products.map((p) => p.id));
      }
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _description,
      _code,
      _value,
      _min,
      _cap,
      _limit,
      _points,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!_voucher &&
        _isDisplay &&
        _imageBytes == null &&
        (_imageUrl == null || _imageUrl!.isEmpty)) {
      setState(
        () => _error = 'Vui lòng chọn ảnh hoặc video để hiển thị banner.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final p = context.read<CampaignsProvider>();
    try {
      if (_imageBytes != null) {
        final response = await ApiClient().post(
          '/campaigns/images',
          data: FormData.fromMap({
            'file': MultipartFile.fromBytes(
              _imageBytes!,
              filename: _imageName ?? 'campaign.jpg',
            ),
          }),
        );
        if (!mounted) return;
        _imageUrl = response.data['data']['url'] as String;
        _imageBytes = null;
      }

      final item = widget.item;
      final id = item?.id ?? p.nextId();
      final CampaignModel value = _voucher
          ? VoucherModel(
              id: id,
              name: _name.text.trim(),
              description: _description.text.trim(),
              startsAt: _start,
              endsAt: _end,
              enabled: _enabled,
              imageUrl: _imageUrl,
              isDisplay: _isDisplay,
              code: _code.text.trim().toUpperCase(),
              discountType: _type,
              discountValue: _type == DiscountType.gift
                  ? 0
                  : int.parse(_value.text),
              redeemable: _redeemable,
              pointsRequired: _redeemable ? int.tryParse(_points.text) : null,
              minOrderAmount: int.parse(_min.text),
              maxDiscountAmount: _type == DiscountType.percent
                  ? int.tryParse(_cap.text)
                  : null,
              usageLimit: int.tryParse(_limit.text),
              usedCount: item is VoucherModel ? item.usedCount : 0,
              usages: item is VoucherModel ? item.usages : const [],
            )
          : PromotionModel(
              id: id,
              name: _name.text.trim(),
              description: _description.text.trim(),
              startsAt: _start,
              endsAt: _end,
              enabled: _enabled,
              imageUrl: _imageUrl,
              isDisplay: _isDisplay,
              discountPercent: int.parse(_value.text),
              targetMode: 'SELECTED',
              products: p.catalog
                  .where((product) => _products.contains(product.id))
                  .toList(),
            );

      await p.save(value, creating: item == null);
      if (!mounted) return;
      ZellaToast.show(
        context,
        message: item == null
            ? 'Đã tạo ${_voucher ? 'voucher' : 'chương trình khuyến mãi'}'
            : 'Đã lưu thay đổi',
        type: ToastType.success,
      );
      widget.onClose();
    } on ArgumentError catch (e) {
      if (mounted) setState(() => _error = '${e.message}');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate(bool start) async {
    final initial = start ? _start : _end;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final result = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (start) {
        _start = result;
      } else {
        _end = result;
      }
    });
  }

  Future<void> _pickBanner() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'mp4'],
        withData: true,
      );
      if (result == null || !mounted) return;
      final file = result.files.single;
      if (file.bytes == null || file.size > 10 * 1024 * 1024) {
        setState(
          () => _error = 'Chọn tệp JPG, PNG, GIF, WebP hoặc MP4 tối đa 10 MB.',
        );
        return;
      }
      setState(() {
        _imageBytes = file.bytes;
        _imageName = file.name;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.item == null ? 'Thêm' : 'Chỉnh sửa';
    final kind = widget.kind.label.toLowerCase();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFF5364FF)),
            ),
          ),
        ),
        child: AbsorbPointer(
          absorbing: _saving,
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: EdgeInsets.all(box.maxWidth < 700 ? 16 : 28),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: _saving ? null : widget.onClose,
                          tooltip: 'Về danh sách $kind',
                          icon: const Icon(Symbols.arrow_back, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$action $kind',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildBasicInfoCard(),
                    const SizedBox(height: 24),
                    _buildDiscountCard(),
                    if (!_voucher) ...[
                      const SizedBox(height: 24),
                      _buildProductsCard(),
                    ],
                    const SizedBox(height: 24),
                    _buildScheduleCard(),
                    if (!_voucher) ...[
                      const SizedBox(height: 24),
                      _buildBannerCard(),
                    ],
                    const SizedBox(height: 24),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE4E7EC)),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(24),
        child: child,
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.text,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing],
      ],
    );
  }

  Widget _buildBasicInfoCard() {
    final used =
        widget.item is VoucherModel &&
        (widget.item as VoucherModel).usedCount > 0;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Symbols.edit_document, 'Thông tin chương trình'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: 'Tên chương trình *',
              hintText: _voucher
                  ? 'VD: Giảm 50K cho đơn từ 500K'
                  : 'VD: Siêu Sale Thời Trang Mùa Hè',
              prefixIcon: const Icon(Symbols.label, size: 20),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Vui lòng nhập tên chương trình'
                : null,
          ),
          if (_voucher) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _code,
              maxLength: 50,
              readOnly: used,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Mã voucher *',
                hintText: 'VD: SUMMER50',
                prefixIcon: const Icon(Symbols.key, size: 20),
                helperText: used
                    ? 'Mã voucher đã có lượt sử dụng, không được đổi mã.'
                    : '3–50 ký tự A–Z, 0–9, gạch dưới hoặc gạch ngang.',
              ),
              validator: (v) =>
                  RegExp(r'^[A-Z0-9_-]{3,50}$')
                      .hasMatch((v ?? '').trim().toUpperCase())
                  ? null
                  : 'Mã voucher từ 3–50 ký tự chữ hoa, số hoặc dấu gạch',
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Mô tả chi tiết',
              hintText: 'Nhập thông tin giới thiệu, điều kiện hoặc ghi chú...',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountCard() {
    if (!_voucher) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Symbols.percent, 'Mức chiết khấu'),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _value,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Tỷ lệ giảm giá (%) *',
                      hintText: 'VD: 15',
                      suffixText: '%',
                      prefixIcon: Icon(Symbols.percent, size: 20),
                    ),
                    validator: (value) {
                      final n = int.tryParse(value ?? '');
                      if (n == null || n < 1 || n > 100) {
                        return 'Nhập số phần trăm từ 1 đến 100';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Symbols.info, size: 20, color: AppTheme.info),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Giảm giá tự động trừ vào đơn giá bán lẻ của các sản phẩm áp dụng trong danh sách bên dưới.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final used =
        widget.item is VoucherModel &&
        (widget.item as VoucherModel).usedCount > 0;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Symbols.local_offer, 'Mức giảm & Điều kiện'),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Voucher đổi điểm',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Khách dùng điểm tích lũy để nhận voucher riêng, hiệu lực 30 ngày.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            value: _redeemable,
            onChanged: used || _saving
                ? null
                : (value) => setState(() {
                    _redeemable = value;
                    if (!value && _type == DiscountType.gift) {
                      _type = DiscountType.fixed;
                    }
                  }),
          ),
          if (_redeemable) ...[
            const SizedBox(height: 12),
            _number(_points, 'Điểm cần đổi *', max: 2147483647),
            const SizedBox(height: 16),
          ],
          DropdownButtonFormField<DiscountType>(
            key: ValueKey('discount_type_${_type}_$_redeemable'),
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Loại giảm giá',
              prefixIcon: Icon(Symbols.tune, size: 20),
            ),
            items: [
              for (final type in DiscountType.values.where(
                (t) => _redeemable || t != DiscountType.gift || t == _type,
              ))
                DropdownMenuItem(value: type, child: Text(type.label)),
            ],
            onChanged: (type) => setState(() => _type = type!),
          ),
          if (_type != DiscountType.gift) ...[
            const SizedBox(height: 16),
            _number(
              _value,
              _type == DiscountType.percent
                  ? 'Tỷ lệ giảm (%) *'
                  : 'Số tiền giảm (VND) *',
              max: _type == DiscountType.percent ? 100 : null,
            ),
          ],
          if (_type == DiscountType.percent) ...[
            const SizedBox(height: 16),
            _number(_cap, 'Mức giảm tối đa (VND)', optional: true),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _number(_min, 'Đơn hàng tối thiểu (VND) *', min: 0),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _number(
                  _limit,
                  'Tổng lượt dùng',
                  optional: true,
                  max: 2147483647,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _redeemable
                ? 'Giới hạn số lần đổi điểm. Mỗi mã cấp được dùng 1 lần.'
                : 'Để trống tổng lượt dùng nếu cho phép sử dụng không giới hạn.',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsCard() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(Symbols.inventory_2, 'Sản phẩm áp dụng'),
        const SizedBox(height: 16),
        _productPicker(),
      ],
    ),
  );

  Widget _productPicker() {
    final catalog = context.watch<CampaignsProvider>().catalog;
    final categories = <int, String>{
      for (final product in catalog)
        if (product.categoryId != null)
          product.categoryId!:
              product.categoryName ?? 'Danh mục ${product.categoryId}',
    };
    final entries = categories.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final visible = catalog
        .where((p) => _categoryId == null || p.categoryId == _categoryId)
        .toList();
    final allSelected =
        visible.isNotEmpty && visible.every((p) => _products.contains(p.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SearchableSelectField<int>(
                initialValue: _categoryId ?? 0,
                enabled: !_saving,
                decoration: const InputDecoration(hintText: 'Chọn danh mục'),
                items: [
                  const DropdownMenuItem(
                    value: 0,
                    child: Text('Tất cả danh mục'),
                  ),
                  for (final entry in entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: (id) {
                  if (_saving) return;
                  setState(() => _categoryId = id == 0 ? null : id);
                },
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: Icon(
                allSelected ? Symbols.deselect : Symbols.select_all,
                size: 18,
              ),
              label: Text(
                allSelected ? 'Bỏ chọn hết' : 'Chọn tất cả (${visible.length})',
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: _saving || visible.isEmpty
                  ? null
                  : () => setState(() {
                      if (allSelected) {
                        _products.removeAll(visible.map((p) => p.id));
                      } else {
                        _products.addAll(visible.map((p) => p.id));
                      }
                    }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 230,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: visible.isEmpty
              ? const Center(
                  child: Text(
                    'Không có sản phẩm nào trong danh mục này',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    indent: 48,
                    color: AppTheme.borderLight,
                  ),
                  itemBuilder: (context, index) {
                    final product = visible[index];
                    final isChecked = _products.contains(product.id);
                    return InkWell(
                      onTap: _saving
                          ? null
                          : () => setState(() {
                              if (isChecked) {
                                _products.remove(product.id);
                              } else {
                                _products.add(product.id);
                              }
                            }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isChecked,
                              onChanged: _saving
                                  ? null
                                  : (selected) => setState(() {
                                      if (selected == true) {
                                        _products.add(product.id);
                                      } else {
                                        _products.remove(product.id);
                                      }
                                    }),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: const Icon(
                                Symbols.checkroom,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isChecked
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isChecked
                                          ? AppTheme.text
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                  if (product.categoryName != null)
                                    Text(
                                      product.categoryName!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Symbols.schedule, 'Thời gian áp dụng'),
          const SizedBox(height: 16),
          _datePickerCard(
            label: 'Thời gian bắt đầu',
            date: _start,
            icon: Symbols.calendar_today,
            onTap: () => _pickDate(true),
          ),
          const SizedBox(height: 12),
          _datePickerCard(
            label: 'Thời gian kết thúc',
            date: _end,
            icon: Symbols.event,
            onTap: () => _pickDate(false),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Kích hoạt chương trình',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Chỉ có hiệu lực khi bật và đang trong thời gian áp dụng.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            value: _enabled,
            onChanged: _saving ? null : (v) => setState(() => _enabled = v),
          ),
        ],
      ),
    );
  }

  Widget _datePickerCard({
    required String label,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _saving ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Icon(icon, size: 18, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    campaignDate(date),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.text,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Symbols.edit_calendar,
              size: 18,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCard() {
    final hasBanner =
        _imageBytes != null || (_imageUrl != null && _imageUrl!.isNotEmpty);
    final isVideo = isCampaignBannerVideo(_imageName ?? _imageUrl);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Symbols.image, 'Banner hiển thị'),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Hiển thị banner trang chủ',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Hiển thị trong slider trang chủ khi chương trình đang diễn ra.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            value: _isDisplay,
            onChanged: _saving ? null : (v) => setState(() => _isDisplay = v),
          ),
          const SizedBox(height: 12),
          if (hasBanner) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    color: AppTheme.surface,
                    child: isVideo
                        ? Center(
                            child: ListTile(
                              leading: const Icon(Symbols.play_circle),
                              title: Text(_imageName ?? 'Video banner MP4'),
                            ),
                          )
                        : _imageBytes != null
                        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                        : Image.network(
                            _imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                Symbols.broken_image,
                                size: 36,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.black.withAlpha(160),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Symbols.close,
                          size: 14,
                          color: Colors.white,
                        ),
                        tooltip: 'Xóa banner',
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                _imageBytes = null;
                                _imageName = null;
                                _imageUrl = null;
                              }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            icon: const Icon(Symbols.upload_file, size: 18),
            label: Text(hasBanner ? 'Đổi banner' : 'Chọn ảnh hoặc video'),
            onPressed: _saving ? null : _pickBanner,
          ),
          const SizedBox(height: 6),
          const Text(
            'Hỗ trợ JPG, PNG, GIF, WebP và MP4 (tối đa 10 MB)',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: AppTheme.danger)),
          const SizedBox(height: 12),
        ],
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 12,
          runSpacing: 12,
          children: [
            TextButton(
              onPressed: _saving ? null : widget.onClose,
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5364FF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Symbols.save, size: 18),
              label: Text(_saving ? 'Đang lưu…' : 'Lưu'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _number(
    TextEditingController controller,
    String label, {
    bool optional = false,
    int min = 1,
    int? max,
  }) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      if (optional && (value ?? '').isEmpty) return null;
      final number = int.tryParse(value ?? '');
      if (number == null || number < min || (max != null && number > max)) {
        return 'Nhập số nguyên từ $min${max != null ? ' đến $max' : ' trở lên'}';
      }
      return null;
    },
  );
}
