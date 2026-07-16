import 'dart:convert';
import 'dart:typed_data';

Future<String> saveReceiptImage(Uint8List bytes, String originalName) async {
  final extension = originalName.split('.').last.toLowerCase();
  final mimeType = switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}
