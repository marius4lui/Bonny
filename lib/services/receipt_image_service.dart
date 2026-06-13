import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ReceiptImageService {
  static const _uuid = Uuid();

  Future<String> persistImage(
    String sourcePath, {
    required bool saveImages,
  }) async {
    if (!saveImages) return sourcePath;
    final source = File(sourcePath);
    if (!await source.exists()) return sourcePath;

    final appDir = await getApplicationDocumentsDirectory();
    final receiptDir = Directory(p.join(appDir.path, 'receipts'));
    if (!await receiptDir.exists()) {
      await receiptDir.create(recursive: true);
    }

    final ext = p.extension(sourcePath).isEmpty
        ? '.jpg'
        : p.extension(sourcePath);
    final destination = File(p.join(receiptDir.path, '${_uuid.v4()}$ext'));
    await source.copy(destination.path);
    return destination.path;
  }
}
