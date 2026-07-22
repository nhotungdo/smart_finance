import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

typedef NetworkStatusChecker = Future<NetworkStatus> Function();

NetworkStatus networkStatusFromResults(List<ConnectivityResult> results) {
  final hasConnection = results.any(
    (result) => result != ConnectivityResult.none,
  );
  return hasConnection ? NetworkStatus.online : NetworkStatus.offline;
}

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final networkStatusCheckerProvider = Provider<NetworkStatusChecker>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return () async =>
      networkStatusFromResults(await connectivity.checkConnectivity());
});

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  final connectivity = ref.watch(connectivityProvider);

  yield networkStatusFromResults(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged
      .map(networkStatusFromResults)
      .distinct();
});
