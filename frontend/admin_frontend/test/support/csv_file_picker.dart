import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class CsvFilePicker extends FilePicker {
  String? savePath;
  String? suggestedName;
  Uint8List? capturedBytes;
  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    suggestedName = fileName;
    capturedBytes = bytes;
    return savePath;
  }
}
