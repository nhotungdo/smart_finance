import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smart_finance/data/database/local_database.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  static const _profileRequestTimeout = Duration(seconds: 6);
  static const _sessionChangedMessage =
      'Phiên đăng nhập đã thay đổi. Vui lòng đăng nhập lại.';
  AuthRepository(this._supabase);

  static const _lockedAccountMessage =
      'Tài khoản đã bị quản lý khóa. Vui lòng liên hệ quản lý doanh nghiệp.';

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

    try {
      await _ensureAndCacheProfile(user);
    } catch (_) {
      await _supabase.auth.signOut();
      rethrow;
    }
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

    return getProfileForAuthUser(authUser);
  }

  Future<UserModel> getProfileForAuthUser(User authUser) async {
    _assertCurrentSession(authUser.id);

    try {
      final profile = await _ensureAndCacheProfile(authUser);
      _assertCurrentSession(authUser.id);
      return profile;
    } catch (error) {
      if (error is AuthException && error.message == _lockedAccountMessage) {
        rethrow;
      }
      _assertCurrentSession(authUser.id);
      debugPrint('Không thể tải profile cloud, dùng local cache: $error');
      final db = await LocalDatabase.instance.database;
      final rows = await db.query(
        'users',
        where: 'user_id = ?',
        whereArgs: [authUser.id],
        limit: 1,
      );
      if (rows.isEmpty) rethrow;
      final cachedProfile = UserModel.fromMap(rows.first);
      if (cachedProfile.status == RecordStatus.deleted) {
        throw const AuthException(_lockedAccountMessage);
      }
      _assertCurrentSession(authUser.id);
      return cachedProfile;
    }
  }

  Future<UserModel> _ensureAndCacheProfile(User authUser) async {
    _assertCurrentSession(authUser.id);
    Map<String, dynamic>? profile = await _supabase
        .from('users')
        .select()
        .eq('user_id', authUser.id)
        .maybeSingle()
        .timeout(_profileRequestTimeout);

    if (profile == null) {
      // Fallback cho tài khoản Auth cũ được tạo trước khi cài trigger.
      await _supabase
          .rpc('ensure_user_profile')
          .timeout(_profileRequestTimeout);
      profile = await _supabase
          .from('users')
          .select()
          .eq('user_id', authUser.id)
          .maybeSingle()
          .timeout(_profileRequestTimeout);
    }

    if (profile == null || profile['company_id'] == null) {
      throw const AuthException(
        'Tài khoản chưa có hồ sơ doanh nghiệp. Hãy chạy lại supabase_schema.sql.',
      );
    }

    if (RecordStatus.fromDatabase(profile['status']) == RecordStatus.deleted) {
      await _supabase.auth.signOut();
      throw const AuthException(_lockedAccountMessage);
    }

    final company = await _supabase
        .from('companies')
        .select()
        .eq('company_id', profile['company_id'])
        .maybeSingle()
        .timeout(_profileRequestTimeout);

    _assertCurrentSession(authUser.id);

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

  void _assertCurrentSession(String expectedUserId) {
    if (_supabase.auth.currentUser?.id != expectedUserId) {
      throw const AuthException(_sessionChangedMessage);
    }
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim().toLowerCase());
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
