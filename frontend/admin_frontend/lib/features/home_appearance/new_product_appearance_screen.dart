import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../theme/app_theme.dart';

class NewProductAppearanceScreen extends StatefulWidget {
  const NewProductAppearanceScreen({super.key});
  @override
  State<NewProductAppearanceScreen> createState() =>
      _NewProductAppearanceScreenState();
}

class _NewProductAppearanceScreenState
    extends State<NewProductAppearanceScreen> {
  final _api = ApiClient();
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String? _imageUrl, _fileName, _error;
  Uint8List? _imageBytes;
  bool _display = true, _loading = true, _saving = false, _hasData = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.get('/admin/home/new-products');
      if (!mounted) return;
      final data = response.data['data'];
      setState(() {
        _hasData = true;
        _title.text = data['title'] ?? '';
        _description.text = data['description'] ?? '';
        _imageUrl = data['imageUrl'];
        _display = data['isDisplay'] == true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
        withData: true,
      );
      if (!mounted || result == null) return;
      final file = result.files.single;
      if (file.bytes == null ||
          file.bytes!.isEmpty ||
          file.size > 10 * 1024 * 1024) {
        setState(
          () => _error = 'Chọn ảnh JPG, PNG, GIF hoặc WebP tối đa 10 MB.',
        );
        return;
      }
      setState(() {
        _imageBytes = file.bytes;
        _fileName = file.name;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _save() async {
    if (!_hasData || !_form.currentState!.validate()) return;
    if (_display &&
        _imageBytes == null &&
        (_imageUrl == null || _imageUrl!.isEmpty)) {
      setState(() => _error = 'Vui lòng chọn ảnh trước khi bật hiển thị.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_imageBytes != null) {
        final response = await _api.post(
          '/campaigns/images',
          data: FormData.fromMap({
            'file': MultipartFile.fromBytes(
              _imageBytes!,
              filename: _fileName ?? 'new-products.jpg',
            ),
          }),
        );
        if (!mounted) return;
        setState(() {
          _imageUrl = response.data['data']['url'] as String;
          _imageBytes = null;
        });
      }
      await _api.put(
        '/admin/home/new-products',
        data: {
          'title': _title.text.trim(),
          'description': _description.text.trim(),
          'imageUrl': _imageUrl,
          'isDisplay': _display,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu giao diện sản phẩm mới')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _input(String label) => InputDecoration(
    labelText: label,
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
        const SizedBox(height: 20),
        ...children,
      ],
    ),
  );
  Widget _settings() => _card('Sản phẩm mới', [
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: const Text('Hiển thị trên trang chủ'),
      subtitle: const Text('Bật hoặc tắt cả banner và dãy sản phẩm bên dưới.'),
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
    const SizedBox(height: 16),
    OutlinedButton.icon(
      onPressed: _saving ? null : _pickImage,
      icon: const Icon(Icons.add_photo_alternate_outlined),
      label: Text(
        _imageUrl != null || _imageBytes != null
            ? 'Đổi ảnh banner'
            : 'Chọn ảnh banner',
      ),
    ),
    const SizedBox(height: 8),
    Text(
      _fileName ?? 'JPG, PNG, GIF hoặc WebP · Tối đa 10 MB',
      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
    ),
    const SizedBox(height: 24),
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Sản phẩm được chọn tự động trong 7 ngày đầu và hưởng ưu đãi 5%. Tắt hiển thị không tắt ưu đãi giá.',
        style: TextStyle(
          fontSize: 13,
          height: 1.6,
          color: AppTheme.textSecondary,
        ),
      ),
    ),
  ]);
  Widget _preview() => _card('Xem trước banner', [
    ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_imageBytes != null)
              Image.memory(
                _imageBytes!,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, _, _) =>
                    const Center(child: Text('Không xem được ảnh')),
              )
            else if (_imageUrl != null && _imageUrl!.isNotEmpty)
              Image.network(
                _imageUrl!,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, _, _) =>
                    const Center(child: Text('Không tải được ảnh')),
              )
            else
              Container(
                color: AppTheme.surface,
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title.text.isEmpty ? 'Tiêu đề banner' : _title.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _description.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 16),
    Text(
      _display
          ? 'Khối sẽ xuất hiện khi có ảnh và có sản phẩm mới đủ điều kiện.'
          : 'Banner và dãy sản phẩm đang được ẩn khỏi trang chủ.',
      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
    ),
  ]);
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      backgroundColor: AppTheme.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_hasData
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error ?? 'Không tải được cấu hình trang chủ'),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _load,
                    child: const Text('Thử lại'),
                  ),
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
                            'Sản phẩm mới',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Chỉnh sửa nội dung và hiển thị trên trang chủ',
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: AppTheme.error),
                            ),
                          ),
                          TextButton(
                            onPressed: _saving ? null : _load,
                            child: const Text('Tải lại'),
                          ),
                        ],
                      ),
                    ),
                  Form(
                    key: _form,
                    child: LayoutBuilder(
                      builder: (context, c) => c.maxWidth > 1000
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 400, child: _settings()),
                                const SizedBox(width: 24),
                                Expanded(child: _preview()),
                              ],
                            )
                          : Column(
                              children: [
                                _settings(),
                                const SizedBox(height: 24),
                                _preview(),
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
