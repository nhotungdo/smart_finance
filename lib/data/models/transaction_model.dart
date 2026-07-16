class TransactionModel {
  final String transactionId;
  final String? companyId;
  final String? categoryId;
  final String? createdBy;
  final String? invoiceId;
  final double amount;
  final String transactionType; // 'income' or 'expense'
  final DateTime transactionDate;
  final String? description;
  final String? receiptImagePath;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isSynced;

  TransactionModel({
    required this.transactionId,
    this.companyId,
    this.categoryId,
    this.createdBy,
    this.invoiceId,
    required this.amount,
    required this.transactionType,
    required this.transactionDate,
    this.description,
    this.receiptImagePath,
    this.status = 'completed',
    this.createdAt,
    this.updatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'transaction_id': transactionId,
      'company_id': companyId,
      'category_id': categoryId,
      'created_by': createdBy,
      'invoice_id': invoiceId,
      'amount': amount,
      'transaction_type': transactionType,
      'transaction_date': transactionDate.toIso8601String(),
      'description': description,
      'receipt_image_path': receiptImagePath,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      transactionId: map['transaction_id'] as String,
      companyId: map['company_id'] as String?,
      categoryId: map['category_id'] as String?,
      createdBy: map['created_by'] as String?,
      invoiceId: map['invoice_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      transactionType: map['transaction_type'] as String,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      description: map['description'] as String?,
      receiptImagePath: map['receipt_image_path'] as String?,
      status: map['status'] as String? ?? 'completed',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}
