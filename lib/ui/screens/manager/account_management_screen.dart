import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/user_model.dart';
import 'package:smart_finance/providers/accounts_provider.dart';
import 'package:smart_finance/providers/auth_provider.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/page_header.dart';
import 'package:smart_finance/ui/widgets/smart_button.dart';
import 'package:smart_finance/ui/widgets/smart_text_field.dart';

class AccountManagementScreen extends ConsumerWidget {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsState = ref.watch(accountsProvider);
    final currentUserId = ref.watch(currentUserProfileProvider).value?.userId;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(accountsProvider);
          await ref.read(accountsProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 24,
            vertical: compact ? 16 : 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHeader(
                    title: 'Quản lý tài khoản',
                    subtitle:
                        'Phân quyền và quản lý nhân viên trong doanh nghiệp.',
                    compact: true,
                    action: SmartButton(
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      onPressed: () async {
                        final created = await showDialog<bool>(
                          context: context,
                          builder: (_) => const _CreateAccountDialog(),
                        );
                        if (context.mounted && created == true) {
                          _message(context, 'Đã tạo tài khoản nhân viên.');
                        }
                      },
                      child: const Text('Thêm tài khoản'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  accountsState.when(
                    loading: () => const SizedBox(
                      height: 320,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Center(
                      child: Text(
                        'Không thể tải tài khoản: $error',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    data: (accounts) => accounts.isEmpty
                        ? const BentoCard(
                            child: SizedBox(
                              height: 240,
                              child: Center(child: Text('Chưa có tài khoản.')),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth >= 760) {
                                return _AccountTable(
                                  accounts: accounts,
                                  currentUserId: currentUserId,
                                );
                              }
                              return Column(
                                children: accounts
                                    .map(
                                      (account) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _AccountCard(
                                          account: account,
                                          isCurrent:
                                              account.userId == currentUserId,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateAccountDialog extends ConsumerStatefulWidget {
  const _CreateAccountDialog();

  @override
  ConsumerState<_CreateAccountDialog> createState() =>
      _CreateAccountDialogState();
}

class _CreateAccountDialogState extends ConsumerState<_CreateAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  AppRole _role = AppRole.accountant;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(accountsProvider.notifier)
          .createAccount(
            fullName: _fullNameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            role: _role,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final message = error
          .toString()
          .replaceFirst('Bad state: ', '')
          .replaceFirst('Exception: ', '');
      _message(context, message, error: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = (MediaQuery.sizeOf(context).height - 32).clamp(
      300.0,
      720.0,
    );
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Thêm tài khoản',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Đóng',
                      child: IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SmartTextField(
                  controller: _fullNameController,
                  labelText: 'Họ và tên',
                  prefixIcon: Icons.badge_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ và tên.';
                    }
                    if (value.trim().length < 2) {
                      return 'Họ và tên phải có ít nhất 2 ký tự.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: _emailController,
                  labelText: 'Email đăng nhập',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Vui lòng nhập email.';
                    final valid = RegExp(
                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                    ).hasMatch(email);
                    return valid ? null : 'Email không đúng định dạng.';
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AppRole>(
                  initialValue: _role,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Vai trò',
                    prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                  ),
                  items: AppRole.values
                      .map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Text(role.label),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (role) {
                          if (role != null) setState(() => _role = role);
                        },
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: _passwordController,
                  labelText: 'Mật khẩu ban đầu',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu.';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Nhập lại mật khẩu',
                  prefixIcon: Icons.lock_reset_rounded,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    tooltip: _obscureConfirmPassword
                        ? 'Hiện mật khẩu'
                        : 'Ẩn mật khẩu',
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  validator: (value) => value == _passwordController.text
                      ? null
                      : 'Mật khẩu nhập lại không khớp.',
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SmartButton.text(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 12),
                    SmartButton(
                      onPressed: _isSubmitting ? null : _submit,
                      isLoading: _isSubmitting,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      child: const Text('Tạo tài khoản'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountTable extends StatelessWidget {
  const _AccountTable({required this.accounts, required this.currentUserId});

  final List<UserModel> accounts;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => BentoCard(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              horizontalMargin: 20,
              columnSpacing: 28,
              headingRowHeight: 48,
              dataRowMinHeight: 64,
              dataRowMaxHeight: 64,
              columns: const [
                DataColumn(label: Text('Tài khoản')),
                DataColumn(label: Text('Vai trò')),
                DataColumn(label: Text('Trạng thái')),
                DataColumn(label: Text('Hành động')),
              ],
              rows: accounts.map((account) {
                final isCurrent = account.userId == currentUserId;
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 270,
                        child: _AccountIdentity(
                          account: account,
                          isCurrent: isCurrent,
                        ),
                      ),
                    ),
                    DataCell(
                      _RoleSelector(
                        account: account,
                        enabled: !isCurrent,
                        compact: true,
                        width: 190,
                      ),
                    ),
                    DataCell(_StatusChip(status: account.status)),
                    DataCell(
                      _StatusButton(
                        account: account,
                        enabled: !isCurrent,
                        compact: true,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.isCurrent});

  final UserModel account;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _AccountIdentity(account: account, isCurrent: isCurrent),
              ),
              _StatusChip(status: account.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RoleSelector(
                  account: account,
                  enabled: !isCurrent,
                  compact: true,
                ),
              ),
              const SizedBox(width: 10),
              _StatusButton(
                account: account,
                enabled: !isCurrent,
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountIdentity extends StatelessWidget {
  const _AccountIdentity({required this.account, required this.isCurrent});

  final UserModel account;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          child: Text(
            account.fullName.isEmpty ? '?' : account.fullName[0].toUpperCase(),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCurrent ? '${account.fullName} (Bạn)' : account.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                account.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleSelector extends ConsumerWidget {
  const _RoleSelector({
    required this.account,
    required this.enabled,
    this.compact = false,
    this.width,
  });

  final UserModel account;
  final bool enabled;
  final bool compact;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (compact) {
      final theme = Theme.of(context);
      return Tooltip(
        message: enabled ? 'Đổi vai trò' : 'Không thể đổi vai trò của bạn',
        child: Container(
          width: width,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: enabled ? 0.7 : 0.45,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AppRole>(
              value: account.role,
              isExpanded: true,
              borderRadius: BorderRadius.circular(8),
              iconSize: 18,
              items: _roleItems(),
              onChanged: enabled
                  ? (role) => _changeRole(context, ref, role)
                  : null,
            ),
          ),
        ),
      );
    }

    return DropdownButtonFormField<AppRole>(
      initialValue: account.role,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Vai trò', isDense: true),
      items: _roleItems(),
      onChanged: !enabled ? null : (role) => _changeRole(context, ref, role),
    );
  }

  List<DropdownMenuItem<AppRole>> _roleItems() => AppRole.values
      .map(
        (role) => DropdownMenuItem(
          value: role,
          child: Text(role.label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      )
      .toList();

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    AppRole? role,
  ) async {
    if (role == null || role == account.role) return;
    try {
      await ref.read(accountsProvider.notifier).updateRole(account, role);
      if (context.mounted) _message(context, 'Đã cập nhật vai trò.');
    } catch (error) {
      if (context.mounted) {
        _message(context, error.toString(), error: true);
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final RecordStatus status;

  @override
  Widget build(BuildContext context) {
    final active = status == RecordStatus.active;
    final color = active ? const Color(0xFF059669) : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        active ? 'Hoạt động' : 'Đã khóa',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusButton extends ConsumerWidget {
  const _StatusButton({
    required this.account,
    required this.enabled,
    this.compact = false,
  });

  final UserModel account;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = account.status == RecordStatus.active;
    final onPressed = !enabled
        ? null
        : () => _changeStatus(context, ref, active);

    if (compact) {
      return Tooltip(
        message: !enabled
            ? 'Không thể khóa tài khoản của bạn'
            : active
            ? 'Khóa tài khoản'
            : 'Mở khóa tài khoản',
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            active ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
            size: 18,
          ),
          style: IconButton.styleFrom(
            fixedSize: const Size.square(36),
            minimumSize: const Size.square(36),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: Theme.of(context).colorScheme.primary,
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.55),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(active ? Icons.lock_outline_rounded : Icons.lock_open_rounded),
      label: Text(active ? 'Khóa' : 'Mở khóa'),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    bool active,
  ) async {
    final next = active ? RecordStatus.deleted : RecordStatus.active;
    try {
      await ref.read(accountsProvider.notifier).updateStatus(account, next);
      if (context.mounted) {
        _message(context, active ? 'Đã khóa tài khoản.' : 'Đã mở tài khoản.');
      }
    } catch (error) {
      if (context.mounted) {
        _message(context, error.toString(), error: true);
      }
    }
  }
}

void _message(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error
          ? Theme.of(context).colorScheme.error
          : const Color(0xFF059669),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
