import 'package:smart_finance/data/database/local_database.dart';
import 'package:smart_finance/data/models/category_model.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:sqflite/sqflite.dart';

class CategoryRepository {
  CategoryRepository({Future<Database> Function()? databaseProvider})
    : _databaseProvider =
          databaseProvider ?? (() => LocalDatabase.instance.database);

  final Future<Database> Function() _databaseProvider;

  Future<void> seedDefaultCategories(String companyId) async {
    final db = await _databaseProvider();
    await db.transaction((txn) async {
      await _deduplicateCompanyCategories(txn, companyId);

      final now = DateTime.now();
      final defaultCategories = [
        CategoryModel(
          categoryId: _defaultCategoryId(companyId, 'expense:food'),
          companyId: companyId,
          categoryName: 'Ăn uống',
          categoryType: TransactionType.expense,
          iconName: 'restaurant',
          colorCode: '#F44336',
          isDefault: true,
          createdAt: now,
          updatedAt: now,
        ),
        CategoryModel(
          categoryId: _defaultCategoryId(companyId, 'expense:travel'),
          companyId: companyId,
          categoryName: 'Du lịch',
          categoryType: TransactionType.expense,
          iconName: 'flight',
          colorCode: '#2196F3',
          isDefault: true,
          createdAt: now,
          updatedAt: now,
        ),
        CategoryModel(
          categoryId: _defaultCategoryId(companyId, 'expense:office'),
          companyId: companyId,
          categoryName: 'Văn phòng',
          categoryType: TransactionType.expense,
          iconName: 'computer',
          colorCode: '#4CAF50',
          isDefault: true,
          createdAt: now,
          updatedAt: now,
        ),
        CategoryModel(
          categoryId: _defaultCategoryId(companyId, 'expense:fuel'),
          companyId: companyId,
          categoryName: 'Xăng xe',
          categoryType: TransactionType.expense,
          iconName: 'local_gas_station',
          colorCode: '#FF9800',
          isDefault: true,
          createdAt: now,
          updatedAt: now,
        ),
        CategoryModel(
          categoryId: _defaultCategoryId(companyId, 'expense:salary'),
          companyId: companyId,
          categoryName: 'Lương',
          categoryType: TransactionType.expense,
          iconName: 'payments',
          colorCode: '#E11D48',
          isDefault: true,
          createdAt: now,
          updatedAt: now,
        ),
        CategoryModel(
          categoryId: _defaultCategoryId(companyId, 'income:sales'),
          companyId: companyId,
          categoryName: 'Doanh thu bán hàng',
          categoryType: TransactionType.income,
          iconName: 'attach_money',
          colorCode: '#8BC34A',
          isDefault: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      for (final category in defaultCategories) {
        await _canonicalizeDefaultCategory(txn, category);
      }
    });
  }

  String _defaultCategoryId(String companyId, String key) {
    return 'default:$companyId:$key';
  }

  Future<void> _canonicalizeDefaultCategory(
    DatabaseExecutor db,
    CategoryModel category,
  ) async {
    final isSalaryCategory =
        category.categoryType == TransactionType.expense &&
        category.categoryName == 'Lương';
    final matchingRows = await db.query(
      'categories',
      where: isSalaryCategory
          ? '''
        company_id = ?
        AND (
          LOWER(TRIM(category_name)) = LOWER(TRIM(?))
          OR TRIM(category_name) IN ('Tiền lương', 'tiền lương')
        )
        AND category_type = ?
        AND status = 'ACTIVE'
      '''
          : '''
        company_id = ?
        AND LOWER(TRIM(category_name)) = LOWER(TRIM(?))
        AND category_type = ?
        AND status = 'ACTIVE'
      ''',
      whereArgs: [
        category.companyId,
        category.categoryName,
        category.categoryType.databaseValue,
      ],
      orderBy: 'created_at ASC, category_id ASC',
    );
    final canonicalRows = await db.query(
      'categories',
      where: 'category_id = ?',
      whereArgs: [category.categoryId],
      limit: 1,
    );

    final legacyRows = matchingRows.where(
      (row) => row['category_id'] != category.categoryId,
    );
    for (final row in legacyRows) {
      await db.update(
        'categories',
        {
          'status': RecordStatus.deleted.databaseValue,
          'updated_at': DateTime.now().toIso8601String(),
          'is_synced': 0,
        },
        where: 'category_id = ?',
        whereArgs: [row['category_id']],
      );
    }

    if (canonicalRows.isEmpty) {
      await db.insert(
        'categories',
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } else {
      final current = canonicalRows.first;
      final needsUpdate =
          current['company_id'] != category.companyId ||
          current['category_name'] != category.categoryName ||
          current['category_type'] != category.categoryType.databaseValue ||
          current['icon_name'] != category.iconName ||
          current['color_code'] != category.colorCode ||
          current['is_default'] != 1 ||
          current['status'] != RecordStatus.active.databaseValue;
      if (needsUpdate) {
        await db.update(
          'categories',
          {
            'company_id': category.companyId,
            'category_name': category.categoryName,
            'category_type': category.categoryType.databaseValue,
            'icon_name': category.iconName,
            'color_code': category.colorCode,
            'is_default': 1,
            'status': RecordStatus.active.databaseValue,
            'updated_at': DateTime.now().toIso8601String(),
            'is_synced': 0,
          },
          where: 'category_id = ?',
          whereArgs: [category.categoryId],
        );
      }
    }

    for (final row in legacyRows) {
      final oldId = row['category_id'] as String;
      await db.update(
        'transactions',
        {'category_id': category.categoryId, 'is_synced': 0},
        where: 'category_id = ?',
        whereArgs: [oldId],
      );
      await db.delete(
        'categories',
        where: 'category_id = ?',
        whereArgs: [oldId],
      );
    }
  }

  Future<List<CategoryModel>> getCategories({String? companyId}) async {
    final db = await _databaseProvider();
    final result = await db.query(
      'categories',
      where: companyId != null
          ? '''
            status = 'ACTIVE'
            AND (company_id = ? OR (company_id IS NULL AND is_default = 1))
            '''
          : "status = 'ACTIVE'",
      whereArgs: companyId != null ? [companyId] : null,
      orderBy: 'category_name ASC',
    );
    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<void> addCategory(CategoryModel category) async {
    final db = await _databaseProvider();
    await db.insert('categories', category.toMap());
  }

  // --- Sync Methods ---

  Future<List<CategoryModel>> getUnsyncedCategories({
    required String companyId,
  }) async {
    final db = await _databaseProvider();
    final result = await db.query(
      'categories',
      where: 'is_synced = 0 AND company_id = ?',
      whereArgs: [companyId],
    );
    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<void> markAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _databaseProvider();
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'categories',
      {'is_synced': 1},
      where: 'category_id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<void> upsertCategoryFromCloud(CategoryModel cloudCategory) async {
    final db = await _databaseProvider();

    // Conflict resolution
    final localMaps = await db.query(
      'categories',
      where: 'category_id = ?',
      whereArgs: [cloudCategory.categoryId],
      limit: 1,
    );

    if (localMaps.isNotEmpty) {
      final localCategory = CategoryModel.fromMap(localMaps.first);
      if (!localCategory.isSynced &&
          localCategory.updatedAt != null &&
          cloudCategory.updatedAt != null &&
          localCategory.updatedAt!.isAfter(cloudCategory.updatedAt!)) {
        return; // Bỏ qua, không ghi đè bản ghi local mới hơn
      }
    }

    final map = cloudCategory.toMap();
    map['is_synced'] = 1; // Always mark as synced when pulling from cloud
    await db.insert(
      'categories',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _deduplicateCompanyCategories(
    DatabaseExecutor db,
    String companyId,
  ) async {
    final rows = await db.query(
      'categories',
      where: "company_id = ? AND status = 'ACTIVE'",
      whereArgs: [companyId],
      orderBy: 'created_at ASC, category_id ASC',
    );
    final canonicalIds = <String, String>{};

    for (final row in rows) {
      final categoryId = row['category_id'] as String;
      final name = (row['category_name'] as String).trim().toLowerCase();
      final type = (row['category_type'] as String).toUpperCase();
      final key = '$name\u0000$type';
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
}
