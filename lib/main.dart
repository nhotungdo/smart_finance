import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_finance/ui/routing/app_router.dart';
import 'package:smart_finance/ui/theme/app_theme.dart';
import 'package:smart_finance/providers/theme_provider.dart';
import 'package:smart_finance/providers/network_status_provider.dart';
import 'package:smart_finance/data/database/database_factory_initializer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  late Future<SharedPreferences> _initialization = _initialize();
  bool _supabaseInitialized = false;

  Future<SharedPreferences> _initialize() async {
    await initializeDatabaseFactory();
    if (!_supabaseInitialized) {
      await Supabase.initialize(
        url: 'https://xllpjaonfaebohkjcznt.supabase.co',
        publishableKey: 'sb_publishable_p8iZe-cj8Iexak_5QQad2g_Z85O05bi',
      );
      _supabaseInitialized = true;
    }
    return SharedPreferences.getInstance();
  }

  void _retry() {
    setState(() => _initialization = _initialize());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(snapshot.data!),
            ],
            child: const MyApp(),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: snapshot.hasError
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Không thể khởi động SmartFinance',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late final AuthStateRefreshListenable _authRefreshListenable;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authRefreshListenable = AuthStateRefreshListenable();
    _router = createAppRouter(refreshListenable: _authRefreshListenable);
  }

  @override
  void dispose() {
    _router.dispose();
    _authRefreshListenable.dispose();
    super.dispose();
  }

  void _showNetworkStatus(NetworkStatus status) {
    final messenger = _scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    final isOnline = status == NetworkStatus.online;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: isOnline
              ? const Duration(seconds: 3)
              : const Duration(days: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isOnline
              ? const Color(0xFF047857)
              : const Color(0xFFB45309),
          content: Row(
            children: [
              Icon(
                isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isOnline
                      ? 'Đã kết nối mạng. Bạn có thể đồng bộ dữ liệu.'
                      : 'Đang mất mạng. Dữ liệu mới vẫn được lưu trên thiết bị.',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    ref.listen<AsyncValue<NetworkStatus>>(networkStatusProvider, (
      previous,
      next,
    ) {
      final previousStatus = previous?.asData?.value;
      final status = next.asData?.value;
      if (status == null || status == previousStatus) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showNetworkStatus(status);
      });
    });

    return MaterialApp.router(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'Smart Finance SME',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
