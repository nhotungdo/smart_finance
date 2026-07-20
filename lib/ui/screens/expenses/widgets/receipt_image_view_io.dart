import 'dart:io';

import 'package:flutter/material.dart';

class ReceiptImageView extends StatelessWidget {
  const ReceiptImageView({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const _ImageUnavailable(),
    );
  }
}

class _ImageUnavailable extends StatelessWidget {
  const _ImageUnavailable();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 36),
          SizedBox(height: 8),
          Text('Không thể mở ảnh chứng từ'),
        ],
      ),
    );
  }
}
