import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_finance/providers/auth_provider.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/smart_button.dart';
import 'package:smart_finance/ui/widgets/smart_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreed = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _businessCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đồng ý với Điều khoản sử dụng')),
      );
      return;
    }
    final requiresEmailConfirmation = await ref
        .read(authNotifierProvider.notifier)
        .signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          fullName: _nameCtrl.text.trim(),
          businessName: _businessCtrl.text.trim(),
        );
    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${state.error}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else if (requiresEmailConfirmation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đăng ký thành công. Hãy xác nhận email rồi đăng nhập.',
          ),
        ),
      );
      context.go('/login');
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header Bento ─────────────────────────────────────
                    BentoCard(
                      accentColor: theme.colorScheme.secondary,
                      showAccentStrip: true,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.secondary.withValues(alpha: 0.08),
                          theme.colorScheme.primary.withValues(alpha: 0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.auto_graph,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'SmartFinance',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Tạo tài khoản mới',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bắt đầu quản lý tài chính thông minh',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Personal Info Bento ────────────────────────────
                    BentoCard(
                      showAccentStrip: true,
                      accentColor: theme.colorScheme.primary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BentoSectionHeader(
                            title: 'Thông tin cá nhân',
                            subtitle: 'Họ tên và doanh nghiệp',
                          ),
                          const SizedBox(height: 16),
                          SmartTextField(
                            controller: _nameCtrl,
                            hintText: 'Nguyễn Văn A',
                            labelText: 'Họ và tên',
                            prefixIcon: Icons.person_outline,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Vui lòng nhập họ tên'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          SmartTextField(
                            controller: _businessCtrl,
                            hintText: 'Công ty TNHH ABC',
                            labelText: 'Tên doanh nghiệp',
                            prefixIcon: Icons.business_outlined,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Vui lòng nhập tên doanh nghiệp'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Account Info Bento ─────────────────────────────
                    BentoCard(
                      showAccentStrip: true,
                      accentColor: const Color(0xFF10B981),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BentoSectionHeader(
                            title: 'Thông tin đăng nhập',
                            subtitle: 'Email và mật khẩu bảo mật',
                          ),
                          const SizedBox(height: 16),
                          SmartTextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            hintText: 'email@congty.com',
                            labelText: 'Email',
                            prefixIcon: Icons.email_outlined,
                            validator: (v) => v == null || !v.contains('@')
                                ? 'Email không hợp lệ'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          SmartTextField(
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            hintText: '••••••••',
                            labelText: 'Mật khẩu',
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                            validator: (v) => v == null || v.length < 6
                                ? 'Mật khẩu ít nhất 6 ký tự'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          SmartTextField(
                            controller: _confirmCtrl,
                            obscureText: _obscureConfirm,
                            hintText: '••••••••',
                            labelText: 'Xác nhận mật khẩu',
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                            validator: (v) => v != _passCtrl.text
                                ? 'Mật khẩu không khớp'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Terms & Submit Bento ───────────────────────────
                    BentoCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _agreed,
                                onChanged: (v) =>
                                    setState(() => _agreed = v ?? false),
                                activeColor: theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Expanded(
                                child: Wrap(
                                  children: [
                                    Text(
                                      'Tôi đồng ý với ',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    Text(
                                      'Điều khoản sử dụng',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      ' và ',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    Text(
                                      'Chính sách bảo mật',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: SmartButton(
                              onPressed: _submit,
                              isLoading: isLoading,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: const Text(
                                'Tạo tài khoản',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Đã có tài khoản? ',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SmartButton.text(
                            onPressed: () => context.go('/login'),
                            child: Text(
                              'Đăng nhập',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
