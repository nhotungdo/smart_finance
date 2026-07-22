import 'package:smart_finance/data/database/local_database.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountRepository {
  AccountRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<UserModel> createCompanyUser({
    required String fullName,
    required String email,
    required String password,
    required AppRole role,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-company-user',
        body: {
          'full_name': fullName.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'role_id': role.roleId,
        },
      );
      final data = response.data;
      if (data is! Map || data['account'] is! Map) {
        throw StateError('Máy chủ trả về dữ liệu tài khoản không hợp lệ.');
      }

      final account = UserModel.fromMap({
        ...Map<String, dynamic>.from(data['account'] as Map),
        'is_synced': 1,
      });
      final db = await LocalDatabase.instance.database;
      await db.insert(
        'users',
        account.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return account;
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] is String) {
        throw StateError(details['error'] as String);
      }
      throw StateError(
        'Không thể tạo tài khoản nhân viên. Hãy kiểm tra Edge Function đã được triển khai.',
      );
    }
  }

  Future<List<UserModel>> getCompanyUsers(String companyId) async {
    final db = await LocalDatabase.instance.database;
    try {
      final rows = await _supabase
          .from('users')
          .select()
          .eq('company_id', companyId)
          .order('full_name');
      final users = rows
          .map<UserModel>((row) => UserModel.fromMap({...row, 'is_synced': 1}))
          .toList();
      await db.transaction((txn) async {
        for (final user in users) {
          await txn.insert(
            'users',
            user.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      return users;
    } catch (_) {
      final rows = await db.query(
        'users',
        where: 'company_id = ?',
        whereArgs: [companyId],
        orderBy: 'full_name',
      );
      return rows.map(UserModel.fromMap).toList();
    }
  }

  Future<void> updateRole({
    required String userId,
    required String companyId,
    required AppRole role,
  }) async {
    await _supabase
        .from('users')
        .update({
          'role_id': role.roleId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('company_id', companyId);
    final db = await LocalDatabase.instance.database;
    await db.update(
      'users',
      {
        'role_id': role.roleId,
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 1,
      },
      where: 'user_id = ? AND company_id = ?',
      whereArgs: [userId, companyId],
    );
  }

  Future<void> updateStatus({
    required String userId,
    required String companyId,
    required RecordStatus status,
  }) async {
    await _supabase
        .from('users')
        .update({
          'status': status.databaseValue,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('company_id', companyId);
    final db = await LocalDatabase.instance.database;
    await db.update(
      'users',
      {
        'status': status.databaseValue,
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 1,
      },
      where: 'user_id = ? AND company_id = ?',
      whereArgs: [userId, companyId],
    );
  }
}
