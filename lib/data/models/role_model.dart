class RoleModel {
  final String roleId;
  final String roleName;
  final String? description;
  final bool isSynced;

  RoleModel({
    required this.roleId,
    required this.roleName,
    this.description,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'role_id': roleId,
      'role_name': roleName,
      'description': description,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory RoleModel.fromMap(Map<String, dynamic> map) {
    return RoleModel(
      roleId: map['role_id'] as String,
      roleName: map['role_name'] as String,
      description: map['description'] as String?,
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}
