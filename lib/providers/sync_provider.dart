import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/data/repositories/sync_repository.dart';
import 'package:smart_finance/data/services/background_sync_service.dart';
import 'package:smart_finance/providers/categories_provider.dart';
import 'package:smart_finance/providers/auth_provider.dart';
import 'package:smart_finance/providers/transactions_provider.dart';
import 'package:smart_finance/providers/invoices_provider.dart';
import 'package:smart_finance/providers/network_status_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// PROVIDERS
// ──────────────────────────────────────────────────────────────────────────────

/// Provider cho SyncRepository — singleton dùng chung toàn app.
final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository();
});

/// Provider cho dịch vụ chỉ chạy khi người dùng yêu cầu đồng bộ.
final backgroundSyncServiceProvider = Provider<BackgroundSyncService>((ref) {
  final syncRepo = ref.read(syncRepositoryProvider);
  return BackgroundSyncService(syncRepo: syncRepo);
});

/// Provider cho số dòng chưa đồng bộ — dùng hiển thị badge/indicator trên UI.
final unsyncedCountProvider = FutureProvider<int>((ref) async {
  final profile = await ref.watch(currentUserProfileProvider.future);
  if (profile?.companyId == null) return 0;
  final repo = ref.read(syncRepositoryProvider);
  return repo.countUnsynced(
    companyId: profile!.companyId!,
    userId: profile.userId,
    role: profile.role,
  );
});

final networkCheckTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 2),
);

final manualSyncTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 10),
);

final offlineSyncFeedbackDelayProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 3),
);

// ──────────────────────────────────────────────────────────────────────────────
// MANUAL SYNC NOTIFIER
// ──────────────────────────────────────────────────────────────────────────────

/// State của một lần sync thủ công.
class SyncState {
  final bool isLoading;
  final SyncResult? lastResult;
  final String? error;

  const SyncState({this.isLoading = false, this.lastResult, this.error});

  SyncState copyWith({bool? isLoading, SyncResult? lastResult, String? error}) {
    return SyncState(
      isLoading: isLoading ?? this.isLoading,
      lastResult: lastResult ?? this.lastResult,
      error: error,
    );
  }
}

/// [SyncNotifier] — Điều phối đồng bộ thủ công từ các nút trên UI.
class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncState();

  Future<bool> _canStartSync() async {
    final startedAt = DateTime.now();
    try {
      final checkNetwork = ref.read(networkStatusCheckerProvider);
      final networkStatus = await checkNetwork().timeout(
        ref.read(networkCheckTimeoutProvider),
      );
      if (networkStatus == NetworkStatus.offline) {
        await _finishNetworkCheckFailure(
          startedAt,
          'Không có kết nối mạng, không thể đồng bộ.',
        );
        return false;
      }
      return true;
    } on TimeoutException {
      await _finishNetworkCheckFailure(
        startedAt,
        'Không thể kiểm tra kết nối mạng. Vui lòng thử lại.',
      );
      return false;
    } catch (_) {
      await _finishNetworkCheckFailure(
        startedAt,
        'Không thể xác định trạng thái mạng. Vui lòng thử lại.',
      );
      return false;
    }
  }

  Future<void> _finishNetworkCheckFailure(
    DateTime startedAt,
    String message,
  ) async {
    final minimumDelay = ref.read(offlineSyncFeedbackDelayProvider);
    final remaining = minimumDelay - DateTime.now().difference(startedAt);
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    state = state.copyWith(isLoading: false, error: message);
  }

  /// Kích hoạt sync đầy đủ (PUSH + PULL) từ UI.
  Future<void> syncNow() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    if (!await _canStartSync()) return;

    try {
      final bgService = ref.read(backgroundSyncServiceProvider);
      final result = await bgService.triggerManualSync().timeout(
        ref.read(manualSyncTimeoutProvider),
      );

      if (bgService.status == SyncStatus.error) {
        state = state.copyWith(
          isLoading: false,
          error: bgService.lastError ?? 'Máy chủ không thể đồng bộ dữ liệu.',
        );
        return;
      }
      if (result == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Không thể bắt đầu đồng bộ. Vui lòng đăng nhập lại.',
        );
        return;
      }

      // Sau khi sync xong, lấy kết quả từ syncRepo để báo cáo
      final repo = ref.read(syncRepositoryProvider);
      final profile = await ref.read(currentUserProfileProvider.future);
      if (profile?.companyId == null) {
        throw StateError('Tài khoản chưa có hồ sơ doanh nghiệp.');
      }
      final unsyncedCount = await repo.countUnsynced(
        companyId: profile!.companyId!,
        userId: profile.userId,
        role: profile.role,
      );

      state = state.copyWith(
        isLoading: false,
        lastResult: result,
        // Nếu unsyncedCount == 0 → tất cả đã sync
        error: unsyncedCount > 0
            ? 'Còn $unsyncedCount dòng chưa đồng bộ'
            : null,
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        error: 'Máy chủ phản hồi quá chậm. Vui lòng thử lại.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Không thể đồng bộ: $e');
    } finally {
      // Làm mới các provider UI sau khi sync
      ref.invalidate(unsyncedCountProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(invoicesProvider);
    }
  }

  /// Chỉ PUSH dữ liệu local chưa đồng bộ (nhanh hơn full sync).
  Future<void> pushPending() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    if (!await _canStartSync()) return;

    try {
      final profile = await ref.read(currentUserProfileProvider.future);
      if (profile?.companyId == null) {
        throw StateError('Tài khoản chưa có hồ sơ doanh nghiệp.');
      }
      final repo = ref.read(syncRepositoryProvider);
      final result = await repo
          .pushOnly(
            companyId: profile!.companyId!,
            userId: profile.userId,
            role: profile.role,
          )
          .timeout(ref.read(manualSyncTimeoutProvider));

      state = state.copyWith(
        isLoading: false,
        lastResult: result,
        error: result.hasErrors ? result.errors.join('\n') : null,
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        error: 'Máy chủ phản hồi quá chậm. Vui lòng thử lại.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Không thể đồng bộ: $e');
    } finally {
      ref.invalidate(unsyncedCountProvider);
    }
  }
}

/// Provider chính cho màn hình sync — dùng `ref.watch(syncNotifierProvider)`.
final syncNotifierProvider = NotifierProvider<SyncNotifier, SyncState>(() {
  return SyncNotifier();
});

// ──────────────────────────────────────────────────────────────────────────────
// LEGACY COMPATIBILITY
// (Giữ lại để không break các file cũ đang import syncProvider)
// ──────────────────────────────────────────────────────────────────────────────

/// @deprecated Dùng [syncNotifierProvider] thay thế.
final syncProvider = syncNotifierProvider;
