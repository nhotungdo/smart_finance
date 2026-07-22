class CompanyModel {
  final String companyId;
  final String companyName;
  final String? taxCode;
  final String? address;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isSynced;

  CompanyModel({
    required this.companyId,
    required this.companyName,
    this.taxCode,
    this.address,
    this.phone,
    this.createdAt,
    this.updatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'company_id': companyId,
      'company_name': companyName,
      'tax_code': taxCode,
      'address': address,
      'phone': phone,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      companyId: map['company_id'] as String,
      companyName: map['company_name'] as String,
      taxCode: map['tax_code'] as String?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
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
