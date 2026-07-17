import 'dart:convert';

import 'package:smart_finance/data/models/finance_enums.dart';

class InvoiceModel {
  final String id;
  final String companyId;
  final String uploadedBy;
  final TransactionType invoiceType;
  final String? supplierName;
  final String? supplierTaxCode;
  final String? invoiceNumber;
  final DateTime? invoiceDate;
  final int? subtotal;
  final int? vatRate;
  final int? vatAmount;
  final int? totalAmount;
  final String? imagePath;
  final InvoiceScanStatus scanStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  InvoiceModel({
    required this.id,
    required this.companyId,
    required this.uploadedBy,
    this.invoiceType = TransactionType.expense,
    this.supplierName,
    this.supplierTaxCode,
    this.invoiceNumber,
    this.invoiceDate,
    this.subtotal,
    this.vatRate,
    this.vatAmount,
    this.totalAmount,
    this.imagePath,
    this.scanStatus = InvoiceScanStatus.notScanned,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  InvoiceModel copyWith({
    String? id,
    String? companyId,
    String? uploadedBy,
    TransactionType? invoiceType,
    String? supplierName,
    String? supplierTaxCode,
    String? invoiceNumber,
    DateTime? invoiceDate,
    int? subtotal,
    int? vatRate,
    int? vatAmount,
    int? totalAmount,
    String? imagePath,
    InvoiceScanStatus? scanStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      invoiceType: invoiceType ?? this.invoiceType,
      supplierName: supplierName ?? this.supplierName,
      supplierTaxCode: supplierTaxCode ?? this.supplierTaxCode,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      subtotal: subtotal ?? this.subtotal,
      vatRate: vatRate ?? this.vatRate,
      vatAmount: vatAmount ?? this.vatAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      imagePath: imagePath ?? this.imagePath,
      scanStatus: scanStatus ?? this.scanStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoice_id': id,
      'company_id': companyId,
      'uploaded_by': uploadedBy,
      'invoice_type': invoiceType.databaseValue,
      'supplier_name': supplierName,
      'supplier_tax_code': supplierTaxCode,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate?.toIso8601String(),
      'subtotal': subtotal,
      'vat_rate': vatRate,
      'vat_amount': vatAmount,
      'total_amount': totalAmount,
      'image_path': imagePath,
      'scan_status': scanStatus.databaseValue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['invoice_id'] ?? '',
      companyId: map['company_id'] ?? '',
      uploadedBy: map['uploaded_by'] ?? '',
      invoiceType: TransactionType.fromDatabase(
        map['invoice_type'] ?? TransactionType.expense.databaseValue,
      ),
      supplierName: map['supplier_name'],
      supplierTaxCode: map['supplier_tax_code'],
      invoiceNumber: map['invoice_number'],
      invoiceDate: map['invoice_date'] != null
          ? DateTime.parse(map['invoice_date'])
          : null,
      subtotal: (map['subtotal'] as num?)?.round(),
      vatRate: (map['vat_rate'] as num?)?.round(),
      vatAmount: (map['vat_amount'] as num?)?.round(),
      totalAmount: (map['total_amount'] as num?)?.round(),
      imagePath: map['image_path'],
      scanStatus: InvoiceScanStatus.fromDatabase(map['scan_status']),
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      isSynced: map['is_synced'] == 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory InvoiceModel.fromJson(String source) =>
      InvoiceModel.fromMap(json.decode(source));
}
