import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_finance/data/database/local_database.dart';
import 'package:sqflite/sqflite.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // Get current user stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Login with Email/Password and sync profile to Local Database
  Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user != null) {
      try {
        // Fetch User Profile from Supabase
        final userData = await _supabase
            .from('users')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

        if (userData != null) {
          final companyId = userData['company_id'];

          // Fetch Company from Supabase
          final companyData = await _supabase
              .from('companies')
              .select()
              .eq('company_id', companyId)
              .maybeSingle();

          final localDb = await LocalDatabase.instance.database;

          // Sync Company to Local DB
          if (companyData != null) {
            await localDb.insert(
              'companies',
              {
                ...companyData,
                'is_synced': 1,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          // Sync User to Local DB
          await localDb.insert(
            'users',
            {
              ...userData,
              'is_synced': 1,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      } catch (e) {
        debugPrint('Error syncing profile to local DB during login: $e');
        // We don't rethrow here because the login itself was successful
      }
    }

    return response;
  }

  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required String businessName,
  }) async {
    // 0. Check if email already exists in local database
    final localDb = await LocalDatabase.instance.database;
    final existingUser = await localDb.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (existingUser.isNotEmpty) {
      throw const AuthException('Tài khoản email đã tồn tại trong hệ thống cục bộ. Vui lòng đăng nhập.');
    }

    // 1. SignUp with Supabase Auth
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'business_name': businessName,
      },
    );

    final user = authResponse.user;
    if (user == null) {
      throw const AuthException('Đăng ký không thành công.');
    }

    try {
      // 2. Create Company on Supabase
      final companyData = await _supabase.from('companies').insert({
        'company_name': businessName,
      }).select().single();

      final companyId = companyData['company_id'];

      // 3. Create User Profile on Supabase
      await _supabase.from('users').insert({
        'user_id': user.id,
        'company_id': companyId,
        'full_name': fullName,
        'email': email,
        'status': 'active',
      });

      // 4. Save to Local Database
      final nowStr = DateTime.now().toIso8601String();
      
      await localDb.insert('companies', {
        'company_id': companyId,
        'company_name': businessName,
        'created_at': nowStr,
        'updated_at': nowStr,
        'is_synced': 1,
      });

      await localDb.insert('users', {
        'user_id': user.id,
        'company_id': companyId,
        'full_name': fullName,
        'email': email,
        'status': 'active',
        'created_at': nowStr,
        'updated_at': nowStr,
        'is_synced': 1,
      });
      
    } catch (e) {
      debugPrint('Error inserting profile data during registration: $e');
      // If the email requires confirmation, session is null, and RLS blocks insert.
      // In this case, the Auth user is created, but profiles aren't.
      if (authResponse.session == null) {
        throw const AuthException('Đăng ký thành công! Vui lòng kiểm tra Email để xác thực tài khoản.');
      } else {
        rethrow;
      }
    }

    return authResponse;
  }

  // Gửi email đặt lại mật khẩu qua Supabase Auth
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
