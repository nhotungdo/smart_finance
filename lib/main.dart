import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_finance/ui/routing/app_router.dart';
import 'package:smart_finance/ui/theme/app_theme.dart';
import 'package:smart_finance/providers/theme_provider.dart';
import 'package:smart_finance/providers/sync_provider.dart';
import 'package:smart_finance/data/database/database_factory_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDatabaseFactory();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://xllpjaonfaebohkjcznt.supabase.co',
    publishableKey: 'sb_publishable_p8iZe-cj8Iexak_5QQad2g_Z85O05bi',
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Khởi động BackgroundSyncService sau khi app đã build xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBackgroundSync();
    });
  }

  void _startBackgroundSync() {
    final syncService = ref.read(backgroundSyncServiceProvider);

    // Đăng ký callback để log trạng thái (tuỳ chọn: có thể hiển thị snackbar)
    syncService.onStatusChanged = (status, error) {
      debugPrint('[App] BackgroundSync status: $status ${error ?? ''}');
    };

    syncService.start();
    debugPrint('[App] BackgroundSyncService đã được khởi động.');
  }

  @override
  void dispose() {
    // Dừng service khi app đóng
    ref.read(backgroundSyncServiceProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Smart Finance SME',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
