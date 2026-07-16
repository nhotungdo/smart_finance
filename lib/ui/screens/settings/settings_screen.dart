import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_finance/providers/theme_provider.dart';
import 'package:smart_finance/providers/sync_provider.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/page_header.dart';
import 'package:smart_finance/ui/widgets/sync_status_indicator.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Cài đặt',
                subtitle: 'Quản lý tài khoản, giao diện và đồng bộ.',
              ),
              const SizedBox(height: 24),

              // Tài khoản Section
              BentoCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingsSectionHeader(
                      title: 'Tài khoản',
                      icon: Icons.person_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(Icons.person,
                            color: theme.colorScheme.primary),
                      ),
                      title: Text(user?.email ?? 'Không có email',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text('Đã đăng nhập',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF10B981))),
                    ),
                    const Divider(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Đăng xuất'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Giao diện Section
              BentoCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingsSectionHeader(
                      title: 'Giao diện',
                      icon: Icons.palette_rounded,
                      color: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                            isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: const Color(0xFF8B5CF6)),
                      ),
                      title: const Text('Chế độ tối (Dark Mode)'),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (val) {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                        activeThumbColor: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Đồng bộ Section
              BentoCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingsSectionHeader(
                      title: 'Đồng bộ Dữ liệu',
                      icon: Icons.sync_rounded,
                      color: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const SyncStatusIndicator(),
                      title: const Text('Trạng thái đồng bộ'),
                      subtitle: const Text('Tự động đồng bộ khi có mạng'),
                      trailing: Consumer(
                        builder: (context, ref, child) {
                          final syncState = ref.watch(syncNotifierProvider);
                          return syncState.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : TextButton.icon(
                                  onPressed: () async {
                                    await ref
                                        .read(syncNotifierProvider.notifier)
                                        .syncNow();
                                    if (context.mounted) {
                                      final finalState =
                                          ref.read(syncNotifierProvider);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            finalState.error != null
                                                ? 'Lỗi đồng bộ: ${finalState.error}'
                                                : 'Đồng bộ thành công!',
                                          ),
                                          backgroundColor:
                                              finalState.error != null
                                                  ? theme.colorScheme.error
                                                  : const Color(0xFF10B981),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.sync),
                                  label: const Text('Đồng bộ ngay'),
                                );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Giới thiệu Section
              BentoCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingsSectionHeader(
                      title: 'Giới thiệu',
                      icon: Icons.info_outline_rounded,
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(height: 16),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('SmartFinance SME'),
                      subtitle: Text('Phiên bản 1.0.0\n© 2026 SmartFinance'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SettingsSectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
