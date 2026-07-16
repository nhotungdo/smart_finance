import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/data/repositories/sync_repository.dart';
import 'package:smart_finance/data/services/background_sync_service.dart';
import 'package:smart_finance/providers/categories_provider.dart';
import 'package:smart_finance/providers/transactions_provider.dart';
import 'package:smart_finance/providers/invoices_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// PROVIDERS
// ──────────────────────────────────────────────────────────────────────────────

/// Provider cho SyncRepository — singleton dùng chung toàn app.
final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository();
});

// ──────────────────────────────────────────────────────────────────────────────
// SYNC NOTIFIER
// ──────────────────────────────────────────────────────────────────────────────

class BackgroundSyncStatusNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => SyncStatus.idle;
  
  void setStatus(SyncStatus status) {
    state = status;
  }
}

/// Provider lắng nghe trạng thái của BackgroundSyncService
final backgroundSyncStatusProvider = NotifierProvider<BackgroundSyncStatusNotifier, SyncStatus>(() {
  return BackgroundSyncStatusNotifier();
});

/// Provider cho BackgroundSyncService — singleton, được khởi động từ main.dart.
final backgroundSyncServiceProvider = Provider<BackgroundSyncService>((ref) {
  final syncRepo = ref.read(syncRepositoryProvider);
  final service = BackgroundSyncService(syncRepo: syncRepo);
  
  service.onStatusChanged = (status, error) {
    debugPrint('[BackgroundSyncService] status: $status ${error ?? ''}');
    // Update the state provider so UI can react
    ref.read(backgroundSyncStatusProvider.notifier).setStatus(status);
  };
  
  return service;
});

/// Provider cho số dòng chưa đồng bộ — dùng hiển thị badge/indicator trên UI.
final unsyncedCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.read(syncRepositoryProvider);
  return repo.countUnsynced();
});

// ──────────────────────────────────────────────────────────────────────────────
// MANUAL SYNC NOTIFIER
// ──────────────────────────────────────────────────────────────────────────────

/// State của một lần sync thủ công.
class SyncState {
  final bool isLoading;
  final SyncResult? lastResult;
  final String? error;

  const SyncState({
    this.isLoading = false,
    this.lastResult,
    this.error,
  });

  SyncState copyWith({
    bool? isLoading,
    SyncResult? lastResult,
    String? error,
  }) {
    return SyncState(
      isLoading: isLoading ?? this.isLoading,
      lastResult: lastResult ?? this.lastResult,
      error: error,
    );
  }
}

/// [SyncNotifier] — Điều phối sync thủ công từ UI (ví dụ: kéo để làm mới,
/// hoặc nhấn nút sync trong settings).
class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncState();

  /// Kích hoạt sync đầy đủ (PUSH + PULL) từ UI.
  Future<void> syncNow() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final bgService = ref.read(backgroundSyncServiceProvider);
      await bgService.triggerManualSync();

      // Sau khi sync xong, lấy kết quả từ syncRepo để báo cáo
      final repo = ref.read(syncRepositoryProvider);
      final unsyncedCount = await repo.countUnsynced();

      state = state.copyWith(
        isLoading: false,
        // Nếu unsyncedCount == 0 → tất cả đã sync
        error: unsyncedCount > 0 ? 'Còn $unsyncedCount dòng chưa đồng bộ' : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi sync: $e',
      );
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

    try {
      final repo = ref.read(syncRepositoryProvider);
      final result = await repo.pushOnly();

      state = state.copyWith(
        isLoading: false,
        lastResult: result,
        error: result.hasErrors ? result.errors.join('\n') : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Lỗi push: $e');
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
