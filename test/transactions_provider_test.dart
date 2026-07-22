import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/user_model.dart';
import 'package:smart_finance/data/repositories/transaction_repository.dart';
import 'package:smart_finance/providers/auth_provider.dart';
import 'package:smart_finance/providers/transactions_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late ProviderContainer container;

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
        approval_status TEXT NOT NULL DEFAULT 'PENDING',
        approved_by TEXT,
        approved_at TEXT,
        rejection_reason TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    await database.insert('transactions', {
      'transaction_id': 'pending-1',
      'company_id': 'company-1',
      'created_by': 'accountant-1',
      'amount': 1250000,
      'transaction_type': 'EXPENSE',
      'transaction_date': '2026-07-22T08:00:00.000',
      'description': 'Chi phí văn phòng',
      'status': 'ACTIVE',
      'approval_status': 'PENDING',
      'created_at': '2026-07-22T08:00:00.000',
      'updated_at': '2026-07-22T08:00:00.000',
      'is_synced': 1,
    });

    final repository = TransactionRepository(
      databaseProvider: () async => database,
    );
    container = ProviderContainer(
      overrides: [
        currentUserProfileProvider.overrideWith(
          (ref) async => UserModel(
            userId: 'manager-1',
            companyId: 'company-1',
            roleId: AppRole.manager.roleId,
            fullName: 'Quản lý',
            email: 'manager@example.com',
          ),
        ),
        transactionRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test(
    'review refreshes pending transactions without a provider cycle',
    () async {
      final before = await container.read(pendingTransactionsProvider.future);
      expect(before, hasLength(1));

      await container
          .read(transactionsProvider.notifier)
          .reviewTransaction(
            transactionId: 'pending-1',
            decision: ApprovalStatus.approved,
          );

      final after = await container.read(pendingTransactionsProvider.future);
      expect(after, isEmpty);
      final stored = await database.query(
        'transactions',
        where: 'transaction_id = ?',
        whereArgs: ['pending-1'],
      );
      expect(stored.single['approval_status'], 'APPROVED');
      expect(stored.single['approved_by'], 'manager-1');
      expect(stored.single['is_synced'], 0);
    },
  );

  test('adding a transaction refreshes without a provider cycle', () async {
    await container.read(transactionsProvider.future);

    await container
        .read(transactionsProvider.notifier)
        .addTransaction(
          amount: 3850000,
          transactionType: TransactionType.expense,
          transactionDate: DateTime(2026, 7, 22),
          description: 'Chi hoa don',
          invoiceId: 'invoice-new',
        );

    final transactions = await container.read(transactionsProvider.future);
    expect(transactions, hasLength(2));
    expect(container.read(transactionsProvider).hasError, isFalse);
  });
}
