import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zella_admin_flutter/core/network/api_client.dart';
import 'package:zella_admin_flutter/features/bought_together/bought_together_screen.dart';

class _Adapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  Map<String, dynamic> settings = {
    'windowDays': 180,
    'minSupport': 0.01,
    'minConfidence': 0.1,
    'minLift': 1,
    'maxRecommendations': 8,
    'enabled': true,
  };
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    dynamic data;
    if (options.method == 'PUT') {
      settings = Map<String, dynamic>.from(options.data);
      data = settings;
    } else if (options.path.endsWith('/itemsets')) {
      data = {
        'content': [
          {
            'items': [1, 2, 3],
            'count': 2,
            'support': 2 / 3,
          },
        ],
        'totalElements': 1,
        'totalPages': 1,
      };
    } else if (options.path.endsWith('/rules')) {
      data = {
        'content': [
          {
            'antecedent': [1],
            'consequent': [2, 3],
            'count': 2,
            'support': 2 / 3,
            'confidence': 1,
            'lift': 1.5,
          },
        ],
        'totalElements': 1,
        'totalPages': 1,
      };
    } else if (options.path.endsWith('/preview')) {
      data = {
        'message': 'Đủ điều kiện hiển thị gợi ý.',
        'sourceTransactions': 2,
        'frequentItemsets': 0,
        'qualifyingRules': 0,
        'contextProductIds': [1, 2],
        'productNames': {'1': 'Áo Linen', '2': 'Quần Suông', '3': 'Giày Trắng'},
        'result': {
          'products': [
            {
              'product': {'id': 3, 'name': 'Giày Trắng'},
              'antecedent': [1],
              'consequent': [2, 3],
              'transactions': 2,
              'support': 0.5,
              'confidence': 1,
              'lift': 2,
            },
          ],
        },
      };
    } else {
      data = {
        'computedAt': '2026-10-17T00:00:00Z',
        'windowFrom': '2026-04-20T00:00:00Z',
        'windowTo': '2026-10-17T00:00:00Z',
        'totalTransactions': 3,
        'totalProducts': 3,
        'frequentItemsets': 7,
        'maximumItemsetSize': 3,
        'totalRules': 9,
        'minimumCount': 2,
        'settings': settings,
      };
    }
    return ResponseBody.fromString(
      jsonEncode({'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

void main() {
  testWidgets(
    'loads settings, shows product names and expands mining table to card width',
    (tester) async {
      dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost/api/v1');
      final dio = ApiClient().dio;
      final originalAdapter = dio.httpClientAdapter;
      final interceptors = dio.interceptors.toList();
      final adapter = _Adapter();
      dio.interceptors.clear();
      dio.httpClientAdapter = adapter;
      addTearDown(() {
        dio.httpClientAdapter = originalAdapter;
        dio.interceptors.addAll(interceptors);
      });
      tester.view.physicalSize = const Size(1500, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: BoughtTogetherScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Gợi ý mua kèm'), findsOneWidget);
      final support = find.widgetWithText(TextFormField, 'Minsup (%)');
      expect(tester.widget<TextFormField>(support).controller!.text, '1');
      await tester.enterText(support, '101');
      await tester.tap(find.text('Lưu cấu hình'));
      await tester.pumpAndSettle();
      expect(adapter.calls.where((call) => call.method == 'PUT'), isEmpty);
      await tester.enterText(support, '5');
      await tester.tap(find.text('Lưu cấu hình'));
      await tester.pumpAndSettle();
      expect(adapter.settings['minSupport'], 0.05);
      expect(find.text('Đã lưu cấu hình vào database'), findsOneWidget);
      await tester.tap(find.text('Tính lại mô hình'));
      await tester.pumpAndSettle();
      expect(
        adapter.calls.any(
          (call) => call.method == 'POST' && call.path.endsWith('/rebuild'),
        ),
        isTrue,
      );
      final productId = find.widgetWithText(TextField, 'Mã sản phẩm ');
      await tester.enterText(productId, '1, 2');
      await tester.tap(find.text('Kiểm tra theo cấu hình đã lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Đủ điều kiện hiển thị gợi ý.'), findsOneWidget);
      expect(adapter.calls.last.queryParameters['productIds'], '1,2');
      expect(
        find.text('Sản phẩm đang xét: Áo Linen (#1), Quần Suông (#2)'),
        findsOneWidget,
      );
      expect(
        find.text('Áo Linen (#1) → Quần Suông (#2), Giày Trắng (#3)'),
        findsOneWidget,
      );
      expect(find.text('Số đơn mua chung tối thiểu'), findsNothing);
      expect(adapter.settings.containsKey('minCooccurrence'), isFalse);
      final rules = find.text('Luật X → Y');
      await tester.ensureVisible(rules);
      await tester.tap(rules);
      await tester.pumpAndSettle();
      expect(find.text('{#1}'), findsOneWidget);
      expect(find.text('{#2, #3}'), findsOneWidget);
      expect(
        tester.getSize(find.byType(DataTable).last).width,
        greaterThan(1300),
      );
      final itemsets = find.text('Tập phổ biến (1–n)');
      await tester.tap(itemsets);
      await tester.pumpAndSettle();
      expect(find.text('{#1, #2, #3}'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
