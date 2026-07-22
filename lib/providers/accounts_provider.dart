import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/user_model.dart';
import 'package:smart_finance/data/repositories/account_repository.dart';
import 'package:smart_finance/providers/auth_provider.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});

final accountsProvider =
    AsyncNotifierProvider<AccountsNotifier, List<UserModel>>(
      AccountsNotifier.new,
    );

class AccountsNotifier extends AsyncNotifier<List<UserModel>> {
  @override
  FutureOr<List<UserModel>> build() async {
    final profile = await ref.watch(currentUserProfileProvider.future);
    return _fetchAccountsFor(profile);
  }

  Future<List<UserModel>> _fetchAccounts() async {
    final profile = await ref.read(currentUserProfileProvider.future);
    return _fetchAccountsFor(profile);
  }

  Future<List<UserModel>> _fetchAccountsFor(UserModel? profile) async {
    if (profile == null || !profile.isManager || profile.companyId == null) {
      return [];
    }
    return ref
        .read(accountRepositoryProvider)
        .getCompanyUsers(profile.companyId!);
  }

  Future<void> updateRole(UserModel account, AppRole role) async {
    final manager = await _requireManager();
    if (account.userId == manager.userId) {
      throw StateError('Không thể tự thay đổi vai trò của chính mình.');
    }
    await ref
        .read(accountRepositoryProvider)
        .updateRole(
          userId: account.userId,
          companyId: manager.companyId!,
          role: role,
        );
    await _reload();
  }

  Future<void> createAccount({
    required String fullName,
    required String email,
    required String password,
    required AppRole role,
  }) async {
    await _requireManager();
    await ref
        .read(accountRepositoryProvider)
        .createCompanyUser(
          fullName: fullName,
          email: email,
          password: password,
          role: role,
        );
    await _reload();
  }

  Future<void> updateStatus(UserModel account, RecordStatus status) async {
    final manager = await _requireManager();
    if (account.userId == manager.userId) {
      throw StateError('Không thể tự khóa tài khoản của chính mình.');
    }
    await ref
        .read(accountRepositoryProvider)
        .updateStatus(
          userId: account.userId,
          companyId: manager.companyId!,
          status: status,
        );
    await _reload();
  }

  Future<UserModel> _requireManager() async {
    final profile = await ref.read(currentUserProfileProvider.future);
    if (profile == null || !profile.isManager || profile.companyId == null) {
      throw StateError('Chỉ quản lý mới được quản lý tài khoản.');
    }
    return profile;
  }

  Future<void> _reload() async {
    try {
      state = AsyncData(await _fetchAccounts());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
