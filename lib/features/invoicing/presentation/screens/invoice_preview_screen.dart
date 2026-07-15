import 'package:flutter/material.dart';

class InvoicePreviewScreen extends StatelessWidget {
  const InvoicePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width > 768;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 896),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {},
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Xem trước hóa đơn',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Chỉnh sửa'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            side: BorderSide(color: theme.colorScheme.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.send, size: 18),
                          label: const Text('Gửi hóa đơn'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Document Container
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // Document Paper Edge Decoration
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.secondaryContainer,
                              theme.colorScheme.secondary,
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header Section
                            _buildHeaderSection(theme, isDesktop),
                            const SizedBox(height: 32),
                            const Divider(),
                            const SizedBox(height: 32),

                            // Client Section
                            _buildClientSection(theme),
                            const SizedBox(height: 32),

                            // Itemized Table
                            _buildItemTable(theme, isDesktop),
                            const SizedBox(height: 32),

                            // Totals Section
                            _buildTotalsSection(theme, isDesktop),
                          ],
                        ),
                      ),
                      // Footer Ribbon
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Được cung cấp bởi SmartFinance', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            Row(
                              children: [
                                Icon(Icons.verified, size: 16, color: theme.colorScheme.secondary),
                                const SizedBox(width: 4),
                                Text('Hóa đơn bảo mật', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ],
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
    );
  }

  Widget _buildHeaderSection(ThemeData theme, bool isDesktop) {
    return Flex(
      direction: isDesktop ? Axis.horizontal : Axis.vertical,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.account_balance, color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Text('SmartFinance', style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Công ty TNHH SmartFinance SME', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
            Text('123 Khu tài chính, Phòng 400', style: theme.textTheme.bodySmall),
            Text('New York, NY 10004', style: theme.textTheme.bodySmall),
            Text('contact@smartfinance.com', style: theme.textTheme.bodySmall),
            Text('+1 (555) 123-4567', style: theme.textTheme.bodySmall),
          ],
        ),
        if (!isDesktop) const SizedBox(height: 24),
        Column(
          crossAxisAlignment: isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text('HÓA ĐƠN', style: theme.textTheme.headlineLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildMetaRow(theme, 'Số hóa đơn:', 'INV-2023-089', isDesktop),
            _buildMetaRow(theme, 'Ngày:', '15 tháng 10, 2023', isDesktop),
            _buildMetaRow(theme, 'Ngày đến hạn:', '30 tháng 10, 2023', isDesktop),
          ],
        ),
      ],
    );
  }

  Widget _buildMetaRow(ThemeData theme, String label, String value, bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: isDesktop ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 16),
          Text(value, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'Inter', color: theme.colorScheme.primary)),
        ],
      ),
    );
  }

  Widget _buildClientSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('THANH TOÁN CHO', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('Acme Corporation', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Jane Doe, Kế toán công nợ', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text('456 Corporate Blvd, Tòa nhà B', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text('San Francisco, CA 94107', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text('accounting@acmecorp.com', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildItemTable(ThemeData theme, bool isDesktop) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3), width: 2)),
          ),
          child: Row(
            children: [
              Expanded(flex: 6, child: Text('Mô tả', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
              Expanded(flex: 2, child: Text('SL', textAlign: TextAlign.center, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
              Expanded(flex: 2, child: Text('Đơn giá', textAlign: TextAlign.right, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
              Expanded(flex: 2, child: Text('Thành tiền', textAlign: TextAlign.right, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
            ],
          ),
        ),
        _buildTableRow(theme, 'Dịch vụ tư vấn', 'Lập kế hoạch và đánh giá chiến lược tài chính Q3', '40', '\$150.00', '\$6,000.00'),
        _buildTableRow(theme, 'Chuẩn bị thuế', 'Chuẩn bị và nộp hồ sơ hàng quý', '1', '\$1,200.00', '\$1,200.00'),
        _buildTableRow(theme, 'Giấy phép phần mềm', 'Gia hạn đăng ký hàng năm cho gói Doanh nghiệp', '1', '\$450.00', '\$450.00'),
      ],
    );
  }

  Widget _buildTableRow(ThemeData theme, String title, String subtitle, String qty, String rate, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.surfaceContainerHigh)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(qty, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'Inter'))),
          Expanded(flex: 2, child: Text(rate, textAlign: TextAlign.right, style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'Inter'))),
          Expanded(flex: 2, child: Text(amount, textAlign: TextAlign.right, style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: theme.colorScheme.primary))),
        ],
      ),
    );
  }

  Widget _buildTotalsSection(ThemeData theme, bool isDesktop) {
    final children = [
      Expanded(
        flex: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ĐIỀU KHOẢN THANH TOÁN & GHI CHÚ', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Thanh toán trong vòng 15 ngày. Vui lòng ghi số hóa đơn trên séc hoặc khi chuyển khoản ngân hàng. Thanh toán trễ có thể phải chịu phí 1.5% hàng tháng. Cảm ơn bạn đã hợp tác!',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
      if (isDesktop) const SizedBox(width: 48) else const SizedBox(height: 24),
      Expanded(
        flex: 2,
        child: Column(
          children: [
            _buildTotalRow(theme, 'Tổng phụ', '\$7,650.00'),
            const SizedBox(height: 8),
            _buildTotalRow(theme, 'Thuế (8%)', '\$612.00'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tổng cộng', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  Text('\$8,262.00', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    ];

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    } else {
      return Column(
        children: children.map((e) => e is Expanded ? e.child : e).toList(),
      );
    }
  }

  Widget _buildTotalRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'Inter', color: theme.colorScheme.primary)),
        ],
      ),
    );
  }
}
