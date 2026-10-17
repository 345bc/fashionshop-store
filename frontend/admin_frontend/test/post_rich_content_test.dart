import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:zella_admin_flutter/features/posts/post_rich_content.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

void main() {
  test('legacy post text can be edited without losing paragraphs', () {
    final document = loadPostDocument('Bài cũ\r\nĐoạn hai');
    expect(document.toPlainText(), contains('Bài cũ\nĐoạn hai'));
    expect(
      loadPostDocument('{đây là văn bản}').toPlainText(),
      contains('{đây là văn bản}'),
    );
  });
  test('formatting and cloud image survive save and reload', () {
    final ops = [
      {'insert': 'Tiêu đề'},
      {
        'insert': '\n',
        'attributes': {'header': 2},
      },
      {
        'insert': 'Nội dung',
        'attributes': {'bold': true},
      },
      {'insert': '\n'},
      {
        'insert': {'image': 'https://cloud.example/photo.png'},
      },
      {'insert': '\n'},
    ];
    final document = quill.Document.fromJson(ops);
    final encoded = encodePostDocument(document);
    expect(encoded, startsWith(postRichPrefix));
    expect(
      loadPostDocument(encoded).toDelta().toJson(),
      document.toDelta().toJson(),
    );
  });
  testWidgets('editor shows formatting toolbar and cloud image action', (
    tester,
  ) async {
    final controller = quill.QuillController.basic();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          quill.FlutterQuillLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: PostRichEditor(controller: controller, onUploading: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nội dung bài viết'), findsOneWidget);
    expect(find.text('Chèn ảnh từ máy'), findsOneWidget);
    expect(find.byType(quill.QuillSimpleToolbar), findsOneWidget);
    expect(find.byType(quill.QuillEditor), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
