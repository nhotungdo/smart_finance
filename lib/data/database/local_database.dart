import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();

  static Database? _database;
  static Future<Database>? _openingDatabase;

  LocalDatabase._init();

  Future<Database> get database async {
    final openedDatabase = _database;
    if (openedDatabase != null && openedDatabase.isOpen) {
      return openedDatabase;
    }

    final openingDatabase = _openingDatabase;
    if (openingDatabase != null) return openingDatabase;

    final future = _initDB('smart_finance');
    _openingDatabase = future;
    try {
      final database = await future;
      _database = database;
      return database;
    } finally {
      _openingDatabase = null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final path = kIsWeb ? filePath : join(await getDatabasesPath(), filePath);

    return await openDatabase(
      path,
      version: 10,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createOcrResultsTable(db);
      await _createPdfExportsTable(db);
    }
    if (oldVersion < 3) {
      await _migrateMoneyColumnsToInteger(db);
    }
    if (oldVersion < 4) {
      await _migrateEnumValues(db);
    }
    if (oldVersion < 5) {
      await _deduplicateCategories(db);
    }
    if (oldVersion < 6) {
      await db.execute('''
        ALTER TABLE invoices
        ADD COLUMN invoice_type TEXT NOT NULL DEFAULT 'EXPENSE'
          CHECK (invoice_type IN ('INCOME', 'EXPENSE'))
      ''');
    }
    if (oldVersion < 7) {
      await _addColumnIfMissing(
        db,
        table: 'ocr_results',
        column: 'is_synced',
        definition: 'INTEGER DEFAULT 0',
      );
      await _createSyncDeletionsTable(db);
      await _createPendingInvoiceImagesTable(db);
    }
    if (oldVersion < 8) {
      await _migrateRolesAndApprovals(db);
    }
    if (oldVersion < 9) {
      await _migrateSyncOwnership(db);
    }
    if (oldVersion < 10) {
      await _repairOcrTransactionCategories(db);
    }
    await _createIndexes(db);
  }

  Future<void> _repairOcrTransactionCategories(Database db) async {
    final rows = await db.rawQuery('''
      SELECT
        t.transaction_id,
        t.company_id,
        t.transaction_type,
        o.raw_mock_data
      FROM transactions t
      JOIN ocr_results o ON o.invoice_id = t.invoice_id
      WHERE t.status = 'ACTIVE'
        AND t.invoice_id IS NOT NULL
        AND t.category_id IS NULL
        AND o.raw_mock_data IS NOT NULL
    ''');

    for (final row in rows) {
      final rawMockData = row['raw_mock_data'] as String?;
      if (rawMockData == null || rawMockData.isEmpty) continue;

      Object? decoded;
      try {
        decoded = jsonDecode(rawMockData);
      } on FormatException {
        continue;
      }
      if (decoded is! Map<String, dynamic>) continue;

      final categoryName = decoded['category_name']?.toString().trim();
      if (categoryName == null || categoryName.isEmpty) continue;

      final categories = await db.query(
        'categories',
        columns: ['category_id'],
        where: '''
          company_id = ?
          AND category_type = ?
          AND LOWER(TRIM(category_name)) = LOWER(TRIM(?))
          AND status = 'ACTIVE'
        ''',
        whereArgs: [row['company_id'], row['transaction_type'], categoryName],
        limit: 1,
      );
      if (categories.isEmpty) continue;

      await db.update(
        'transactions',
        {
          'category_id': categories.first['category_id'],
          'updated_at': DateTime.now().toIso8601String(),
          'is_synced': 0,
        },
        where: 'transaction_id = ?',
        whereArgs: [row['transaction_id']],
      );
    }
  }

  Future<void> _migrateSyncOwnership(Database db) async {
    await _addColumnIfMissing(
      db,
      table: 'sync_deletions',
      column: 'company_id',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'sync_deletions',
      column: 'created_by',
      definition: 'TEXT',
    );

    // Kế toán không được sửa lại giao dịch đã được quản lý xử lý.
    // Các dòng này sẽ được PULL lại từ cloud khi đồng bộ.
    await db.execute('''
      UPDATE transactions
      SET is_synced = 1
      WHERE approval_status <> 'PENDING'
    ''');
  }

  Future<void> _migrateRolesAndApprovals(Database db) async {
    await db.insert('roles', {
      'role_id': 'role_manager',
      'role_name': 'MANAGER',
      'description': 'Quản lý',
      'is_synced': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('roles', {
      'role_id': 'role_accountant',
      'role_name': 'ACCOUNTANT',
      'description': 'Nhân viên kế toán',
      'is_synced': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.execute('''
      UPDATE users
      SET role_id = CASE
        WHEN role_id IN ('role_manager', 'role_01', 'role_02', 'role_09')
          THEN 'role_manager'
        ELSE 'role_accountant'
      END
    ''');
    await _addColumnIfMissing(
      db,
      table: 'invoices',
      column: 'created_by',
      definition: 'TEXT REFERENCES users(user_id)',
    );
    await db.execute(
      'UPDATE invoices SET created_by = uploaded_by WHERE created_by IS NULL',
    );
    await _addColumnIfMissing(
      db,
      table: 'transactions',
      column: 'approval_status',
      definition: "TEXT NOT NULL DEFAULT 'APPROVED'",
    );
    await _addColumnIfMissing(
      db,
      table: 'transactions',
      column: 'approved_by',
      definition: 'TEXT REFERENCES users(user_id)',
    );
    await _addColumnIfMissing(
      db,
      table: 'transactions',
      column: 'approved_at',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      db,
      table: 'transactions',
      column: 'rejection_reason',
      definition: 'TEXT',
    );
    await db.execute('''
      UPDATE transactions
      SET approval_status = CASE UPPER(COALESCE(approval_status, ''))
        WHEN 'PENDING' THEN 'PENDING'
        WHEN 'REJECTED' THEN 'REJECTED'
        ELSE 'APPROVED'
      END
    ''');
  }

  Future<void> _addColumnIfMissing(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((item) => item['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future<void> _migrateEnumValues(Database db) async {
    await db.execute('''
      UPDATE users
      SET status = CASE
        WHEN UPPER(status) = 'DELETED' THEN 'DELETED'
        ELSE 'ACTIVE'
      END
    ''');
    await db.execute('''
      UPDATE categories
      SET
        category_type = UPPER(category_type),
        status = CASE
          WHEN UPPER(status) = 'DELETED' THEN 'DELETED'
          ELSE 'ACTIVE'
        END
    ''');
    await db.execute('''
      UPDATE transactions
      SET
        transaction_type = UPPER(transaction_type),
        status = CASE
          WHEN UPPER(status) = 'DELETED' THEN 'DELETED'
          ELSE 'ACTIVE'
        END
    ''');
    await db.execute('''
      UPDATE invoices
      SET scan_status = CASE UPPER(scan_status)
        WHEN 'SCANNING' THEN 'SCANNING'
        WHEN 'SCANNED' THEN 'SCANNED'
        WHEN 'PROCESSED' THEN 'SCANNED'
        WHEN 'COMPLETED' THEN 'SCANNED'
        WHEN 'MANUAL' THEN 'SCANNED'
        WHEN 'ERROR' THEN 'ERROR'
        WHEN 'FAILED' THEN 'ERROR'
        ELSE 'NOT_SCANNED'
      END
    ''');
    await db.execute('''
      UPDATE ocr_results
      SET status = CASE UPPER(status)
        WHEN 'ERROR' THEN 'ERROR'
        WHEN 'FAILED' THEN 'ERROR'
        ELSE 'SCANNED'
      END
    ''');
  }

  Future<void> _migrateMoneyColumnsToInteger(Database db) async {
    await db.execute('''
      UPDATE transactions
      SET amount = CAST(ROUND(amount) AS INTEGER)
      WHERE amount IS NOT NULL
    ''');

    await db.execute('''
      UPDATE invoices
      SET
        subtotal = CAST(ROUND(subtotal) AS INTEGER),
        vat_rate = CAST(ROUND(vat_rate) AS INTEGER),
        vat_amount = CAST(ROUND(vat_amount) AS INTEGER),
        total_amount = CAST(ROUND(total_amount) AS INTEGER)
      WHERE subtotal IS NOT NULL
         OR vat_rate IS NOT NULL
         OR vat_amount IS NOT NULL
         OR total_amount IS NOT NULL
    ''');

    await db.execute('''
      UPDATE ocr_results
      SET extracted_amount = CAST(ROUND(extracted_amount) AS INTEGER)
      WHERE extracted_amount IS NOT NULL
    ''');
  }

  Future _createDB(Database db, int version) async {
    // Kích hoạt foreign keys
    await db.execute('PRAGMA foreign_keys = ON');

    // 1. COMPANY
    await db.execute('''
      CREATE TABLE companies (
        company_id TEXT PRIMARY KEY,
        company_name TEXT NOT NULL,
        tax_code TEXT,
        address TEXT,
        phone TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // 2. ROLE
    await db.execute('''
      CREATE TABLE roles (
        role_id TEXT PRIMARY KEY,
        role_name TEXT NOT NULL UNIQUE,
        description TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    await db.insert('roles', {
      'role_id': 'role_manager',
      'role_name': 'MANAGER',
      'description': 'Quản lý',
      'is_synced': 1,
    });
    await db.insert('roles', {
      'role_id': 'role_accountant',
      'role_name': 'ACCOUNTANT',
      'description': 'Nhân viên kế toán',
      'is_synced': 1,
    });

    // 3. USER
    await db.execute('''
      CREATE TABLE users (
        user_id TEXT PRIMARY KEY,
        company_id TEXT REFERENCES companies(company_id),
        role_id TEXT REFERENCES roles(role_id),
        full_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT,
        phone TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE'
          CHECK (status IN ('ACTIVE', 'DELETED')),
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // 4. CATEGORY
    await db.execute('''
      CREATE TABLE categories (
        category_id TEXT PRIMARY KEY,
        company_id TEXT REFERENCES companies(company_id),
        category_name TEXT NOT NULL,
        category_type TEXT NOT NULL
          CHECK (category_type IN ('INCOME', 'EXPENSE')),
        icon_name TEXT,
        color_code TEXT,
        is_default INTEGER DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'ACTIVE'
          CHECK (status IN ('ACTIVE', 'DELETED')),
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // 5. INVOICE
    await db.execute('''
      CREATE TABLE invoices (
        invoice_id TEXT PRIMARY KEY,
        company_id TEXT REFERENCES companies(company_id),
        uploaded_by TEXT REFERENCES users(user_id),
        created_by TEXT REFERENCES users(user_id),
        invoice_type TEXT NOT NULL DEFAULT 'EXPENSE'
          CHECK (invoice_type IN ('INCOME', 'EXPENSE')),
        supplier_name TEXT,
        supplier_tax_code TEXT,
        invoice_number TEXT,
        invoice_date TEXT,
        subtotal INTEGER,
        vat_rate INTEGER,
        vat_amount INTEGER,
        total_amount INTEGER,
        image_path TEXT,
        scan_status TEXT NOT NULL DEFAULT 'NOT_SCANNED'
          CHECK (scan_status IN ('NOT_SCANNED', 'SCANNING', 'SCANNED', 'ERROR')),
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // 6. TRANSACTION
    await db.execute('''
      CREATE TABLE transactions (
        transaction_id TEXT PRIMARY KEY,
        company_id TEXT REFERENCES companies(company_id),
        category_id TEXT REFERENCES categories(category_id),
        created_by TEXT REFERENCES users(user_id),
        invoice_id TEXT REFERENCES invoices(invoice_id),
        amount INTEGER NOT NULL,
        transaction_type TEXT NOT NULL
          CHECK (transaction_type IN ('INCOME', 'EXPENSE')),
        transaction_date TEXT NOT NULL,
        description TEXT,
        receipt_image_path TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE'
          CHECK (status IN ('ACTIVE', 'DELETED')),
        approval_status TEXT NOT NULL DEFAULT 'PENDING'
          CHECK (approval_status IN ('PENDING', 'APPROVED', 'REJECTED')),
        approved_by TEXT REFERENCES users(user_id),
        approved_at TEXT,
        rejection_reason TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // 7. OCR_RESULT & 8. PDF_EXPORT
    await _createOcrResultsTable(db);
    await _createPdfExportsTable(db);
    await _createSyncDeletionsTable(db);
    await _createPendingInvoiceImagesTable(db);
    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS transactions_one_active_invoice_idx
      ON transactions(invoice_id)
      WHERE invoice_id IS NOT NULL AND status = 'ACTIVE'
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS transactions_company_approval_idx
      ON transactions(company_id, approval_status, transaction_date DESC)
      WHERE status = 'ACTIVE'
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS categories_company_name_type_active_idx
      ON categories(
        COALESCE(company_id, ''),
        LOWER(TRIM(category_name)),
        category_type
      )
      WHERE status = 'ACTIVE'
    ''');
  }

  Future<void> _deduplicateCategories(Database db) async {
    final rows = await db.query(
      'categories',
      where: "status = 'ACTIVE'",
      orderBy: 'created_at ASC, category_id ASC',
    );
    final canonicalIds = <String, String>{};

    for (final row in rows) {
      final categoryId = row['category_id'] as String;
      final companyId = row['company_id'] as String? ?? '';
      final name = (row['category_name'] as String).trim().toLowerCase();
      final type = (row['category_type'] as String).toUpperCase();
      final key = '$companyId\u0000$name\u0000$type';
      final canonicalId = canonicalIds[key];

      if (canonicalId == null) {
        canonicalIds[key] = categoryId;
        continue;
      }

      await db.update(
        'transactions',
        {'category_id': canonicalId, 'is_synced': 0},
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
      await db.delete(
        'categories',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
    }
  }

  Future<void> _createOcrResultsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ocr_results (
        ocr_result_id TEXT PRIMARY KEY,
        invoice_id TEXT REFERENCES invoices(invoice_id) ON DELETE CASCADE,
        extracted_supplier_name TEXT,
        extracted_tax_code TEXT,
        extracted_amount INTEGER,
        raw_mock_data TEXT,
        status TEXT NOT NULL DEFAULT 'SCANNED'
          CHECK (status IN ('NOT_SCANNED', 'SCANNING', 'SCANNED', 'ERROR')),
        scanned_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createPdfExportsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pdf_exports (
        pdf_export_id TEXT PRIMARY KEY,
        company_id TEXT REFERENCES companies(company_id),
        exported_by TEXT REFERENCES users(user_id),
        invoice_id TEXT REFERENCES invoices(invoice_id),
        export_type TEXT NOT NULL,
        file_path TEXT NOT NULL,
        exported_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createSyncDeletionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_deletions (
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        company_id TEXT,
        created_by TEXT,
        created_at TEXT NOT NULL,
        PRIMARY KEY (table_name, record_id)
      )
    ''');
  }

  Future<void> _createPendingInvoiceImagesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_invoice_images (
        invoice_id TEXT PRIMARY KEY,
        company_id TEXT NOT NULL,
        file_name TEXT NOT NULL,
        image_bytes BLOB NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    final openingDatabase = _openingDatabase;
    final db =
        _database ?? (openingDatabase == null ? null : await openingDatabase);
    _database = null;
    _openingDatabase = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }
}
