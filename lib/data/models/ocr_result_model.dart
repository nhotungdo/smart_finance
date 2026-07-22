import 'dart:convert';

import 'package:smart_finance/data/models/finance_enums.dart';

class OcrResultModel {
  final String id;
  final String invoiceId;
  final String? extractedSupplierName;
  final String? extractedTaxCode;
  final int? extractedAmount;
  final String? rawMockData;
  final InvoiceScanStatus status;
  final DateTime scannedAt;
  final bool isSynced;

  Map<String, dynamic> get mockData {
    final source = rawMockData;
    if (source == null || source.isEmpty) return const {};
    try {
      final decoded = json.decode(source);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }

  TransactionType? get extractedTransactionType {
    final value = mockData['transaction_type'];
    if (value == null) return null;
    try {
      return TransactionType.fromDatabase(value);
    } on FormatException {
      return null;
    }
  }

  String? get extractedCategoryName {
    final value = mockData['category_name']?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  OcrResultModel({
    required this.id,
    required this.invoiceId,
    this.extractedSupplierName,
    this.extractedTaxCode,
    this.extractedAmount,
    this.rawMockData,
    this.status = InvoiceScanStatus.scanned,
    required this.scannedAt,
    this.isSynced = false,
  });

  OcrResultModel copyWith({
    String? id,
    String? invoiceId,
    String? extractedSupplierName,
    String? extractedTaxCode,
    int? extractedAmount,
    String? rawMockData,
    InvoiceScanStatus? status,
    DateTime? scannedAt,
    bool? isSynced,
  }) {
    return OcrResultModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      extractedSupplierName:
          extractedSupplierName ?? this.extractedSupplierName,
      extractedTaxCode: extractedTaxCode ?? this.extractedTaxCode,
      extractedAmount: extractedAmount ?? this.extractedAmount,
      rawMockData: rawMockData ?? this.rawMockData,
      status: status ?? this.status,
      scannedAt: scannedAt ?? this.scannedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ocr_result_id': id,
      'invoice_id': invoiceId,
      'extracted_supplier_name': extractedSupplierName,
      'extracted_tax_code': extractedTaxCode,
      'extracted_amount': extractedAmount,
      'raw_mock_data': rawMockData,
      'status': status.databaseValue,
      'scanned_at': scannedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory OcrResultModel.fromMap(Map<String, dynamic> map) {
    return OcrResultModel(
      id: map['ocr_result_id'] ?? '',
      invoiceId: map['invoice_id'] ?? '',
      extractedSupplierName: map['extracted_supplier_name'],
      extractedTaxCode: map['extracted_tax_code'],
      extractedAmount: (map['extracted_amount'] as num?)?.round(),
      rawMockData: map['raw_mock_data'],
      status: InvoiceScanStatus.fromDatabase(map['status']),
      scannedAt: DateTime.parse(
        map['scanned_at'] ?? DateTime.now().toIso8601String(),
      ),
      isSynced: map['is_synced'] == 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory OcrResultModel.fromJson(String source) =>
      OcrResultModel.fromMap(json.decode(source));
}
