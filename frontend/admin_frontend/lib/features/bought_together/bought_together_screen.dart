import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/network/api_client.dart';
import '../../theme/app_theme.dart';

class BoughtTogetherScreen extends StatefulWidget {
  const BoughtTogetherScreen({super.key});

  @override
  State<BoughtTogetherScreen> createState() => _BoughtTogetherScreenState();
}

class _BoughtTogetherScreenState extends State<BoughtTogetherScreen> {
  final _api = ApiClient();
  final _form = GlobalKey<FormState>();
  final _days = TextEditingController();
  final _support = TextEditingController();
  final _confidence = TextEditingController();
  final _lift = TextEditingController();
  final _limit = TextEditingController();
  final _productId = TextEditingController();
  bool _busy = false, _enabled = true;
  Map<String, dynamic>? _status, _preview;
  String? _error;
  Map<String, dynamic>? _itemsets, _rules;
  bool _showRules = false;
  int _miningPage = 0, _level = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _days,
      _support,
      _confidence,
      _lift,
      _limit,
      _productId,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _numberText(num value) =>
      value.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');

  void _setStatus(Map<String, dynamic> status, {bool fill = false}) {
    _status = status;
    if (!fill) return;
    final settings = status['settings'] as Map<String, dynamic>;
    _days.text = '${settings['windowDays']}';
    _support.text = _numberText((settings['minSupport'] as num) * 100);
    _confidence.text = _numberText((settings['minConfidence'] as num) * 100);
    _lift.text = _numberText(settings['minLift'] as num);
    _limit.text = '${settings['maxRecommendations']}';
    _enabled = settings['enabled'] == true;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _load() => _run(() async {
    final response = await _api.get('/admin/bought-together/status');
    if (mounted) {
      setState(
        () => _setStatus(
          Map<String, dynamic>.from(response.data['data']),
          fill: true,
        ),
      );
    }
    await _loadMining();
  });

  double _fraction(TextEditingController controller) =>
      double.parse((double.parse(controller.text) / 100).toStringAsFixed(6));

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    await _run(() async {
      await _api.put(
        '/admin/bought-together/settings',
        data: {
          'windowDays': int.parse(_days.text),
          'minSupport': _fraction(_support),
          'minConfidence': _fraction(_confidence),
          'minLift': double.parse(_lift.text),
          'maxRecommendations': int.parse(_limit.text),
          'enabled': _enabled,
        },
      );
      if (!mounted) return;
      setState(() => _preview = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu cấu hình vào database')),
      );
      final response = await _api.get('/admin/bought-together/status');
      if (mounted) {
        setState(
          () => _setStatus(
            Map<String, dynamic>.from(response.data['data']),
            fill: true,
          ),
        );
      }
      await _loadMining();
    });
  }

  Future<void> _rebuild() => _run(() async {
    final response = await _api.post('/admin/bought-together/rebuild');
    if (mounted) {
      setState(() {
        _setStatus(Map<String, dynamic>.from(response.data['data']));
        _preview = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tính lại mô hình theo cấu hình đã lưu'),
        ),
      );
    }
    await _loadMining();
  });

  Future<void> _check() async {
    final ids = _productId.text
        .split(',')
        .map((value) => int.tryParse(value.trim()))
        .toList();
    if (ids.isEmpty ||
        ids.length > 50 ||
        ids.any((id) => id == null || id <= 0)) {
      setState(
        () => _error = 'Nhập từ 1 đến 50 mã sản phẩm nguyên dương, cách nhau bằng dấu phẩy.',
      );
      return;
    }
    await _run(() async {
      final response = await _api.get(
        '/admin/bought-together/preview',
        queryParameters: {'productIds': ids.join(',')},
      );
      if (mounted) {
        setState(
          () => _preview = Map<String, dynamic>.from(response.data['data']),
        );
      }
    });
  }

  Widget _field(
    TextEditingController controller,
    String label,
    double min,
    double max, {
    bool integer = false,
    int decimals = 4,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      controller: controller,
      enabled: !_busy,
      keyboardType: TextInputType.numberWithOptions(decimal: !integer),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          integer ? RegExp(r'[0-9]') : RegExp(r'[0-9.]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final text = value ?? '';
        final number = double.tryParse(text);
        if (number == null ||
            !number.isFinite ||
            number < min ||
            number > max ||
            (integer && int.tryParse(text) == null)) {
          return 'Nhập ${integer ? 'số nguyên' : 'số'} từ $min đến $max';
        }
        if (!integer &&
            text.contains('.') &&
            text.split('.').last.length > decimals) {
          return 'Tối đa $decimals chữ số thập phân';
        }
        return null;
      },
    ),
  );

  Widget _card(String title, List<Widget> children) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppTheme.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    ),
  );

  String _time(dynamic value) {
    final date = DateTime.tryParse('$value')?.toLocal();
    if (date == null) return '—';
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _model() => _card('Trạng thái mô hình', [
    Text('Tính lúc: ${_time(_status!['computedAt'])}'),
    const SizedBox(height: 10),
    Text(
      'Khoảng xét: ${_time(_status!['windowFrom'])} – ${_time(_status!['windowTo'])}',
    ),
    const SizedBox(height: 10),
    Text(
      'Đơn hợp lệ: ${_status!['totalTransactions']} • Sản phẩm: ${_status!['totalProducts']}',
    ),
    const SizedBox(height: 10),
    Text(
      'Tập phổ biến: ${_status!['frequentItemsets']} • Cấp lớn nhất: ${_status!['maximumItemsetSize']} • Luật đạt minconf: ${_status!['totalRules']} • Ngưỡng minsup: ${_status!['minimumCount']} đơn',
    ),
    const SizedBox(height: 16),
    OutlinedButton.icon(
      onPressed: _busy ? null : _rebuild,
      icon: const Icon(Icons.refresh),
      label: const Text('Tính lại mô hình'),
    ),
  ]);

  Widget _configuration() => _card('Cấu hình FP-Growth', [
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Hiển thị gợi ý trên trang chi tiết'),
      value: _enabled,
      onChanged: _busy ? null : (value) => setState(() => _enabled = value),
    ),
    const SizedBox(height: 16),
    _field(_days, 'Khoảng thời gian xác định', 1, 365, integer: true),
    _field(_support, 'Minsup (%)', 0.0001, 100),
    _field(_confidence, 'Minconf (%)', 0, 100),
    _field(_lift, 'lift', 0, 100),
    _field(_limit, 'lượt hiển thị', 1, 24, integer: true),
    const SizedBox(height: 16),
    FilledButton.icon(
      onPressed: _busy ? null : _save,
      icon: const Icon(Icons.check),
      label: const Text('Lưu cấu hình'),
    ),
  ]);

  Widget _inspection() {
    final items = (_preview?['result']?['products'] as List?) ?? [];
    return _card('Kiểm tra gợi ý theo sản phẩm', [
      TextField(
        controller: _productId,
        enabled: !_busy,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9, ]')),
        ],
        decoration: const InputDecoration(
          labelText: 'Mã sản phẩm ',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() => _preview = null),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: _busy ? null : _check,
        child: const Text('Kiểm tra theo cấu hình đã lưu'),
      ),
      if (_preview != null) ...[
        const SizedBox(height: 16),
        Text(
          'Sản phẩm đang xét: ${_previewItems(_preview!["contextProductIds"])}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          '${_preview!['message']}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          'Đơn chứa tập đang xét (đã đạt minsup): ${_preview!['sourceTransactions']} • Tập mở rộng phổ biến: ${_preview!['frequentItemsets']} • Luật gợi ý phù hợp: ${_preview!['qualifyingRules']}',
        ),
        if (items.isNotEmpty)
          _wideTable(
            DataTable(
              columns: const [
                DataColumn(label: Text('Sản phẩm mua kèm')),
                DataColumn(label: Text('Luật sử dụng')),
                DataColumn(label: Text('Mua chung')),
                DataColumn(label: Text('Support')),
                DataColumn(label: Text('Confidence')),
                DataColumn(label: Text('Lift')),
              ],
              rows: items
                  .map(
                    (item) => DataRow(
                      cells: [
                        DataCell(
                          Text(
                            '#${item['product']['id']} · ${item['product']['name']}',
                          ),
                        ),
                        DataCell(
                          Text(
                            '${_previewItems(item['antecedent'])} → ${_previewItems(item['consequent'])}',
                          ),
                        ),
                        DataCell(Text('${item['transactions']} đơn')),
                        DataCell(
                          Text(
                            '${((item['support'] as num) * 100).toStringAsFixed(2)}%',
                          ),
                        ),
                        DataCell(
                          Text(
                            '${((item['confidence'] as num) * 100).toStringAsFixed(2)}%',
                          ),
                        ),
                        DataCell(
                          Text((item['lift'] as num).toStringAsFixed(3)),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    ]);
  }

  String _previewItems(dynamic items) {
    final names = _preview?['productNames'] as Map? ?? {};
    return (items as List? ?? [])
        .map((id) {
          final name = names['$id'];
          return name is String && name.isNotEmpty
              ? '$name (#$id)'
              : '#$id (không tìm thấy tên)';
        })
        .join(', ');
  }

  Widget _wideTable(Widget table) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: constraints.maxWidth),
        child: table,
      ),
    ),
  );

  String _items(dynamic items) =>
      '{${(items as List? ?? []).map((id) => '#$id').join(', ')}}';

  Future<void> _loadMining({int page = 0, int? level}) async {
    final selectedLevel = level ?? _level;
    final responses = await Future.wait([
      _api.get(
        '/admin/bought-together/itemsets',
        queryParameters: {'page': page, 'size': 10, 'level': selectedLevel},
      ),
      _api.get(
        '/admin/bought-together/rules',
        queryParameters: {'page': page, 'size': 10},
      ),
    ]);
    if (!mounted) return;
    setState(() {
      _miningPage = page;
      _level = selectedLevel;
      _itemsets = Map<String, dynamic>.from(responses[0].data['data']);
      _rules = Map<String, dynamic>.from(responses[1].data['data']);
    });
  }

  Widget _mining() {
    final data = _showRules ? _rules : _itemsets;
    final rows = data?['content'] as List? ?? [];
    final totalPages = data?['totalPages'] as int? ?? 0;
    final maximumLevel = _status?['maximumItemsetSize'] as int? ?? 0;
    return _card('Kết quả khai phá luật kết hợp', [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ChoiceChip(
            label: const Text('Tập phổ biến (1–n)'),
            selected: !_showRules,
            onSelected: _busy
                ? null
                : (_) => _run(() async {
                    setState(() => _showRules = false);
                    await _loadMining();
                  }),
          ),
          ChoiceChip(
            label: const Text('Luật X → Y'),
            selected: _showRules,
            onSelected: _busy
                ? null
                : (_) => _run(() async {
                    setState(() => _showRules = true);
                    await _loadMining();
                  }),
          ),
          if (!_showRules)
            DropdownButton<int>(
              value: _level <= maximumLevel ? _level : 0,
              items: [
                const DropdownMenuItem(value: 0, child: Text('Tất cả cấp')),
                for (int i = 1; i <= maximumLevel; i++)
                  DropdownMenuItem(value: i, child: Text('Cấp $i')),
              ],
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value != null) _run(() => _loadMining(level: value));
                    },
            ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        _showRules
            ? 'Các luật thỏa minsup và minconf. Bộ lọc lift chỉ áp dụng khi chọn gợi ý; X có đúng 1 sản phẩm, Y có thể có nhiều sản phẩm và không giao với X.'
            : 'Tập có support ≥ minsup. Cấp là số sản phẩm trong tập. Tập cấp 1 không sinh luật.',
      ),
      const SizedBox(height: 12),
      if (rows.isEmpty)
        const Text('Chưa có kết quả phù hợp với cấu hình đã lưu.'),
      if (rows.isNotEmpty)
        _wideTable(
          DataTable(
            columns: _showRules
                ? const [
                    DataColumn(label: Text('Vế trái X')),
                    DataColumn(label: Text('Vế phải Y')),
                    DataColumn(label: Text('Số đơn')),
                    DataColumn(label: Text('Support')),
                    DataColumn(label: Text('Confidence')),
                    DataColumn(label: Text('Lift')),
                  ]
                : const [
                    DataColumn(label: Text('Tập sản phẩm (ID)')),
                    DataColumn(label: Text('Cấp')),
                    DataColumn(label: Text('Số đơn')),
                    DataColumn(label: Text('Support')),
                  ],
            rows: rows
                .map(
                  (row) => DataRow(
                    cells: _showRules
                        ? [
                            DataCell(Text(_items(row['antecedent']))),
                            DataCell(Text(_items(row['consequent']))),
                            DataCell(Text('${row['count']}')),
                            DataCell(
                              Text(
                                '${((row['support'] as num) * 100).toStringAsFixed(2)}%',
                              ),
                            ),
                            DataCell(
                              Text(
                                '${((row['confidence'] as num) * 100).toStringAsFixed(2)}%',
                              ),
                            ),
                            DataCell(
                              Text((row['lift'] as num).toStringAsFixed(3)),
                            ),
                          ]
                        : [
                            DataCell(Text(_items(row['items']))),
                            DataCell(Text('${(row['items'] as List).length}')),
                            DataCell(Text('${row['count']}')),
                            DataCell(
                              Text(
                                '${((row['support'] as num) * 100).toStringAsFixed(2)}%',
                              ),
                            ),
                          ],
                  ),
                )
                .toList(),
          ),
        ),
      Wrap(
        spacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Tổng: ${data?['totalElements'] ?? 0} • Trang ${totalPages == 0 ? 0 : _miningPage + 1}/$totalPages',
          ),
          TextButton(
            onPressed: _busy || _miningPage == 0
                ? null
                : () => _run(() => _loadMining(page: _miningPage - 1)),
            child: const Text('Trước'),
          ),
          TextButton(
            onPressed: _busy || _miningPage + 1 >= totalPages
                ? null
                : () => _run(() => _loadMining(page: _miningPage + 1)),
            child: const Text('Sau'),
          ),
        ],
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.surface,
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Gợi ý mua kèm',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Quản lý FP-Growth và kiểm tra điều kiện hiển thị sản phẩm mua kèm.',
          ),
          const SizedBox(height: 24),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _error!,
                style: const TextStyle(color: AppTheme.error),
              ),
            ),
          if (_status == null && !_busy)
            TextButton(onPressed: _load, child: const Text('Thử tải lại')),
          if (_status != null) ...[
            Form(
              key: _form,
              child: LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth > 1050
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _configuration()),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                _model(),
                                const SizedBox(height: 24),
                                _inspection(),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _configuration(),
                          const SizedBox(height: 24),
                          _model(),
                          const SizedBox(height: 24),
                          _inspection(),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            _mining(),
          ],
        ],
      ),
    ),
  );
}
