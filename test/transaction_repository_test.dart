import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/data/repositories/transaction_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late TransactionRepository repository;

  setUp(() async {
    sqfliteFfiInit();
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute('''
      CREATE TABLE transactions (
        transaction_id TEXT PRIMARY KEY,
        company_id TEXT,
        category_id TEXT,
        created_by TEXT,
        invoice_id TEXT,
        amount INTEGER NOT NULL,
        transaction_type TEXT NOT NULL,
        transaction_date TEXT NOT NULL,
        description TEXT,
        receipt_image_path TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    repository = TransactionRepository(databaseProvider: () async => database);
  });

  tearDown(() async {
    await database.close();
  });

  test('gets an active transaction owned by the selected company', () async {
    await _insertTransaction(
      database,
      id: 'transaction-a',
      companyId: 'company-a',
    );

    final transaction = await repository.getTransactionById(
      'transaction-a',
      companyId: 'company-a',
    );

    expect(transaction, isNotNull);
    expect(transaction!.transactionId, 'transaction-a');
    expect(transaction.amount, 1200000);
  });

  test(
    'does not expose another company transaction or a deleted one',
    () async {
      await _insertTransaction(
        database,
        id: 'other-company',
        companyId: 'company-b',
      );
      await _insertTransaction(
        database,
        id: 'deleted',
        companyId: 'company-a',
        status: 'DELETED',
      );

      final otherCompany = await repository.getTransactionById(
        'other-company',
        companyId: 'company-a',
      );
      final deleted = await repository.getTransactionById(
        'deleted',
        companyId: 'company-a',
      );

      expect(otherCompany, isNull);
      expect(deleted, isNull);
    },
  );

  test('updates an unlinked transaction and marks it pending sync', () async {
    await _insertTransaction(database, id: 'editable', companyId: 'company-a');
    final current = await repository.getTransactionById('editable');

    await repository.updateTransaction(current!.copyWith(amount: 2450000));

    final updated = await repository.getTransactionById('editable');
    expect(updated!.amount, 2450000);
    expect(updated.isSynced, isFalse);
  });

  test(
    'does not update or delete a transaction linked to an invoice',
    () async {
      await _insertTransaction(
        database,
        id: 'linked',
        companyId: 'company-a',
        invoiceId: 'invoice-a',
      );
      final linked = await repository.getTransactionById('linked');

      await expectLater(
        repository.updateTransaction(linked!.copyWith(amount: 1)),
        throwsStateError,
      );
      await expectLater(
        repository.deleteTransaction('linked'),
        throwsStateError,
      );
    },
  );

  test('does not delete a transaction when a later one exists', () async {
    await _insertTransaction(
      database,
      id: 'older',
      companyId: 'company-a',
      transactionDate: '2026-07-16T00:00:00.000',
      createdAt: '2026-07-16T08:00:00.000',
    );
    await _insertTransaction(
      database,
      id: 'newer',
      companyId: 'company-a',
      transactionDate: '2026-07-17T00:00:00.000',
      createdAt: '2026-07-17T08:00:00.000',
    );

    await expectLater(repository.deleteTransaction('older'), throwsStateError);

    await repository.deleteTransaction('newer');
    await repository.deleteTransaction('older');
    expect(await repository.getTransactionById('older'), isNull);
  });

  test('links an expense transaction to an invoice once', () async {
    await _insertTransaction(database, id: 'expense', companyId: 'company-a');

    await repository.linkInvoiceToTransaction(
      transactionId: 'expense',
      invoiceId: 'invoice-a',
    );

    final linked = await repository.getTransactionById('expense');
    expect(linked!.invoiceId, 'invoice-a');
    expect(linked.isSynced, isFalse);

    await repository.linkInvoiceToTransaction(
      transactionId: 'expense',
      invoiceId: 'invoice-a',
    );
    await expectLater(
      repository.linkInvoiceToTransaction(
        transactionId: 'expense',
        invoiceId: 'invoice-b',
      ),
      throwsStateError,
    );
  });
}

Future<void> _insertTransaction(
  Database database, {
  required String id,
  required String companyId,
  String status = 'ACTIVE',
  String? invoiceId,
  String transactionDate = '2026-07-17T00:00:00.000',
  String createdAt = '2026-07-17T08:00:00.000',
}) {
  return database.insert('transactions', <String, Object?>{
    'transaction_id': id,
    'company_id': companyId,
    'category_id': 'office',
    'created_by': 'user-a',
    'invoice_id': invoiceId,
    'amount': 1200000,
    'transaction_type': 'EXPENSE',
    'transaction_date': transactionDate,
    'description': 'Văn phòng',
    'receipt_image_path': null,
    'status': status,
    'created_at': createdAt,
    'updated_at': createdAt,
    'is_synced': 0,
  });
}
