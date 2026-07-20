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
