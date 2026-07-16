class PdfExportModel {
  final String pdfExportId;
  final String? companyId;
  final String? exportedBy;
  final String? invoiceId;
  final String exportType;
  final String filePath;
  final DateTime? exportedAt;
  final bool isSynced;

  PdfExportModel({
    required this.pdfExportId,
    this.companyId,
    this.exportedBy,
    this.invoiceId,
    required this.exportType,
    required this.filePath,
    this.exportedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'pdf_export_id': pdfExportId,
      'company_id': companyId,
      'exported_by': exportedBy,
      'invoice_id': invoiceId,
      'export_type': exportType,
      'file_path': filePath,
      'exported_at': exportedAt?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory PdfExportModel.fromMap(Map<String, dynamic> map) {
    return PdfExportModel(
      pdfExportId: map['pdf_export_id'] as String,
      companyId: map['company_id'] as String?,
      exportedBy: map['exported_by'] as String?,
      invoiceId: map['invoice_id'] as String?,
      exportType: map['export_type'] as String,
      filePath: map['file_path'] as String,
      exportedAt: map['exported_at'] != null ? DateTime.parse(map['exported_at'] as String) : null,
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}
