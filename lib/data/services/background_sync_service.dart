import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_finance/data/repositories/sync_repository.dart';

/// Trạng thái của BackgroundSyncService
enum SyncStatus {
  idle,      // Đang chờ
  syncing,   // Đang đồng bộ
  success,   // Sync thành công lần cuối
  error,     // Có lỗi trong lần sync cuối
}

/// [BackgroundSyncService] — Dịch vụ chạy ngầm, tự động đồng bộ dữ liệu.
///
/// Thuật toán:
/// 1. Lắng nghe sự kiện thay đổi kết nối mạng (`connectivity_plus`).
/// 2. Khi phát hiện **có mạng** (WiFi hoặc Mobile Data), tự động kích hoạt
///    `SyncRepository.sync()`.
/// 3. Ngoài ra, chạy định kỳ mỗi [periodicInterval] để đồng bộ nếu có mạng.
/// 4. Bỏ qua sync nếu người dùng chưa đăng nhập.
class BackgroundSyncService {
  final SyncRepository _syncRepo;

  /// Khoảng thời gian giữa các lần sync định kỳ (mặc định: 5 phút)
  final Duration periodicInterval;

  BackgroundSyncService({
    SyncRepository? syncRepo,
    this.periodicInterval = const Duration(minutes: 5),
  }) : _syncRepo = syncRepo ?? SyncRepository();

  // ── Internal State ────────────────────────────────────────────────────────
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicTimer;
  bool _isSyncing = false;
  SyncStatus _status = SyncStatus.idle;
  String? _lastError;
  DateTime? _lastSyncTime;

  // Callback để thông báo cho UI khi trạng thái thay đổi
  void Function(SyncStatus status, String? error)? onStatusChanged;

  // ── Getters ───────────────────────────────────────────────────────────────
  SyncStatus get status => _status;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isSyncing => _isSyncing;

  // ──────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ──────────────────────────────────────────────────────────────────────────

  /// Khởi động service: bắt đầu lắng nghe mạng và chạy timer định kỳ.
  void start() {
    debugPrint('[BackgroundSyncService] Đã khởi động.');

    // 1. Lắng nghe thay đổi kết nối mạng
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);

    // 2. Kiểm tra ngay lập tức khi khởi động
    _checkAndSync();

    // 3. Chạy định kỳ
    _periodicTimer = Timer.periodic(periodicInterval, (_) {
      debugPrint('[BackgroundSyncService] Kích hoạt sync định kỳ...');
      _checkAndSync();
    });
  }

  /// Dừng service và giải phóng tài nguyên.
  void stop() {
    _connectivitySub?.cancel();
    _periodicTimer?.cancel();
    _connectivitySub = null;
    _periodicTimer = null;
    debugPrint('[BackgroundSyncService] Đã dừng.');
  }

  /// Kích hoạt sync thủ công (ví dụ: khi người dùng nhấn nút sync).
  Future<void> triggerManualSync() async {
    debugPrint('[BackgroundSyncService] Sync thủ công được kích hoạt.');
    await _doSync();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PRIVATE METHODS
  // ──────────────────────────────────────────────────────────────────────────

  /// Callback khi trạng thái mạng thay đổi.
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasNetwork = results.any(
      (r) => r == ConnectivityResult.wifi ||
             r == ConnectivityResult.mobile ||
             r == ConnectivityResult.ethernet,
    );

    if (hasNetwork) {
      debugPrint('[BackgroundSyncService] Phát hiện có mạng → kích hoạt sync.');
      _checkAndSync();
    } else {
      debugPrint('[BackgroundSyncService] Mất mạng → dừng sync.');
    }
  }

  /// Kiểm tra điều kiện rồi chạy sync nếu hợp lệ.
  Future<void> _checkAndSync() async {
    // Tránh chạy song song
    if (_isSyncing) {
      debugPrint('[BackgroundSyncService] Đang sync, bỏ qua request này.');
      return;
    }

    // Kiểm tra có mạng không
    final connectivity = await Connectivity().checkConnectivity();
    final hasNetwork = connectivity.any(
      (r) => r == ConnectivityResult.wifi ||
             r == ConnectivityResult.mobile ||
             r == ConnectivityResult.ethernet,
    );

    if (!hasNetwork) {
      debugPrint('[BackgroundSyncService] Không có mạng, bỏ qua sync.');
      return;
    }

    // Kiểm tra đã đăng nhập chưa
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('[BackgroundSyncService] Chưa đăng nhập, bỏ qua sync.');
      return;
    }

    await _doSync();
  }

  /// Thực hiện đồng bộ thực sự.
  Future<void> _doSync() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _setStatus(SyncStatus.syncing);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _isSyncing = false;
        _setStatus(SyncStatus.idle);
        return;
      }

      // Lấy companyId từ Supabase (nếu có)
      String? companyId;
      try {
        final userData = await Supabase.instance.client
            .from('users')
            .select('company_id')
            .eq('user_id', user.id)
            .maybeSingle();
        companyId = userData?['company_id'] as String?;
      } catch (_) {
        // Không có company, tiếp tục sync theo userId
      }

      final result = await _syncRepo.sync(
        companyId: companyId,
        userId: user.id,
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
    } catch (e) {
      _lastError = e.toString();
      _setStatus(SyncStatus.error, _lastError);
      debugPrint('[BackgroundSyncService] ✗ Lỗi nghiêm trọng khi sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void _setStatus(SyncStatus status, [String? error]) {
    _status = status;
    _lastError = error;
    onStatusChanged?.call(status, error);
  }
}
