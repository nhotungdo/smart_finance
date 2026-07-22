import 'package:smart_finance/data/models/finance_enums.dart';

class UserModel {
  final String userId;
  final String? companyId;
  final String? roleId;
  final String fullName;
  final String email;
  final String? passwordHash;
  final String? phone;
  final RecordStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isSynced;

  AppRole get role => AppRole.fromRoleId(roleId);
  bool get isManager => role == AppRole.manager;
  bool get isAccountant => role == AppRole.accountant;

  UserModel({
    required this.userId,
    this.companyId,
    this.roleId,
    required this.fullName,
    required this.email,
    this.passwordHash,
    this.phone,
    this.status = RecordStatus.active,
    this.createdAt,
    this.updatedAt,
    this.isSynced = false,
  });

  UserModel copyWith({
    String? userId,
    String? companyId,
    String? roleId,
    String? fullName,
    String? email,
    String? passwordHash,
    String? phone,
    RecordStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      companyId: companyId ?? this.companyId,
      roleId: roleId ?? this.roleId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'company_id': companyId,
      'role_id': roleId,
      'full_name': fullName,
      'email': email,
      'password_hash': passwordHash,
      'phone': phone,
      'status': status.databaseValue,
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
      status: RecordStatus.fromDatabase(map['status']),
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
