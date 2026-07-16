import 'dart:convert';

class OcrResultModel {
  final String id;
  final String invoiceId;
  final String? extractedSupplierName;
  final String? extractedTaxCode;
  final double? extractedAmount;
  final String? rawMockData;
  final String status;
  final DateTime scannedAt;

  OcrResultModel({
    required this.id,
    required this.invoiceId,
    this.extractedSupplierName,
    this.extractedTaxCode,
    this.extractedAmount,
    this.rawMockData,
    this.status = 'processed',
    required this.scannedAt,
  });

  OcrResultModel copyWith({
    String? id,
    String? invoiceId,
    String? extractedSupplierName,
    String? extractedTaxCode,
    double? extractedAmount,
    String? rawMockData,
    String? status,
    DateTime? scannedAt,
  }) {
    return OcrResultModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      extractedSupplierName: extractedSupplierName ?? this.extractedSupplierName,
      extractedTaxCode: extractedTaxCode ?? this.extractedTaxCode,
      extractedAmount: extractedAmount ?? this.extractedAmount,
      rawMockData: rawMockData ?? this.rawMockData,
      status: status ?? this.status,
      scannedAt: scannedAt ?? this.scannedAt,
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
      'status': status,
      'scanned_at': scannedAt.toIso8601String(),
    };
  }

  factory OcrResultModel.fromMap(Map<String, dynamic> map) {
    return OcrResultModel(
      id: map['ocr_result_id'] ?? '',
      invoiceId: map['invoice_id'] ?? '',
      extractedSupplierName: map['extracted_supplier_name'],
      extractedTaxCode: map['extracted_tax_code'],
      extractedAmount: map['extracted_amount']?.toDouble(),
      rawMockData: map['raw_mock_data'],
      status: map['status'] ?? 'processed',
      scannedAt: DateTime.parse(map['scanned_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  String toJson() => json.encode(toMap());

  factory OcrResultModel.fromJson(String source) => OcrResultModel.fromMap(json.decode(source));
}
