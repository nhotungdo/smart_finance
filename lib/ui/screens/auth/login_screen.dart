import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_finance/providers/auth_provider.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/smart_button.dart';
import 'package:smart_finance/ui/widgets/smart_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signIn(
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );
    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi: ${state.error}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 800;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: isWide
            ? _WideLogin(
                theme: theme,
                isDark: isDark,
                formKey: _formKey,
                emailCtrl: _emailCtrl,
                passCtrl: _passCtrl,
                obscure: _obscure,
                isLoading: isLoading,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                onSubmit: _submit,
              )
            : _NarrowLogin(
                theme: theme,
                formKey: _formKey,
                emailCtrl: _emailCtrl,
                passCtrl: _passCtrl,
                obscure: _obscure,
                isLoading: isLoading,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                onSubmit: _submit,
              ),
      ),
    );
  }
}

// ── Wide Layout ───────────────────────────────────────────────────────────────
class _WideLogin extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _WideLogin({
    required this.theme,
    required this.isDark,
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: Brand Hero Bento
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                    : [const Color(0xFFF8FAFC), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : theme.colorScheme.primary.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: -80,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : theme.colorScheme.primary.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.15) : theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: isDark ? Colors.white.withValues(alpha: 0.2) : theme.colorScheme.primary.withValues(alpha: 0.2)),
                            ),
                            child: Icon(Icons.auto_graph,
                                color: isDark ? Colors.white : theme.colorScheme.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'SmartFinance',
                            style: TextStyle(
                              color: isDark ? Colors.white : theme.colorScheme.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'Chào mừng\ntrở lại 👋',
                        style: TextStyle(
                          color: isDark ? Colors.white : theme.colorScheme.primary,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Đăng nhập để tiếp tục quản lý\ntài chính doanh nghiệp của bạn.',
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.7) : theme.colorScheme.onSurfaceVariant,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Mini feature grid
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _FeatureChip(label: '📊 Báo cáo tức thì'),
                          _FeatureChip(label: '🔄 Sync offline'),
                          _FeatureChip(label: '🧾 Quản lý hóa đơn'),
                          _FeatureChip(label: '🔒 Bảo mật tuyệt đối'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right: Form Bento tiles
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: _LoginForm(
              theme: theme,
              formKey: formKey,
              emailCtrl: emailCtrl,
              passCtrl: passCtrl,
              obscure: obscure,
              isLoading: isLoading,
              onToggleObscure: onToggleObscure,
              onSubmit: onSubmit,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Narrow Layout ─────────────────────────────────────────────────────────────
class _NarrowLogin extends StatelessWidget {
  final ThemeData theme;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _NarrowLogin({
    required this.theme,
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header tile
          BentoCard(
            accentColor: theme.colorScheme.primary,
            showAccentStrip: true,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.08),
                theme.colorScheme.secondary.withValues(alpha: 0.04),
              ],
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
                      child: const Icon(Icons.auto_graph,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text('SmartFinance',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Đăng nhập',
                    style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Chào mừng trở lại!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _LoginForm(
            theme: theme,
            formKey: formKey,
            emailCtrl: emailCtrl,
            passCtrl: passCtrl,
            obscure: obscure,
            isLoading: isLoading,
            onToggleObscure: onToggleObscure,
            onSubmit: onSubmit,
          ),
        ],
      ),
        ),
      ),
    );
  }
}

// ── Shared Form ───────────────────────────────────────────────────────────────
class _LoginForm extends StatelessWidget {
  final ThemeData theme;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _LoginForm({
    required this.theme,
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email tile
          BentoCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BentoSectionHeader(title: 'Email'),
                const SizedBox(height: 12),
                SmartTextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  hintText: 'email@congty.com',
                  prefixIcon: Icons.email_outlined,
                  labelText: 'Địa chỉ email',
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Email không hợp lệ'
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Password tile
          BentoCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BentoSectionHeader(title: 'Mật khẩu'),
                const SizedBox(height: 12),
                SmartTextField(
                  controller: passCtrl,
                  obscureText: obscure,
                  hintText: '••••••••',
                  labelText: 'Mật khẩu',
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: onToggleObscure,
                  ),
                  validator: (v) => v == null || v.length < 6
                      ? 'Mật khẩu ít nhất 6 ký tự'
                      : null,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: SmartButton.text(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text('Quên mật khẩu?',
                        style:
                            TextStyle(color: theme.colorScheme.primary)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Submit tile
          BentoCard(
            accentColor: theme.colorScheme.primary,
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: double.infinity,
              child: SmartButton(
                onPressed: onSubmit,
                isLoading: isLoading,
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: const Text('Đăng nhập',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Register link
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Chưa có tài khoản? ',
                    style: theme.textTheme.bodyMedium),
                SmartButton.text(
                  onPressed: () => context.go('/register'),
                  child: Text('Đăng ký ngay',
                      style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}
