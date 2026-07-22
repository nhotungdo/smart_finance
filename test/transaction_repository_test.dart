import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/data/repositories/transaction_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late TransactionRepository repository;

  setUp(() async {
    sqfliteFfiInit();
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute('PRAGMA foreign_keys = ON');
    await database.execute('''
      CREATE TABLE categories (
        category_id TEXT PRIMARY KEY,
        company_id TEXT,
        category_name TEXT NOT NULL,
        category_type TEXT NOT NULL,
        is_default INTEGER DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'ACTIVE'
      )
    ''');
    await database.insert('categories', {
      'category_id': 'office',
      'company_id': 'company-a',
      'category_name': 'Văn phòng',
      'category_type': 'EXPENSE',
      'is_default': 1,
      'status': 'ACTIVE',
    });
    await database.execute('''
      CREATE TABLE transactions (
        transaction_id TEXT PRIMARY KEY,
        company_id TEXT,
        category_id TEXT REFERENCES categories(category_id),
        created_by TEXT,
        invoice_id TEXT,
        amount INTEGER NOT NULL,
        transaction_type TEXT NOT NULL,
        transaction_date TEXT NOT NULL,
        description TEXT,
        receipt_image_path TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        approval_status TEXT NOT NULL DEFAULT 'PENDING',
        approved_by TEXT,
        approved_at TEXT,
        rejection_reason TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    await database.execute('''
      CREATE TABLE invoices (
        invoice_id TEXT PRIMARY KEY,
        company_id TEXT,
        uploaded_by TEXT,
        invoice_type TEXT NOT NULL,
        invoice_number TEXT,
        invoice_date TEXT,
        total_amount INTEGER,
        image_path TEXT,
        created_at TEXT
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

  test(
    'accountant is scoped to own records while manager sees company',
    () async {
      await _insertTransaction(
        database,
        id: 'owned-by-a',
        companyId: 'company-a',
        createdBy: 'user-a',
      );
      await _insertTransaction(
        database,
        id: 'owned-by-b',
        companyId: 'company-a',
        createdBy: 'user-b',
      );

      final accountantRows = await repository.getRecentTransactions(
        companyId: 'company-a',
        createdBy: 'user-a',
        limit: null,
      );
      final managerRows = await repository.getRecentTransactions(
        companyId: 'company-a',
        limit: null,
      );

      expect(accountantRows.map((item) => item.transactionId), ['owned-by-a']);
      expect(managerRows, hasLength(2));
    },
  );

  test('financial report query only returns approved transactions', () async {
    await _insertTransaction(
      database,
      id: 'pending-report',
      companyId: 'company-a',
    );
    await _insertTransaction(
      database,
      id: 'approved-report',
      companyId: 'company-a',
      approvalStatus: 'APPROVED',
    );

    final rows = await repository.getTransactionsByDateRange(
      DateTime(2026, 7, 1),
      DateTime(2026, 7, 31, 23, 59, 59),
      companyId: 'company-a',
      approvalStatus: ApprovalStatus.approved,
    );

    expect(rows.map((item) => item.transactionId), ['approved-report']);
  });

  test('updates an unlinked transaction and marks it pending sync', () async {
    await _insertTransaction(database, id: 'editable', companyId: 'company-a');
    final current = await repository.getTransactionById('editable');

    await repository.updateTransaction(current!.copyWith(amount: 2450000));

    final updated = await repository.getTransactionById('editable');
    expect(updated!.amount, 2450000);
    expect(updated.approvalStatus, ApprovalStatus.pending);
    expect(updated.isSynced, isFalse);
  });

  test('manager approves a pending transaction once', () async {
    await _insertTransaction(database, id: 'pending', companyId: 'company-a');

    await repository.reviewTransaction(
      transactionId: 'pending',
      managerId: 'manager-a',
      decision: ApprovalStatus.approved,
    );

    final reviewed = await repository.getTransactionById('pending');
    expect(reviewed!.approvalStatus, ApprovalStatus.approved);
    expect(reviewed.approvedBy, 'manager-a');
    expect(reviewed.approvedAt, isNotNull);
    expect(reviewed.rejectionReason, isNull);
    await expectLater(
      repository.reviewTransaction(
        transactionId: 'pending',
        managerId: 'manager-a',
        decision: ApprovalStatus.rejected,
        rejectionReason: 'Sai số tiền',
      ),
      throwsStateError,
    );
  });

  test('rejecting a transaction requires and stores a reason', () async {
    await _insertTransaction(database, id: 'rejected', companyId: 'company-a');

    await expectLater(
      repository.reviewTransaction(
        transactionId: 'rejected',
        managerId: 'manager-a',
        decision: ApprovalStatus.rejected,
      ),
      throwsArgumentError,
    );
    await repository.reviewTransaction(
      transactionId: 'rejected',
      managerId: 'manager-a',
      decision: ApprovalStatus.rejected,
      rejectionReason: 'Thiếu chứng từ',
    );

    final reviewed = await repository.getTransactionById('rejected');
    expect(reviewed!.approvalStatus, ApprovalStatus.rejected);
    expect(reviewed.rejectionReason, 'Thiếu chứng từ');
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

  test('repairs an old invoice without an active transaction', () async {
    await database.insert('invoices', {
      'invoice_id': 'legacy-invoice',
      'company_id': 'company-a',
      'uploaded_by': 'user-a',
      'invoice_type': 'INCOME',
      'invoice_number': 'INV-OLD',
      'invoice_date': '2026-07-17T00:00:00.000',
      'total_amount': 2750000,
      'image_path': 'legacy.jpg',
      'created_at': '2026-07-17T08:00:00.000',
    });

    final created = await repository.ensureTransactionsForInvoices(
      companyId: 'company-a',
      createdBy: 'user-a',
    );
    final createdAgain = await repository.ensureTransactionsForInvoices(
      companyId: 'company-a',
      createdBy: 'user-a',
    );
    final linked = await repository.getActiveTransactionForInvoice(
      'legacy-invoice',
    );

    expect(created, 1);
    expect(createdAgain, 0);
    expect(linked, isNotNull);
    expect(linked!.transactionType, TransactionType.income);
    expect(linked.amount, 2750000);
    expect(linked.categoryId, isNull);
    await expectLater(
      repository.deleteTransaction(linked.transactionId),
      throwsStateError,
    );
  });

  test(
    'only returns pending unsynced transactions owned by the user',
    () async {
      await _insertTransaction(
        database,
        id: 'own-pending',
        companyId: 'company-a',
      );
      await _insertTransaction(
        database,
        id: 'other-user',
        companyId: 'company-a',
        createdBy: 'user-b',
      );
      await _insertTransaction(
        database,
        id: 'other-company',
        companyId: 'company-b',
      );
      await _insertTransaction(
        database,
        id: 'own-approved',
        companyId: 'company-a',
        approvalStatus: 'APPROVED',
      );

      final pending = await repository.getUnsyncedTransactions(
        companyId: 'company-a',
        userId: 'user-a',
        role: AppRole.accountant,
      );

      expect(pending.map((transaction) => transaction.transactionId), [
        'own-pending',
      ]);
    },
  );

  test(
    'returns reviewed transactions for the manager who reviewed them',
    () async {
      await _insertTransaction(
        database,
        id: 'reviewed-by-manager',
        companyId: 'company-a',
        createdBy: 'accountant-a',
      );
      await repository.reviewTransaction(
        transactionId: 'reviewed-by-manager',
        managerId: 'manager-a',
        decision: ApprovalStatus.approved,
      );

      final pending = await repository.getUnsyncedTransactions(
        companyId: 'company-a',
        userId: 'manager-a',
        role: AppRole.manager,
      );

      expect(pending.map((transaction) => transaction.transactionId), [
        'reviewed-by-manager',
      ]);
    },
  );

  test('repairs a cloud category id that belongs to another company', () async {
    const canonicalId = 'default:company-a:income:sales';
    await database.insert('categories', {
      'category_id': canonicalId,
      'company_id': 'company-a',
      'category_name': 'Doanh thu bán hàng',
      'category_type': 'INCOME',
      'is_default': 1,
      'status': 'ACTIVE',
    });

    await repository.upsertTransactionFromCloud(
      TransactionModel(
        transactionId: 'cloud-income',
        companyId: 'company-a',
        categoryId: 'default:old-company:income:sales',
        createdBy: 'accountant-a',
        amount: 100000,
        transactionType: TransactionType.income,
        transactionDate: DateTime(2026, 7, 16),
        approvalStatus: ApprovalStatus.approved,
        isSynced: true,
      ),
    );

    final stored = await repository.getTransactionById('cloud-income');
    expect(stored?.categoryId, canonicalId);
  });
}

Future<void> _insertTransaction(
  Database database, {
  required String id,
  required String companyId,
  String status = 'ACTIVE',
  String approvalStatus = 'PENDING',
  String createdBy = 'user-a',
  String? invoiceId,
  String transactionDate = '2026-07-17T00:00:00.000',
  String createdAt = '2026-07-17T08:00:00.000',
}) {
  return database.insert('transactions', <String, Object?>{
    'transaction_id': id,
    'company_id': companyId,
    'category_id': 'office',
    'created_by': createdBy,
    'invoice_id': invoiceId,
    'amount': 1200000,
    'transaction_type': 'EXPENSE',
    'transaction_date': transactionDate,
    'description': 'Văn phòng',
    'receipt_image_path': null,
    'status': status,
    'approval_status': approvalStatus,
    'approved_by': null,
    'approved_at': null,
    'rejection_reason': null,
    'created_at': createdAt,
    'updated_at': createdAt,
    'is_synced': 0,
  });
}
