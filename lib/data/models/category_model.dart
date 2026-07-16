class CategoryModel {
  final String categoryId;
  final String? companyId;
  final String categoryName;
  final String categoryType; // 'income' or 'expense'
  final String? iconName;
  final String? colorCode;
  final bool isDefault;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isSynced;

  CategoryModel({
    required this.categoryId,
    this.companyId,
    required this.categoryName,
    required this.categoryType,
    this.iconName,
    this.colorCode,
    this.isDefault = false,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'category_id': categoryId,
      'company_id': companyId,
      'category_name': categoryName,
      'category_type': categoryType,
      'icon_name': iconName,
      'color_code': colorCode,
      'is_default': isDefault ? 1 : 0,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      categoryId: map['category_id'] as String,
      companyId: map['company_id'] as String?,
      categoryName: map['category_name'] as String,
      categoryType: map['category_type'] as String,
      iconName: map['icon_name'] as String?,
      colorCode: map['color_code'] as String?,
      isDefault: (map['is_default'] as int?) == 1,
      status: map['status'] as String? ?? 'active',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}
