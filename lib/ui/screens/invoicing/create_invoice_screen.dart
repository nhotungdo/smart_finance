import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateInvoiceScreen extends StatelessWidget {
  const CreateInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width > 768;

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by MainLayout
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 896), // max-w-4xl roughly 896px
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(theme, isDesktop),
                const SizedBox(height: 24),

                // Client & Dates
                _buildClientAndDates(theme, isDesktop),
                const SizedBox(height: 24),

                // Line Items
                _buildLineItems(context, theme, isDesktop),
                const SizedBox(height: 24),

                // Totals & Notes
                _buildTotalsAndNotes(context, theme, isDesktop),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      padding: const EdgeInsets.only(bottom: 16),
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tạo hóa đơn mới',
                style: isDesktop
                    ? theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      )
                    : theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                'Soạn hóa đơn mới để gửi cho khách hàng của bạn.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (!isDesktop) const SizedBox(height: 16),
          Column(
            crossAxisAlignment: isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                'SỐ HÓA ĐƠN',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'INV-2023-0042',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientAndDates(ThemeData theme, bool isDesktop) {
    final children = [
      Expanded(
        flex: 1,
        child: _GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHI TIẾT KHÁCH HÀNG',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                hint: const Text('Chọn một khách hàng...'),
                items: ['Acme Corp', 'Global Tech Industries', 'Stark Enterprises']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {},
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: theme.colorScheme.secondary),
                    const SizedBox(width: 4),
                    Text(
                      'Thêm khách hàng mới',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      if (isDesktop) const SizedBox(width: 24) else const SizedBox(height: 24),
      Expanded(
        flex: 1,
        child: _GlassCard(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NGÀY LẬP',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: '2023-10-27', // Placeholder for date picker
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.calendar_today),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NGÀY HẾT HẠN',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: '2023-11-26', // Placeholder
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.event),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
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
    ];

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    } else {
      return Column(
        children: children.map((e) => e is Expanded ? e.child : e).toList(),
      );
    }
  }

  Widget _buildLineItems(BuildContext context, ThemeData theme, bool isDesktop) {
    return _GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết mục',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (isDesktop)
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
              ),
              child: Row(
                children: [
                  Expanded(flex: 6, child: Text('MÔ TẢ', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                  Expanded(flex: 2, child: Text('SL', textAlign: TextAlign.right, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                  Expanded(flex: 2, child: Text('ĐƠN GIÁ', textAlign: TextAlign.right, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                  Expanded(flex: 2, child: Text('THÀNH TIỀN', textAlign: TextAlign.right, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                  const SizedBox(width: 40), // for delete icon
                ],
              ),
            ),
          const SizedBox(height: 16),
          // Single row placeholder
          _buildItemRow(context, theme, isDesktop),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm mục'),
            style: TextButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainer,
              foregroundColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, ThemeData theme, bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 6,
            child: _buildTextField(theme, hint: 'Mô tả dịch vụ hoặc sản phẩm'),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildTextField(theme, hint: '1', textAlign: TextAlign.right),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildTextField(theme, hint: '0.00', textAlign: TextAlign.right),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              '\$0.00',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.close),
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MÔ TẢ', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          _buildTextField(theme, hint: 'Mô tả dịch vụ hoặc sản phẩm'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SL', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    _buildTextField(theme, hint: '1', textAlign: TextAlign.right),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ĐƠN GIÁ', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    _buildTextField(theme, hint: '0.00', textAlign: TextAlign.right),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Thành tiền:', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text('\$0.00', style: theme.textTheme.bodyLarge?.copyWith(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close), color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
          const Divider(),
        ],
      );
    }
  }

  Widget _buildTextField(ThemeData theme, {String? hint, TextAlign textAlign = TextAlign.left}) {
    return TextFormField(
      textAlign: textAlign,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildTotalsAndNotes(BuildContext context, ThemeData theme, bool isDesktop) {
    final children = [
      Expanded(
        flex: 1,
        child: _GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GHI CHÚ CHO KHÁCH HÀNG',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Cảm ơn bạn đã hợp tác.',
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ĐIỀU KHOẢN & ĐIỀU KIỆN',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Thanh toán trong vòng 30 ngày.',
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      if (isDesktop) const SizedBox(width: 24) else const SizedBox(height: 24),
      Expanded(
        flex: 1,
        child: _GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow(theme, 'Tổng phụ', '\$0.00'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Chiết khấu %', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: _buildTextField(theme, hint: '0', textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                  Text('-\$0.00', style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'Inter', color: theme.colorScheme.primary)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Thuế %', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: _buildTextField(theme, hint: '0', textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                  Text('+\$0.00', style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'Inter', color: theme.colorScheme.primary)),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tổng cộng', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  Text('\$0.00', style: theme.textTheme.headlineMedium?.copyWith(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      side: BorderSide(color: theme.colorScheme.primary),
                      foregroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Lưu nháp'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/invoicing/preview'), // Will navigate to preview
                    icon: const Icon(Icons.visibility),
                    label: const Text('Xem trước'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ];

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    } else {
      return Column(
        children: children.map((e) => e is Expanded ? e.child : e).toList(),
      );
    }
  }

  Widget _buildSummaryRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'Inter', color: theme.colorScheme.primary)),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({required this.child, this.padding = const EdgeInsets.all(24)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }
}
