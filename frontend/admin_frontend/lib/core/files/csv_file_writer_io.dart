import 'dart:io';
import 'dart:typed_data';

Future<void> writeCsvBytes(String path, Uint8List bytes) async {
  // Mobile pickers save the supplied bytes; desktop pickers only return a path.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await File(path).writeAsBytes(bytes, flush: true);
  }
}
