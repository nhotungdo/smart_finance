import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/repositories/sync_repository.dart';

/// Trạng thái của BackgroundSyncService
enum SyncStatus {
  idle, // Đang chờ
  syncing, // Đang đồng bộ
  success, // Sync thành công lần cuối
  error, // Có lỗi trong lần sync cuối
}

/// Điều phối một lần đồng bộ do người dùng chủ động yêu cầu.
class BackgroundSyncService {
  final SyncRepository _syncRepo;

  BackgroundSyncService({SyncRepository? syncRepo})
    : _syncRepo = syncRepo ?? SyncRepository();

  // ── Internal State ────────────────────────────────────────────────────────
  bool _isSyncing = false;
  SyncStatus _status = SyncStatus.idle;
  String? _lastError;
  DateTime? _lastSyncTime;

  // ── Getters ───────────────────────────────────────────────────────────────
  SyncStatus get status => _status;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isSyncing => _isSyncing;

  /// Chỉ chạy khi người dùng nhấn nút đồng bộ.
  Future<SyncResult?> triggerManualSync() async {
    debugPrint('[BackgroundSyncService] Sync thủ công được kích hoạt.');
    return _doSync();
  }

  /// Thực hiện đồng bộ thực sự.
  Future<SyncResult?> _doSync() async {
    if (_isSyncing) return null;

    _isSyncing = true;
    _setStatus(SyncStatus.syncing);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _isSyncing = false;
        _setStatus(SyncStatus.idle);
        return null;
      }

      // Lấy companyId từ Supabase (nếu có)
      String? companyId;
      var role = AppRole.accountant;
      try {
        final userData = await Supabase.instance.client
            .from('users')
            .select('company_id, role_id')
            .eq('user_id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 3));
        companyId = userData?['company_id'] as String?;
        role = AppRole.fromRoleId(userData?['role_id']);
      } catch (_) {
        // Lỗi profile được báo rõ bên dưới, không đẩy dữ liệu thiếu phạm vi.
      }

      if (companyId == null) {
        throw StateError('Tài khoản chưa có hồ sơ doanh nghiệp để đồng bộ.');
      }

      final result = await _syncRepo.sync(
        companyId: companyId,
        userId: user.id,
        role: role,
      );

      _lastSyncTime = DateTime.now();
      _lastError = null;

      if (result.hasErrors) {
        _setStatus(SyncStatus.error, result.errors.join('; '));
        debugPrint('[BackgroundSyncService] Sync có lỗi: ${result.errors}');
      } else {
        _setStatus(SyncStatus.success);
        debugPrint('[BackgroundSyncService] Sync thành công: $result');
      }
      return result;
    } catch (e) {
      _lastError = e.toString();
      _setStatus(SyncStatus.error, _lastError);
      debugPrint('[BackgroundSyncService] ✗ Lỗi nghiêm trọng khi sync: $e');
      return null;
    } finally {
      _isSyncing = false;
    }
  }

  void _setStatus(SyncStatus status, [String? error]) {
    _status = status;
    _lastError = error;
  }
}
