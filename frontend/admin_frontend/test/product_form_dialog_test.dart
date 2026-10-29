import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zella_admin_flutter/features/categories/data/models/category_response_model.dart';
import 'package:zella_admin_flutter/features/categories/presentation/providers/categories_provider.dart';
import 'package:zella_admin_flutter/features/suppliers/data/models/supplier_response_model.dart';
import 'package:zella_admin_flutter/features/suppliers/presentation/providers/suppliers_provider.dart';
import 'package:zella_admin_flutter/features/sizeguides/data/models/size_guide_response_model.dart';
import 'package:zella_admin_flutter/features/sizeguides/presentation/providers/size_guides_provider.dart';
import 'package:zella_admin_flutter/features/products/presentation/providers/products_provider.dart';
import 'package:zella_admin_flutter/features/products/presentation/dialogs/product_form_dialog.dart';

class FormCategories extends CategoriesProvider {
  @override
  Future<void> loadOptions() async {}
  @override
  List<CategoryResponseModel> get options => [
    CategoryResponseModel.fromJson({'id': 1, 'name': 'Áo'}),
  ];
}

class FormSuppliers extends SuppliersProvider {
  @override
  Future<void> loadOptions() async {}
  @override
  List<SupplierResponseModel> get options => [
    SupplierResponseModel.fromJson({'id': 2, 'name': 'Nhà cung cấp'}),
  ];
}

class FormGuides extends SizeGuidesProvider {
  @override
  Future<void> loadItems() async {}
  @override
  List<SizeGuideResponseModel> get items => [
    SizeGuideResponseModel.fromJson({'id': 3, 'name': 'Bảng size'}),
  ];
}

class FormProducts extends ProductsProvider {
  int creates = 0;
  int updates = 0;
  int imageLoads = 0;
  Map<String, dynamic>? saved;
  @override
  Future<Map<String, dynamic>> createItem(Map<String, dynamic> data) async {
    creates++;
    saved = data;
    return {'id': 10};
  }

  @override
  Future<void> updateItem(int id, Map<String, dynamic> data) async {
    expect(id, 10);
    updates++;
    saved = data;
  }

  @override
  Future<List<Map<String, dynamic>>> loadImages(int id) async {
    imageLoads++;
    return [];
  }
}

Future<void> openForm(
  WidgetTester tester,
  Widget dialog,
  FormProducts products,
) async {
  tester.view.physicalSize = const Size(1200, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CategoriesProvider>(
          create: (_) => FormCategories(),
        ),
        ChangeNotifierProvider<SuppliersProvider>(
          create: (_) => FormSuppliers(),
        ),
        ChangeNotifierProvider<SizeGuidesProvider>(create: (_) => FormGuides()),
        ChangeNotifierProvider<ProductsProvider>.value(value: products),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  showDialog<void>(context: context, builder: (_) => dialog),
              child: const Text('Mở'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Mở'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(
    () => dotenv.loadFromString(
      envString: 'API_BASE_URL=http://localhost:8080/api/v1',
    ),
  );

  testWidgets('create starts empty and validates before calling API', (
    tester,
  ) async {
    final products = FormProducts();
    await openForm(tester, const ProductFormDialog(), products);
    expect(find.text('Thêm sản phẩm mới'), findsOneWidget);
    expect(products.imageLoads, 0);
    await tester.tap(find.text('Tạo sản phẩm'));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập tên'), findsOneWidget);
    expect(products.creates, 0);
    expect(products.updates, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit prefills shared form and updates the existing product', (
    tester,
  ) async {
    final products = FormProducts();
    await openForm(
      tester,
      const ProductFormDialog(
        product: {
          'id': 10,
          'name': 'Áo ban đầu',
          'basePrice': 150000,
          'categoryId': 1,
          'supplierId': 2,
          'sizeGuideId': 3,
          'isActive': false,
        },
      ),
      products,
    );
    expect(find.text('Chỉnh sửa sản phẩm'), findsOneWidget);
    expect(products.imageLoads, 1);
    await tester.enterText(find.byType(TextFormField).first, 'Áo đã sửa');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(products.creates, 0);
    expect(products.updates, 1);
    expect(products.saved?['name'], 'Áo đã sửa');
    expect(products.saved?['isActive'], false);
    expect(products.saved?['categoryId'], 1);
    expect(find.text('Chỉnh sửa sản phẩm'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
