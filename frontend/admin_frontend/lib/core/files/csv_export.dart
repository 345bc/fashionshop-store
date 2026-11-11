import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'csv_file_writer_stub.dart'
    if (dart.library.io) 'csv_file_writer_io.dart'
    as writer;

Future<bool> saveCsvFile(String csv, String fileName) async {
  // Excel recognizes Vietnamese correctly with the UTF-8 byte-order mark.
  final bytes = Uint8List.fromList(
    utf8.encode('\uFEFF${csv.replaceFirst(RegExp(r'^\uFEFF'), '')}'),
  );
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Xuất báo cáo CSV',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: ['csv'],
    bytes: bytes,
  );
  // The web picker starts a download and does not return a filesystem path.
  if (kIsWeb) return true;
  if (path == null || path.isEmpty) return false;
  await writer.writeCsvBytes(path, bytes);
  return true;
}
