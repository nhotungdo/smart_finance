import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/data/repositories/category_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late CategoryRepository repository;

  setUp(() async {
    sqfliteFfiInit();
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute('''
      CREATE TABLE categories (
        category_id TEXT PRIMARY KEY,
        company_id TEXT,
        category_name TEXT NOT NULL,
        category_type TEXT NOT NULL,
        icon_name TEXT,
        color_code TEXT,
        is_default INTEGER DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    await database.execute('''
      CREATE TABLE transactions (
        transaction_id TEXT PRIMARY KEY,
        category_id TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    repository = CategoryRepository(databaseProvider: () async => database);
  });

  tearDown(() async {
    await database.close();
  });

  test('only returns categories owned by the selected company', () async {
    await _insertCategory(database, id: 'a-travel', companyId: 'company-a');
    await _insertCategory(database, id: 'b-travel', companyId: 'company-b');
    await _insertCategory(
      database,
      id: 'global-travel',
      companyId: null,
      name: 'Danh mục chung',
    );

    final categories = await repository.getCategories(companyId: 'company-a');

    expect(
      categories.map((category) => category.categoryId),
      containsAll(<String>['a-travel', 'global-travel']),
    );
    expect(
      categories.map((category) => category.categoryId),
      isNot(contains('b-travel')),
    );
  });

  test(
    'seeding is idempotent and remaps duplicate category references',
    () async {
      await _insertCategory(
        database,
        id: 'travel-1',
        companyId: 'company-a',
        createdAt: '2026-01-01T00:00:00.000',
      );
      await _insertCategory(
        database,
        id: 'travel-2',
        companyId: 'company-a',
        createdAt: '2026-01-02T00:00:00.000',
      );
      await _insertCategory(
        database,
        id: 'travel-3',
        companyId: 'company-a',
        createdAt: '2026-01-03T00:00:00.000',
      );
      await _insertCategory(
        database,
        id: 'legacy-salary',
        companyId: 'company-a',
        name: 'Tiền lương',
      );
      await database.insert('transactions', <String, Object>{
        'transaction_id': 'transaction-1',
        'category_id': 'travel-2',
        'is_synced': 1,
      });

      await repository.seedDefaultCategories('company-a');
      await repository.seedDefaultCategories('company-a');

      final categories = await repository.getCategories(companyId: 'company-a');
      final travelCategories = categories.where(
        (category) => category.categoryName == 'Du lịch',
      );
      final transaction = await database.query(
        'transactions',
        where: 'transaction_id = ?',
        whereArgs: <Object>['transaction-1'],
        limit: 1,
      );

      expect(categories, hasLength(6));
      expect(travelCategories, hasLength(1));
      expect(
        travelCategories.single.categoryId,
        'default:company-a:expense:travel',
      );
      expect(
        transaction.single['category_id'],
        'default:company-a:expense:travel',
      );
      expect(transaction.single['is_synced'], 0);
      expect(
        categories.where((category) => category.categoryName == 'Lương'),
        hasLength(1),
      );
      expect(
        categories.where((category) => category.categoryName == 'Tiền lương'),
        isEmpty,
      );
    },
  );

  test(
    'canonicalizes legacy default ids while unique index is active',
    () async {
      await _insertCategory(
        database,
        id: 'legacy-travel',
        companyId: 'company-a',
      );
      await _insertCategory(
        database,
        id: 'legacy-salary',
        companyId: 'company-a',
        name: 'Tiền lương',
      );
      await _createUniqueIndex(database);

      await repository.seedDefaultCategories('company-a');
      await repository.seedDefaultCategories('company-a');

      final categories = await repository.getCategories(companyId: 'company-a');
      expect(categories, hasLength(6));
      expect(
        categories.map((category) => category.categoryId),
        containsAll([
          'default:company-a:expense:travel',
          'default:company-a:expense:salary',
        ]),
      );
    },
  );

  test('only returns unsynced categories from the active company', () async {
    await _insertCategory(
      database,
      id: 'company-a-item',
      companyId: 'company-a',
    );
    await _insertCategory(
      database,
      id: 'company-b-item',
      companyId: 'company-b',
    );
    await _insertCategory(database, id: 'legacy-global', companyId: null);

    final pending = await repository.getUnsyncedCategories(
      companyId: 'company-a',
    );

    expect(pending.map((item) => item.categoryId), ['company-a-item']);
  });
}

Future<void> _createUniqueIndex(Database database) {
  return database.execute('''
    CREATE UNIQUE INDEX categories_company_name_type_active_idx
    ON categories(
      COALESCE(company_id, ''),
      LOWER(TRIM(category_name)),
      category_type
    )
    WHERE status = 'ACTIVE'
  ''');
}

Future<void> _insertCategory(
  Database database, {
  required String id,
  required String? companyId,
  String name = 'Du lịch',
  String createdAt = '2026-01-01T00:00:00.000',
}) {
  return database.insert('categories', <String, Object?>{
    'category_id': id,
    'company_id': companyId,
    'category_name': name,
    'category_type': 'EXPENSE',
    'icon_name': 'flight',
    'color_code': '#2196F3',
    'is_default': 1,
    'status': 'ACTIVE',
    'created_at': createdAt,
    'updated_at': createdAt,
    'is_synced': 0,
  });
}
