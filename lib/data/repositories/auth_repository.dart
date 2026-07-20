import 'package:flutter/foundation.dart';
import 'package:smart_finance/data/database/local_database.dart';
import 'package:smart_finance/data/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._supabase);

  final SupabaseClient _supabase;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Đăng nhập không thành công.');
    }

    await _ensureAndCacheProfile(user);
    return response;
  }

  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required String businessName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'business_name': businessName.trim(),
      },
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Đăng ký không thành công.');
    }

    // Khi tắt xác nhận email, signUp trả session và profile có thể cache ngay.
    // Khi bật xác nhận email, database trigger vẫn tạo profile; app sẽ cache
    // profile ở lần đăng nhập đầu tiên sau xác nhận.
    if (response.session != null) {
      await _ensureAndCacheProfile(user);
    }

    return response;
  }

  Future<UserModel?> getCurrentProfile() async {
    final authUser = currentUser;
    if (authUser == null) return null;

    try {
      return await _ensureAndCacheProfile(authUser);
    } catch (error) {
      debugPrint('Không thể tải profile cloud, dùng local cache: $error');
      final db = await LocalDatabase.instance.database;
      final rows = await db.query(
        'users',
        where: 'user_id = ?',
        whereArgs: [authUser.id],
        limit: 1,
      );
      if (rows.isEmpty) rethrow;
      return UserModel.fromMap(rows.first);
    }
  }

  Future<UserModel> _ensureAndCacheProfile(User authUser) async {
    Map<String, dynamic>? profile = await _supabase
        .from('users')
        .select()
        .eq('user_id', authUser.id)
        .maybeSingle();

    if (profile == null) {
      // Fallback cho tài khoản Auth cũ được tạo trước khi cài trigger.
      await _supabase.rpc('ensure_user_profile');
      profile = await _supabase
          .from('users')
          .select()
          .eq('user_id', authUser.id)
          .maybeSingle();
    }

    if (profile == null || profile['company_id'] == null) {
      throw const AuthException(
        'Tài khoản chưa có hồ sơ doanh nghiệp. Hãy chạy lại supabase_schema.sql.',
      );
    }

    final company = await _supabase
        .from('companies')
        .select()
        .eq('company_id', profile['company_id'])
        .maybeSingle();

    if (company == null) {
      throw const AuthException('Không tìm thấy doanh nghiệp của tài khoản.');
    }

    final db = await LocalDatabase.instance.database;
    await db.transaction((txn) async {
      await txn.insert('companies', {
        ...company,
        'is_synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('users', {
        ...profile!,
        'password_hash': null,
        'is_synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });

    return UserModel.fromMap({...profile, 'is_synced': 1});
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim().toLowerCase());
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
