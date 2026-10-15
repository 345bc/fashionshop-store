import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_client.dart';
import '../../../../widgets/common/feature_header.dart';
import '../../../../widgets/common/feature_toolbar.dart';
import '../../../../widgets/common/filter_dropdown.dart';
import '../dialogs/staff_edit_dialog.dart';

const staffStatuses = {
  'true': 'Đang làm việc',
  'false': 'Ngừng làm việc',
};

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});
  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<Map<String, dynamic>> _items = [];
  String _query = '', _status = '';
  int _page = 0, _pages = 0, _total = 0, _request = 0;
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiClient().get(
        '/staff',
        queryParameters: {
          'q': _query,
          'page': _page,
          'size': 15,
          'sort': 'id,desc',
          if (_status.isNotEmpty) 'active': _status,
        },
      );
      if (!mounted || request != _request) return;
      final data = response.data['data'];
      setState(() {
        _items = List<Map<String, dynamic>>.from(data['content']);
        _pages = data['totalPages'];
        _total = data['totalElements'];
      });
    } catch (e) {
      if (mounted && request == _request) setState(() => _error = '$e');
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _edit([Map<String, dynamic>? staff]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StaffEditDialog(staff: staff),
    );
    if (saved == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FeatureHeader(
            title: 'Quản lý nhân sự',
            subtitle: 'Hồ sơ và thông tin liên hệ của nhân sự',
            actionLabel: 'Thêm nhân sự',
            actionIcon: Symbols.person_add,
            onActionPressed: () => _edit(),
          ),
          const SizedBox(height: 24),
          FeatureToolbar(
            searchHint: 'Tìm theo tên, email',
            initialSearchText: _query,
            onSearchChanged: (query) {
              _query = query;
              _page = 0;
              _load();
            },
            filterWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilterDropdown<String>(
                  label: 'Trạng thái',
                  searchHint: 'Tìm trạng thái',
                  value: _status,
                  defaultValue: '',
                  options: staffStatuses.entries
                      .map((e) => FilterOption(value: e.key, label: e.value))
                      .toList(),
                  onChanged: (status) {
                    _status = status;
                    _page = 0;
                    _load();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const LinearProgressIndicator(minHeight: 2)
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('Thử lại')),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Chưa có nhân sự phù hợp')),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: DataTable(
                            columnSpacing: 24,
                            headingRowHeight: 42,
                            dataRowMinHeight: 58,
                            dataRowMaxHeight: 68,
                            columns: const [
                              DataColumn(label: Text('Tên')),
                              DataColumn(label: Text('Liên hệ')),
                              DataColumn(label: Text('Chức vụ')),
                              DataColumn(label: Text('SĐT')),
                              DataColumn(label: Text('')),
                            ],
                            rows: [
                              for (final s in _items)
                                DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        s['fullName'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(s['email'] ?? '—')),
                                    DataCell(
                                      Text(
                                        (s['position']
                                                    ?.toString()
                                                    .trim()
                                                    .isEmpty ??
                                                true)
                                            ? '—'
                                            : s['position'],
                                      ),
                                    ),
                                    DataCell(Text(s['phone'] ?? '—')),
                                    DataCell(
                                      IconButton(
                                        tooltip: 'Sửa hồ sơ',
                                        onPressed: () => _edit(s),
                                        icon: const Icon(
                                          Symbols.edit,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$_total nhân sự • Trang ${_pages == 0 ? 0 : _page + 1}/$_pages',
                          ),
                        ),
                        IconButton(
                          onPressed: _page > 0
                              ? () {
                                  _page--;
                                  _load();
                                }
                              : null,
                          icon: const Icon(Symbols.chevron_left),
                        ),
                        IconButton(
                          onPressed: _page + 1 < _pages
                              ? () {
                                  _page++;
                                  _load();
                                }
                              : null,
                          icon: const Icon(Symbols.chevron_right),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
