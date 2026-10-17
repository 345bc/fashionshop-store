import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/network/api_client.dart';
import '../../theme/app_theme.dart';

class FeaturedProductSettingsScreen extends StatefulWidget {
  const FeaturedProductSettingsScreen({super.key});
  @override
  State<FeaturedProductSettingsScreen> createState() =>
      _FeaturedProductSettingsScreenState();
}

class _FeaturedProductSettingsScreenState
    extends State<FeaturedProductSettingsScreen> {
  final _api = ApiClient();
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _description = TextEditingController();
  final _days = TextEditingController(),
      _purchase = TextEditingController(),
      _review = TextEditingController();
  bool _loading = true, _saving = false, _loaded = false, _display = true;
  String? _error;
  int get _totalWeight =>
      (int.tryParse(_purchase.text) ?? 0) + (int.tryParse(_review.text) ?? 0);
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _days, _purchase, _review]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.get('/admin/home/featured-products');
      if (!mounted) return;
      final data = response.data['data'];
      setState(() {
        _title.text = data['title'] ?? '';
        _description.text = data['description'] ?? '';
        _days.text = '${data['windowDays']}';
        _purchase.text = '${data['purchaseWeight']}';
        _review.text = '${data['reviewWeight']}';
        _display = data['isDisplay'] == true;
        _loaded = true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_loaded || !_form.currentState!.validate()) return;
    if (_totalWeight != 100) {
      setState(() => _error = 'Tổng hai tỷ trọng phải bằng 100%.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.put(
        '/admin/home/featured-products',
        data: {
          'title': _title.text.trim(),
          'description': _description.text.trim(),
          'windowDays': int.parse(_days.text),
          'purchaseWeight': int.parse(_purchase.text),
          'reviewWeight': int.parse(_review.text),
          'isDisplay': _display,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu cấu hình sản phẩm nổi bật')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _input(String title, {String? suffix}) => InputDecoration(
    labelText: title,
    suffixText: suffix,
    border: const OutlineInputBorder(),
    alignLabelWithHint: true,
  );
  Widget _card(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    ),
  );
  Widget _number(
    TextEditingController controller,
    String label,
    int min,
    int max,
    String suffix,
  ) => TextFormField(
    controller: controller,
    enabled: !_saving,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(3),
    ],
    decoration: _input(label, suffix: suffix),
    onChanged: (_) => setState(() {}),
    validator: (v) {
      final n = int.tryParse(v ?? '');
      return n == null || n < min || n > max
          ? 'Nhập số từ $min đến $max'
          : null;
    },
  );
  Widget _content() => _card('Nội dung hiển thị', [
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Hiển thị trên trang chủ'),
      subtitle: const Text('Tự ẩn nếu không có sản phẩm đủ điều kiện.'),
      value: _display,
      onChanged: _saving ? null : (v) => setState(() => _display = v),
    ),
    const SizedBox(height: 24),
    TextFormField(
      controller: _title,
      enabled: !_saving,
      maxLength: 200,
      minLines: 1,
      maxLines: 3,
      decoration: _input('Tiêu đề *'),
      onChanged: (_) => setState(() {}),
      validator: (v) =>
          (v ?? '').trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
    ),
    const SizedBox(height: 16),
    TextFormField(
      controller: _description,
      enabled: !_saving,
      maxLength: 500,
      minLines: 4,
      maxLines: 6,
      decoration: _input('Mô tả'),
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: 20),
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'XEM TRƯỚC TIÊU ĐỀ',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _title.text.isEmpty ? 'Sản phẩm nổi bật' : _title.text,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Text(
            _description.text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    ),
  ]);
  Widget _ranking() => _card('Cách chọn sản phẩm', [
    _number(_days, 'Khoảng thời gian xét', 1, 365, 'ngày'),
    const SizedBox(height: 10),
    const Text(
      'Tính các đơn đã giao thành công trong số ngày gần nhất. Đánh giá dùng toàn bộ lịch sử công khai.',
      style: TextStyle(
        fontSize: 12,
        height: 1.6,
        color: AppTheme.textSecondary,
      ),
    ),
    const SizedBox(height: 28),
    const Text(
      'Tỷ trọng xếp hạng',
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 16),
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _number(_purchase, 'Mua hàng', 0, 100, '%')),
        const SizedBox(width: 16),
        Expanded(child: _number(_review, 'Đánh giá', 0, 100, '%')),
      ],
    ),
    const SizedBox(height: 14),
    Text(
      'Tổng tỷ trọng: $_totalWeight / 100%',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _totalWeight == 100 ? AppTheme.success : AppTheme.error,
      ),
    ),
    const SizedBox(height: 20),
    const Text(
      'Tăng tỷ trọng mua hàng để ưu tiên sản phẩm được mua phổ biến. Tăng tỷ trọng đánh giá để ưu tiên phản hồi tốt, có điều chỉnh theo số lượt đánh giá.',
      style: TextStyle(
        fontSize: 13,
        height: 1.7,
        color: AppTheme.textSecondary,
      ),
    ),
    const SizedBox(height: 20),
    const Text(
      'Thay đổi cách tính sẽ áp dụng ở lần tải trang tiếp theo. Không cần chọn sản phẩm thủ công.',
      style: TextStyle(
        fontSize: 12,
        height: 1.6,
        color: AppTheme.textSecondary,
      ),
    ),
  ]);
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      backgroundColor: AppTheme.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_loaded
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error ?? 'Không tải được cấu hình'),
                  TextButton(onPressed: _load, child: const Text('Thử lại')),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 20,
                    runSpacing: 16,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sản phẩm nổi bật',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Nội dung hiển thị và cấu hình xếp hạng tự động',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(_saving ? 'Đang lưu…' : 'Lưu thay đổi'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFFFFF1F0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.error),
                      ),
                    ),
                  Form(
                    key: _form,
                    child: LayoutBuilder(
                      builder: (context, c) => c.maxWidth > 1050
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _content()),
                                const SizedBox(width: 24),
                                Expanded(child: _ranking()),
                              ],
                            )
                          : Column(
                              children: [
                                _content(),
                                const SizedBox(height: 24),
                                _ranking(),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
    ),
  );
}
