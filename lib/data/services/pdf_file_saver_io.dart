import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> savePdfBytes(Uint8List bytes, String fileName) async {
  final documentsDirectory = await getApplicationDocumentsDirectory();
  final exportDirectory = Directory(
    '${documentsDirectory.path}${Platform.pathSeparator}SmartFinance'
    '${Platform.pathSeparator}exports',
  );
  await exportDirectory.create(recursive: true);

  final file = File(
    '${exportDirectory.path}${Platform.pathSeparator}$fileName',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
