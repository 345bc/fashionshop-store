import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zella_admin_flutter/core/files/csv_export.dart';

import 'support/csv_file_picker.dart';

void main() {
  test('save CSV writes UTF-8 BOM and preserves Vietnamese text', () async {
    final directory = await Directory.systemTemp.createTemp('zella-csv-test-');
    final file = File('${directory.path}/bao-cao.csv');
    final picker = CsvFilePicker()..savePath = file.path;
    FilePicker.platform = picker;
    try {
      expect(
        await saveCsvFile('Tên,Doanh thu\r\nÁo sơ mi,100000', 'bao-cao.csv'),
        true,
      );
      final bytes = await file.readAsBytes();
      expect(bytes.take(3).toList(), [239, 187, 191]);
      expect(utf8.decode(bytes), 'Tên,Doanh thu\r\nÁo sơ mi,100000');
      expect(picker.suggestedName, 'bao-cao.csv');
    } finally {
      if (await file.exists()) await file.delete();
      await directory.delete();
    }
  });
  test('canceling the save dialog reports cancellation', () async {
    FilePicker.platform = CsvFilePicker();
    expect(await saveCsvFile('Báo cáo', 'bao-cao.csv'), false);
  });
}
