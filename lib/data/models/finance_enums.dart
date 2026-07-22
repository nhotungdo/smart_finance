enum TransactionType {
  income('INCOME'),
  expense('EXPENSE');

  const TransactionType(this.databaseValue);

  final String databaseValue;

  static TransactionType fromDatabase(Object? value) {
    switch (value?.toString().toUpperCase()) {
      case 'INCOME':
        return TransactionType.income;
      case 'EXPENSE':
        return TransactionType.expense;
      default:
        throw FormatException('Invalid transaction type: $value');
    }
  }
}

enum RecordStatus {
  active('ACTIVE'),
  deleted('DELETED');

  const RecordStatus(this.databaseValue);

  final String databaseValue;

  static RecordStatus fromDatabase(Object? value) {
    return value?.toString().toUpperCase() == 'DELETED'
        ? RecordStatus.deleted
        : RecordStatus.active;
  }
}

enum AppRole {
  manager('role_manager', 'MANAGER', 'Quản lý'),
  accountant('role_accountant', 'ACCOUNTANT', 'Nhân viên kế toán');

  const AppRole(this.roleId, this.databaseValue, this.label);

  final String roleId;
  final String databaseValue;
  final String label;

  static AppRole fromRoleId(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'role_manager':
      case 'role_01':
      case 'role_02':
      case 'role_09':
        return AppRole.manager;
      default:
        return AppRole.accountant;
    }
  }

  static AppRole fromDatabase(Object? value) {
    switch (value?.toString().toUpperCase()) {
      case 'MANAGER':
      case 'ADMIN':
      case 'OWNER':
      case 'DIRECTOR':
        return AppRole.manager;
      default:
        return AppRole.accountant;
    }
  }
}

enum ApprovalStatus {
  pending('PENDING', 'Chờ duyệt'),
  approved('APPROVED', 'Đã duyệt'),
  rejected('REJECTED', 'Từ chối');

  const ApprovalStatus(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

  static ApprovalStatus fromDatabase(Object? value) {
    switch (value?.toString().toUpperCase()) {
      case 'APPROVED':
        return ApprovalStatus.approved;
      case 'REJECTED':
        return ApprovalStatus.rejected;
      default:
        return ApprovalStatus.pending;
    }
  }
}

enum InvoiceScanStatus {
  notScanned('NOT_SCANNED'),
  scanning('SCANNING'),
  scanned('SCANNED'),
  error('ERROR');

  const InvoiceScanStatus(this.databaseValue);

  final String databaseValue;

  static InvoiceScanStatus fromDatabase(Object? value) {
    switch (value?.toString().toUpperCase()) {
      case 'SCANNING':
        return InvoiceScanStatus.scanning;
      case 'SCANNED':
      case 'PROCESSED':
      case 'COMPLETED':
      case 'MANUAL':
        return InvoiceScanStatus.scanned;
      case 'ERROR':
      case 'FAILED':
        return InvoiceScanStatus.error;
      case 'NOT_SCANNED':
      case 'PENDING':
      default:
        return InvoiceScanStatus.notScanned;
    }
  }
}
