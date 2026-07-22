import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/providers/network_status_provider.dart';
import 'package:smart_finance/providers/sync_provider.dart';

void main() {
  test(
    'manual sync shows loading before reporting an offline device',
    () async {
      final container = ProviderContainer(
        overrides: [
          networkStatusCheckerProvider.overrideWithValue(
            () async => NetworkStatus.offline,
          ),
          offlineSyncFeedbackDelayProvider.overrideWithValue(Duration.zero),
        ],
      );
      addTearDown(container.dispose);

      final syncFuture = container
          .read(syncNotifierProvider.notifier)
          .syncNow();
      expect(container.read(syncNotifierProvider).isLoading, isTrue);

      await syncFuture;
      final state = container.read(syncNotifierProvider);

      expect(state.isLoading, isFalse);
      expect(state.error, contains('Không có kết nối mạng'));
    },
  );
}
