import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/providers/network_status_provider.dart';

void main() {
  test('reports offline when no connection type is available', () {
    expect(
      networkStatusFromResults(const [ConnectivityResult.none]),
      NetworkStatus.offline,
    );
    expect(networkStatusFromResults(const []), NetworkStatus.offline);
  });

  test('reports online when at least one connection type is available', () {
    expect(
      networkStatusFromResults(const [ConnectivityResult.wifi]),
      NetworkStatus.online,
    );
    expect(
      networkStatusFromResults(const [
        ConnectivityResult.none,
        ConnectivityResult.mobile,
      ]),
      NetworkStatus.online,
    );
  });
}
