import 'package:smart_finance/data/models/finance_enums.dart';

class TransactionModel {
  final String transactionId;
  final String? companyId;
  final String? categoryId;
  final String? createdBy;
  final String? invoiceId;
  final int amount;
  final TransactionType transactionType;
  final DateTime transactionDate;
  final String? description;
  final String? receiptImagePath;
  final RecordStatus status;
  final ApprovalStatus approvalStatus;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
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
    this.status = RecordStatus.active,
    this.approvalStatus = ApprovalStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.isSynced = false,
  });

  TransactionModel copyWith({
    String? transactionId,
    String? companyId,
    String? categoryId,
    String? createdBy,
    String? invoiceId,
    int? amount,
    TransactionType? transactionType,
    DateTime? transactionDate,
    String? description,
    String? receiptImagePath,
    RecordStatus? status,
    ApprovalStatus? approvalStatus,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    bool clearApproval = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return TransactionModel(
      transactionId: transactionId ?? this.transactionId,
      companyId: companyId ?? this.companyId,
      categoryId: categoryId ?? this.categoryId,
      createdBy: createdBy ?? this.createdBy,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      transactionDate: transactionDate ?? this.transactionDate,
      description: description ?? this.description,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      status: status ?? this.status,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: clearApproval ? null : approvedBy ?? this.approvedBy,
      approvedAt: clearApproval ? null : approvedAt ?? this.approvedAt,
      rejectionReason: clearApproval
          ? null
          : rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transaction_id': transactionId,
      'company_id': companyId,
      'category_id': categoryId,
      'created_by': createdBy,
      'invoice_id': invoiceId,
      'amount': amount,
      'transaction_type': transactionType.databaseValue,
      'transaction_date': transactionDate.toIso8601String(),
      'description': description,
      'receipt_image_path': receiptImagePath,
      'status': status.databaseValue,
      'approval_status': approvalStatus.databaseValue,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
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
      amount: (map['amount'] as num).round(),
      transactionType: TransactionType.fromDatabase(map['transaction_type']),
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      description: map['description'] as String?,
      receiptImagePath: map['receipt_image_path'] as String?,
      status: RecordStatus.fromDatabase(map['status']),
      approvalStatus: ApprovalStatus.fromDatabase(map['approval_status']),
      approvedBy: map['approved_by'] as String?,
      approvedAt: map['approved_at'] != null
          ? DateTime.parse(map['approved_at'] as String)
          : null,
      rejectionReason: map['rejection_reason'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}
