import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';

const postRichPrefix = 'zella-quill-v1:';

quill.Document loadPostDocument(String content) {
  if (content.startsWith(postRichPrefix)) {
    return quill.Document.fromJson(
      jsonDecode(content.substring(postRichPrefix.length)) as List,
    );
  }
  final document = quill.Document();
  if (content.isNotEmpty) document.insert(0, content.replaceAll('\r\n', '\n'));
  return document;
}

String encodePostDocument(quill.Document document) =>
    postRichPrefix + jsonEncode(document.toDelta().toJson());

class PostImageEmbedBuilder extends quill.EmbedBuilder {
  const PostImageEmbedBuilder();
  @override
  String get key => 'image';
  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final url = embedContext.node.value.data.toString();
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      return const Text('Đường dẫn ảnh không hợp lệ');
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        height: 280,
        errorBuilder: (_, error, stack) => const SizedBox(
          height: 100,
          child: Center(child: Text('Không tải được ảnh')),
        ),
      ),
    );
  }
}

class PostRichEditor extends StatefulWidget {
  final quill.QuillController controller;
  final bool disabled;
  final ValueChanged<bool> onUploading;
  const PostRichEditor({
    super.key,
    required this.controller,
    required this.onUploading,
    this.disabled = false,
  });
  @override
  State<PostRichEditor> createState() => _PostRichEditorState();
}

class _PostRichEditorState extends State<PostRichEditor> {
  bool _uploading = false;
  String? _error;
  Future<void> _insertImage() async {
    if (_uploading || widget.disabled) return;
    final selection = widget.controller.selection;
    setState(() {
      _uploading = true;
      _error = null;
    });
    widget.controller.readOnly = true;
    widget.onUploading(true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
        withData: true,
      );
      if (result == null || !mounted) return;
      final file = result.files.single;
      if (file.bytes == null || file.bytes!.isEmpty) {
        throw Exception('Không đọc được ảnh');
      }
      final response = await ApiClient().post(
        '/admin/posts/images',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
        }),
      );
      if (!mounted) return;
      final url = response.data['data']['url'] as String;
      final index = selection.baseOffset.clamp(
        0,
        widget.controller.document.length - 1,
      );
      widget.controller.readOnly = false;
      widget.controller.replaceText(
        index,
        0,
        quill.BlockEmbed.image(url),
        TextSelection.collapsed(offset: index + 1),
      );
    } catch (e) {
      if (mounted) setState(() => _error = 'Không thể chèn ảnh: $e');
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
        widget.controller.readOnly = false;
        widget.onUploading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => FormField<String>(
    validator: (_) {
      final content = widget.controller.document
          .toPlainText()
          .replaceAll('\uFFFC', '')
          .trim();
      final images = widget.controller.document.toDelta().toJson().any(
        (op) => op['insert'] is Map,
      );
      if (content.isEmpty && !images) return 'Vui lòng nhập nội dung bài viết';
      if (encodePostDocument(widget.controller.document).length > 100000) {
        return 'Nội dung vượt quá dung lượng cho phép';
      }
      return null;
    },
    builder: (field) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nội dung bài viết',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: field.hasError ? Colors.red : Colors.black12,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AbsorbPointer(
                absorbing: widget.disabled || _uploading,
                child: QuillSimpleToolbarForPost(controller: widget.controller),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: widget.disabled || _uploading
                        ? null
                        : _insertImage,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      _uploading ? 'Đang tải ảnh…' : 'Chèn ảnh từ máy',
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 480,
                child: AbsorbPointer(
                  absorbing: widget.disabled || _uploading,
                  child: quill.QuillEditor.basic(
                    controller: widget.controller,
                    config: const quill.QuillEditorConfig(
                      padding: EdgeInsets.all(16),
                      placeholder: 'Bắt đầu viết câu chuyện của bạn…',
                      embedBuilders: [PostImageEmbedBuilder()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (field.errorText != null)
          Text(field.errorText!, style: const TextStyle(color: Colors.red)),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 20),
      ],
    ),
  );
}

class QuillSimpleToolbarForPost extends StatelessWidget {
  final quill.QuillController controller;
  const QuillSimpleToolbarForPost({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => quill.QuillSimpleToolbar(
    controller: controller,
    config: const quill.QuillSimpleToolbarConfig(
      toolbarIconAlignment: WrapAlignment.start,
      showFontFamily: false,
      showFontSize: false,
      showColorButton: false,
      showBackgroundColorButton: false,
      showInlineCode: false,
      showCodeBlock: false,
      showListCheck: false,
      showSubscript: false,
      showSuperscript: false,
      showSearchButton: false,
      showAlignmentButtons: true,
    ),
  );
}
