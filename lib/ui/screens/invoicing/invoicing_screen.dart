import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_finance/ui/widgets/glass_card.dart';
import 'package:smart_finance/ui/widgets/page_header.dart';


class InvoicingScreen extends StatelessWidget {
  const InvoicingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width > 768;

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by MainLayout
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/invoicing/create'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: const Icon(Icons.add),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Action
                PageHeader(
                  title: 'Tổng quan hóa đơn',
                  subtitle: 'Quản lý và theo dõi hóa đơn doanh nghiệp của bạn.',
                  action: isDesktop
                      ? ElevatedButton.icon(
                          onPressed: () => context.push('/invoicing/create'),
                          icon: const Icon(Icons.add),
                          label: const Text('Tạo hóa đơn mới'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            textStyle: theme.textTheme.labelLarge,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 32),

                // Summary Cards
                _buildSummaryCards(context, theme, isDesktop),
                const SizedBox(height: 32),

                // Invoice List Section
                _buildInvoiceListSection(context, theme, isDesktop),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, ThemeData theme, bool isDesktop) {
    final children = [
      Expanded(
        flex: isDesktop ? 2 : 1,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TỔNG CHƯA THANH TOÁN',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$45,230.00',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.trending_up, color: theme.colorScheme.secondary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '+12% so với tháng trước',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      if (isDesktop) const SizedBox(width: 24) else const SizedBox(height: 24),
      Expanded(
        flex: 1,
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: theme.colorScheme.error, width: 4)),
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SỐ TIỀN QUÁ HẠN',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.error,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Icon(Icons.warning, color: theme.colorScheme.error, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '\$8,450.00',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cần xử lý ngay (4 hóa đơn)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {},
                    child: Text(
                      'Xem hóa đơn quá hạn',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  Widget _buildInvoiceListSection(BuildContext context, ThemeData theme, bool isDesktop) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // List Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hóa đơn gần đây',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list),
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    if (isDesktop) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 250,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm hóa đơn...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerLowest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Table / List
          if (isDesktop)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 800),
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(theme.colorScheme.surfaceContainer),
                  columns: const [
                    DataColumn(label: Text('Mã hóa đơn')),
                    DataColumn(label: Text('Khách hàng')),
                    DataColumn(label: Text('Ngày')),
                    DataColumn(label: Text('Số tiền')),
                    DataColumn(label: Text('Trạng thái')),
                    DataColumn(label: Text('Hành động')),
                  ],
                  rows: [
                    _buildDataRow(theme, 'INV-2023-089', 'Acme Corp', '12 tháng 10, 2023', '\$3,200.00', 'Quá hạn'),
                    _buildDataRow(theme, 'INV-2023-090', 'TechSolutions Inc.', '15 tháng 10, 2023', '\$1,550.00', 'Đã thanh toán'),
                    _buildDataRow(theme, 'INV-2023-091', 'Global Logistics', '18 tháng 10, 2023', '\$8,900.00', 'Chờ xử lý'),
                    _buildDataRow(theme, 'INV-2023-092', 'Design Studio Co.', '20 tháng 10, 2023', '\$450.00', 'Chờ xử lý'),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                _buildMobileInvoiceItem(theme, 'INV-2023-089', 'Acme Corp', '12 tháng 10, 2023', '\$3,200.00', 'Quá hạn'),
                const Divider(height: 1),
                _buildMobileInvoiceItem(theme, 'INV-2023-090', 'TechSolutions Inc.', '15 tháng 10, 2023', '\$1,550.00', 'Đã thanh toán'),
                const Divider(height: 1),
                _buildMobileInvoiceItem(theme, 'INV-2023-091', 'Global Logistics', '18 tháng 10, 2023', '\$8,900.00', 'Chờ xử lý'),
                const Divider(height: 1),
                _buildMobileInvoiceItem(theme, 'INV-2023-092', 'Design Studio Co.', '20 tháng 10, 2023', '\$450.00', 'Chờ xử lý'),
              ],
            ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Xem tất cả hóa đơn',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(ThemeData theme, String id, String client, String date, String amount, String status) {
    return DataRow(
      cells: [
        DataCell(Text(id, style: const TextStyle(fontFamily: 'Inter'))),
        DataCell(Text(client, style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(date, style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
        DataCell(Text(amount, style: const TextStyle(fontFamily: 'Inter'))),
        DataCell(_buildStatusBadge(theme, status)),
        DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileInvoiceItem(ThemeData theme, String id, String client, String date, String amount, String status) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(client, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    _buildStatusBadge(theme, status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(id, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'Inter')),
                    Text(date, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(amount, style: theme.textTheme.bodyLarge?.copyWith(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Quá hạn':
        bgColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        break;
      case 'Đã thanh toán':
        bgColor = theme.colorScheme.secondaryContainer;
        textColor = theme.colorScheme.onSecondaryContainer;
        break;
      default:
        bgColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}


