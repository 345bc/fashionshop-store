import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:zella_admin_flutter/features/auth/presentation/provider/auth_provider.dart';
import 'package:zella_admin_flutter/features/products/presentation/providers/product_variants_provider.dart';
import 'package:zella_admin_flutter/features/products/presentation/screens/product_variants_screen.dart';
import 'package:zella_admin_flutter/features/products/presentation/screens/variant_form_screen.dart';
import 'package:zella_admin_flutter/widgets/common/zella_checkbox.dart';

import 'support/fake_auth.dart';

class _Variants extends ProductVariantsProvider {
  final created = <int, Map<String, dynamic>>{};
  final uploaded = <int, String>{};
  bool failFirstMediumUpload = true;

  @override
  Future<
    ({List<Map<String, dynamic>> sizes, List<Map<String, dynamic>> colors})
  >
  loadOptions() async => (
    sizes: [
      {'id': 1, 'name': 'S'},
      {'id': 2, 'name': 'M'},
    ],
    colors: [
      {'id': 10, 'name': 'Đen', 'hexCode': '#000000'},
      {'id': 20, 'name': 'Trắng', 'hexCode': '#FFFFFF'},
    ],
  );

  @override
  Future<Set<({int sizeId, int colorId})>> loadExistingCombinations(
    int productId,
  ) async => {(sizeId: 2, colorId: 20)};

  @override
  Future<List<Map<String, dynamic>>> loadImages(int variantId) async => [];

  @override
  Future<Map<String, dynamic>> createItem(
    Map<String, dynamic> data, {
    bool refresh = true,
  }) async {
    expect(refresh, isFalse);
    final id = created.length + 1;
    created[id] = data;
    return {'id': id};
  }

  @override
  Future<Map<String, dynamic>> uploadImage({
    required int variantId,
    required String fileName,
    required Uint8List bytes,
    required bool isPrimary,
    required int displayOrder,
  }) async {
    if (created[variantId]!['sizeId'] == 2 && failFirstMediumUpload) {
      failFirstMediumUpload = false;
      throw Exception('Lỗi tải ảnh');
    }
    expect(isPrimary, isTrue);
    expect(uploaded.containsKey(variantId), isFalse);
    uploaded[variantId] = fileName;
    return {'id': variantId, 'imageUrl': '/images/$fileName'};
  }
}

class _ListedVariants extends ProductVariantsProvider {
  Set<int>? requestedDeletes;

  @override
  final List<Map<String, dynamic>> items = [
    {
      'id': 1,
      'sku': 'SKU-BLK-S',
      'colorId': 10,
      'colorName': 'Đen',
      'sizeName': 'S',
      'hasOrders': true,
    },
    {
      'id': 2,
      'sku': 'SKU-WHT-S',
      'colorId': 20,
      'colorName': 'Trắng',
      'sizeName': 'S',
    },
    {
      'id': 3,
      'sku': 'SKU-BLK-M',
      'colorId': 10,
      'colorName': 'Đen',
      'sizeName': 'M',
    },
  ];

  @override
  Future<void> loadItems({
    required int productId,
    int page = 0,
    String? query,
  }) async {}

  @override
  Future<({Set<int> deleted, Map<int, String> errors})> deleteItems(
    int productId,
    Set<int> ids,
  ) async {
    expect(productId, 42);
    requestedDeletes = ids;
    items.removeWhere((item) => item['id'] != 1 && ids.contains(item['id']));
    notifyListeners();
    return (
      deleted: {2, 3},
      errors: {1: 'Biến thể đã có đơn hàng, không thể xóa.'},
    );
  }
}

class _ImagePicker extends FilePicker {
  String name = 'black.png';

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aBeQAAAAASUVORK5CYII=',
    );
    return FilePickerResult([
      PlatformFile(name: name, size: bytes.length, bytes: bytes),
    ]);
  }
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost/api/v1');
  });

  testWidgets(
    'groups variant rows and keeps sold variants during bulk deletion',
    (tester) async {
      final variants = _ListedVariants();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => FakeAuth()),
            ChangeNotifierProvider<ProductVariantsProvider>(
              create: (_) => variants,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ProductVariantsScreen(product: {'id': 42, 'name': 'Áo'}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Đen'), findsOneWidget);
      expect(find.text('Trắng'), findsOneWidget);
      final blackMedium = tester.getTopLeft(find.text('SKU-BLK-M')).dy;
      final whiteHeader = tester.getTopLeft(find.text('Trắng')).dy;
      expect(blackMedium, lessThan(whiteHeader));
      await tester.tap(find.byType(ZellaCheckbox).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Xóa biến thể đã chọn'));
      await tester.pumpAndSettle();
      expect(variants.requestedDeletes, isNull);
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      expect(variants.requestedDeletes, {1, 2, 3});
      expect(find.text('SKU-BLK-S'), findsOneWidget);
      expect(find.text('SKU-BLK-M'), findsNothing);
      expect(find.textContaining('Đã xóa 2/3 biến thể'), findsOneWidget);
      FToast().removeQueuedCustomToasts();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('edit shows color swatches and selects one color immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ProductVariantsProvider>(
        create: (_) => _Variants(),
        child: MaterialApp(
          home: VariantFormScreen(
            productId: 42,
            variant: const {'id': 1, 'sizeId': 1, 'colorId': 10, 'price': 100},
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InkWell, 'Đen'));
    await tester.pumpAndSettle();
    final option = find.widgetWithText(ListTile, 'Trắng');
    final tile = tester.widget<ListTile>(option);
    expect(
      ((tile.leading as Container).decoration as BoxDecoration).color,
      Colors.white,
    );
    await tester.tap(option);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.widgetWithText(InkWell, 'Trắng'), findsOneWidget);
  });

  testWidgets('creates a batch with per-row prices and per-color images', (
    tester,
  ) async {
    final picker = _ImagePicker();
    FilePicker.platform = picker;
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = _Variants();
    var closed = false;
    await tester.pumpWidget(
      ChangeNotifierProvider<ProductVariantsProvider>(
        create: (_) => provider,
        child: MaterialApp(
          home: VariantFormScreen(productId: 42, onClose: () => closed = true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InkWell, 'Chọn kích cỡ'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'S'));
    final search = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(search, 'M');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'S'), findsNothing);
    await tester.tap(find.widgetWithText(ListTile, 'M'));
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();
    expect(find.text('S, M'), findsOneWidget);
    await tester.tap(find.widgetWithText(InkWell, 'Chọn màu sắc'));
    await tester.pumpAndSettle();
    final white = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Trắng'),
    );
    final swatch = (white.leading! as Container).decoration! as BoxDecoration;
    expect(swatch.color, Colors.white);
    expect(swatch.border, isNotNull);
    for (final label in ['Đen', 'Trắng']) {
      await tester.tap(find.widgetWithText(ListTile, label));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();
    expect(find.text('Đen, Trắng'), findsOneWidget);
    expect(find.text('Bỏ qua 1 tổ hợp đã có biến thể.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '100');
    await tester.enterText(
      find.byKey(const ValueKey((sizeId: 1, colorId: 10))),
      '150',
    );
    await tester.tap(find.text('Chọn ảnh từ máy'));
    await tester.pumpAndSettle();
    picker.name = 'white.png';
    await tester.tap(find.widgetWithText(ChoiceChip, 'Trắng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chọn ảnh từ máy'));
    await tester.pumpAndSettle();
    expect(find.text('Ảnh dùng chung'), findsNothing);
    await tester.tap(find.text('Thêm 3 biến thể'));
    await tester.pumpAndSettle();
    expect(closed, isFalse);
    expect(provider.created, hasLength(3));
    expect(provider.uploaded, hasLength(2));

    await tester.tap(find.text('Thử lưu lại'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(provider.created, hasLength(3));
    expect(provider.uploaded, hasLength(3));
    for (final entry in provider.created.entries) {
      final black = entry.value['colorId'] == 10;
      expect(provider.uploaded[entry.key], black ? 'black.png' : 'white.png');
      expect(
        entry.value['price'],
        black && entry.value['sizeId'] == 1 ? 150 : 100,
      );
    }
    FToast().removeQueuedCustomToasts();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
