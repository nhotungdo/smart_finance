import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();

  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('smart_finance');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final path = kIsWeb ? filePath : join(await getDatabasesPath(), filePath);

    return await openDatabase(
      path,
      version: 4,
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
      await _createIndexes(db);
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
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // 7. OCR_RESULT & 8. PDF_EXPORT
    await _createOcrResultsTable(db);
    await _createPdfExportsTable(db);
    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS transactions_one_active_invoice_idx
      ON transactions(invoice_id)
      WHERE invoice_id IS NOT NULL AND status = 'ACTIVE'
    ''');
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
        scanned_at TEXT
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

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
