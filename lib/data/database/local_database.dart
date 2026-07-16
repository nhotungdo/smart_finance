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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createOcrResultsTable(db);
      await _createPdfExportsTable(db);
    }
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
        status TEXT DEFAULT 'active',
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
        category_type TEXT NOT NULL,
        icon_name TEXT,
        color_code TEXT,
        is_default INTEGER DEFAULT 0,
        status TEXT DEFAULT 'active',
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
        subtotal REAL,
        vat_rate REAL,
        vat_amount REAL,
        total_amount REAL,
        image_path TEXT,
        scan_status TEXT DEFAULT 'pending',
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
        amount REAL NOT NULL,
        transaction_type TEXT NOT NULL,
        transaction_date TEXT NOT NULL,
        description TEXT,
        receipt_image_path TEXT,
        status TEXT DEFAULT 'completed',
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // 7. OCR_RESULT & 8. PDF_EXPORT
    await _createOcrResultsTable(db);
    await _createPdfExportsTable(db);
  }

  Future<void> _createOcrResultsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ocr_results (
        ocr_result_id TEXT PRIMARY KEY,
        invoice_id TEXT REFERENCES invoices(invoice_id) ON DELETE CASCADE,
        extracted_supplier_name TEXT,
        extracted_tax_code TEXT,
        extracted_amount REAL,
        raw_mock_data TEXT,
        status TEXT DEFAULT 'processed',
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
