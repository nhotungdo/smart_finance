import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> saveReceiptImage(Uint8List bytes, String originalName) async {
  final documentsDirectory = await getApplicationDocumentsDirectory();
  final receiptDirectory = Directory(
    '${documentsDirectory.path}${Platform.pathSeparator}SmartFinance'
    '${Platform.pathSeparator}receipts',
  );
  await receiptDirectory.create(recursive: true);

  final safeName = originalName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final fileName = '${DateTime.now().microsecondsSinceEpoch}_$safeName';
  final file = File(
    '${receiptDirectory.path}${Platform.pathSeparator}$fileName',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
