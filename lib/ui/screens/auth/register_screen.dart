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

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreed = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _businessCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng đồng ý với Điều khoản sử dụng'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          fullName: _nameCtrl.text.trim(),
          businessName: _businessCtrl.text.trim(),
        );
    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi: ${state.error}'),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
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
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Brand header ──────────────────────────────────
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6C63FF), Color(0xFF4F46E5)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.auto_graph,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'SmartFinance',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                        Text(
                          'Tạo tài khoản',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bắt đầu quản lý tài chính thông minh ngay hôm nay.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Personal Info Bento ────────────────────────────
                        BentoCard(
                          showAccentStrip: true,
                          accentColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel(
                                icon: Icons.person_outline_rounded,
                                label: 'Thông tin cá nhân',
                                color: const Color(0xFF6C63FF),
                              ),
                              const SizedBox(height: 20),
                              SmartTextField(
                                controller: _nameCtrl,
                                hintText: 'Nguyễn Văn A',
                                labelText: 'Họ và tên',
                                prefixIcon: Icons.person_outline,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Vui lòng nhập họ tên'
                                    : null,
                              ),
                              const SizedBox(height: 16),
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
                        const SizedBox(height: 14),

                        // ── Account Info Bento ─────────────────────────────
                        BentoCard(
                          showAccentStrip: true,
                          accentColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel(
                                icon: Icons.shield_outlined,
                                label: 'Thông tin đăng nhập',
                                color: const Color(0xFF10B981),
                              ),
                              const SizedBox(height: 20),
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
                              const SizedBox(height: 16),
                              SmartTextField(
                                controller: _passCtrl,
                                obscureText: _obscurePass,
                                hintText: '••••••••',
                                labelText: 'Mật khẩu',
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePass
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(
                                      () => _obscurePass = !_obscurePass),
                                ),
                                validator: (v) => v == null || v.length < 6
                                    ? 'Mật khẩu ít nhất 6 ký tự'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              SmartTextField(
                                controller: _confirmCtrl,
                                obscureText: _obscureConfirm,
                                hintText: '••••••••',
                                labelText: 'Xác nhận mật khẩu',
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                ),
                                validator: (v) => v != _passCtrl.text
                                    ? 'Mật khẩu không khớp'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Terms & Submit ────────────────────────────────
                        BentoCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () => setState(() => _agreed = !_agreed),
                                borderRadius: BorderRadius.circular(12),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: _agreed
                                            ? const Color(0xFF6C63FF)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _agreed
                                              ? const Color(0xFF6C63FF)
                                              : theme.colorScheme.outline,
                                          width: 2,
                                        ),
                                      ),
                                      child: _agreed
                                          ? const Icon(Icons.check,
                                              color: Colors.white, size: 14)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Wrap(
                                        children: [
                                          Text('Tôi đồng ý với ',
                                              style: theme.textTheme.bodySmall),
                                          Text('Điều khoản sử dụng',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                      color: const Color(
                                                          0xFF6C63FF),
                                                      fontWeight:
                                                          FontWeight.w600)),
                                          Text(' và ',
                                              style: theme.textTheme.bodySmall),
                                          Text('Chính sách bảo mật',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                      color: const Color(
                                                          0xFF6C63FF),
                                                      fontWeight:
                                                          FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: SmartButton(
                                  onPressed: _submit,
                                  isLoading: isLoading,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  child: const Text(
                                    'Tạo tài khoản',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Đã có tài khoản? ',
                                  style: Theme.of(context).textTheme.bodyMedium),
                              SmartButton.text(
                                onPressed: () => context.go('/login'),
                                child: Text(
                                  'Đăng nhập',
                                  style: TextStyle(
                                    color: const Color(0xFF6C63FF),
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
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionLabel(
      {required this.icon, required this.label, required this.color});

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
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
