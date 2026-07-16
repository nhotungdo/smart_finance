import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_finance/providers/auth_provider.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/smart_button.dart';
import 'package:smart_finance/ui/widgets/smart_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authNotifierProvider.notifier)
        .resetPassword(_emailCtrl.text.trim());
    if (!mounted) return;

    final state = ref.read(authNotifierProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi: ${state.error}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } else {
      setState(() => _isSuccess = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _isSuccess
                  ? _buildSuccessBento(theme, isDark)
                  : _buildFormBento(theme, isDark, isLoading),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormBento(ThemeData theme, bool isDark, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BentoCard(
          accentColor: theme.colorScheme.primary,
          showAccentStrip: true,
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.08),
              theme.colorScheme.secondary.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.lock_reset_rounded,
                    color: theme.colorScheme.primary, size: 28),
              ),
              const SizedBox(height: 20),
              Text('Khôi phục mật khẩu',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                  'Nhập email của bạn để nhận liên kết đặt lại mật khẩu an toàn.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BentoCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BentoSectionHeader(title: 'Email xác thực'),
                const SizedBox(height: 16),
                SmartTextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  hintText: 'Nhập địa chỉ email...',
                  labelText: 'Địa chỉ email',
                  prefixIcon: Icons.email_outlined,
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Email không hợp lệ'
                      : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: SmartButton(
                    onPressed: _submit,
                    isLoading: isLoading,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Text('Gửi liên kết khôi phục',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessBento(ThemeData theme, bool isDark) {
    final successColor = const Color(0xFF10B981);
    return BentoCard(
      accentColor: successColor,
      showAccentStrip: true,
      gradient: LinearGradient(
        colors: [
          successColor.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: successColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mark_email_read_rounded,
                  color: successColor, size: 48),
            ),
            const SizedBox(height: 24),
            Text('Đã gửi email khôi phục!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
              'Chúng tôi đã gửi hướng dẫn đặt lại mật khẩu đến:\n${_emailCtrl.text}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: SmartButton.outlined(
                onPressed: () => context.go('/login'),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Text('Quay lại đăng nhập',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
