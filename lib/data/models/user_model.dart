class UserModel {
  final String userId;
  final String? companyId;
  final String? roleId;
  final String fullName;
  final String email;
  final String? passwordHash;
  final String? phone;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isSynced;

  UserModel({
    required this.userId,
    this.companyId,
    this.roleId,
    required this.fullName,
    required this.email,
    this.passwordHash,
    this.phone,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'company_id': companyId,
      'role_id': roleId,
      'full_name': fullName,
      'email': email,
      'password_hash': passwordHash,
      'phone': phone,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id'] as String,
      companyId: map['company_id'] as String?,
      roleId: map['role_id'] as String?,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String?,
      phone: map['phone'] as String?,
      status: map['status'] as String? ?? 'active',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}
