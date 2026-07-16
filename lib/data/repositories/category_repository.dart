import 'package:smart_finance/data/database/local_database.dart';
import 'package:smart_finance/data/models/category_model.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

class CategoryRepository {
  final LocalDatabase _db = LocalDatabase.instance;
  final _uuid = const Uuid();

  Future<void> seedDefaultCategories(String companyId) async {
    final db = await _db.database;
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM categories WHERE company_id = ? OR company_id IS NULL',
            [companyId],
          ),
        ) ??
        0;

    if (count == 0) {
      final now = DateTime.now();
      final defaultCategories = [
        CategoryModel(
          categoryId: _uuid.v4(),
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
          categoryId: _uuid.v4(),
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
          categoryId: _uuid.v4(),
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
          categoryId: _uuid.v4(),
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
          categoryId: _uuid.v4(),
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

      final batch = db.batch();
      for (var cat in defaultCategories) {
        batch.insert('categories', cat.toMap());
      }
      await batch.commit(noResult: true);
    }
  }

  Future<List<CategoryModel>> getCategories({String? companyId}) async {
    final db = await _db.database;
    final result = await db.query(
      'categories',
      where: companyId != null ? 'company_id = ? OR is_default = 1' : null,
      whereArgs: companyId != null ? [companyId] : null,
      orderBy: 'category_name ASC',
    );
    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<void> addCategory(CategoryModel category) async {
    final db = await _db.database;
    await db.insert('categories', category.toMap());
  }

  // --- Sync Methods ---

  Future<List<CategoryModel>> getUnsyncedCategories() async {
    final db = await _db.database;
    final result = await db.query('categories', where: 'is_synced = 0');
    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<void> markAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _db.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'categories',
      {'is_synced': 1},
      where: 'category_id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<void> upsertCategoryFromCloud(CategoryModel cloudCategory) async {
    final db = await _db.database;

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
}
