import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_finance/ui/widgets/glass_card.dart';
import 'package:smart_finance/ui/widgets/page_header.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              const PageHeader(
                title: 'Tổng quan',
                subtitle: 'Dưới đây là tóm tắt tài chính của bạn hôm nay.',
              ),
              const SizedBox(height: 32),

              // Bento Grid Layout
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 768) {
                    return _buildDesktopLayout(context, theme);
                  }
                  return _buildMobileLayout(context, theme);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: _buildTotalBalanceCard(context, theme),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 8,
              child: _buildCashFlowChart(context, theme),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: _buildUpcomingBills(context, theme, true),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 6,
              child: _buildRecentTransactions(context, theme, true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        _buildTotalBalanceCard(context, theme),
        const SizedBox(height: 16),
        _buildCashFlowChart(context, theme),
        const SizedBox(height: 16),
        _buildUpcomingBills(context, theme, false),
        const SizedBox(height: 16),
        _buildRecentTransactions(context, theme, false),
      ],
    );
  }

  Widget _buildTotalBalanceCard(BuildContext context, ThemeData theme) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TỔNG SỐ DƯ',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              Icon(Icons.account_balance_wallet, color: theme.colorScheme.secondary),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '\$124,500.00',
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.trending_up, color: theme.colorScheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                '+2.4% so với tháng trước',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowChart(BuildContext context, ThemeData theme) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dòng tiền',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'Tháng này',
                    isDense: true,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Tháng này', child: Text('Tháng này')),
                      DropdownMenuItem(value: '30 ngày qua', child: Text('30 ngày qua')),
                      DropdownMenuItem(value: 'Năm nay', child: Text('Năm nay')),
                    ],
                    onChanged: (value) {},
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(fontSize: 12);
                        Widget text;
                        switch (value.toInt()) {
                          case 0: text = const Text('T2', style: style); break;
                          case 1: text = const Text('T3', style: style); break;
                          case 2: text = const Text('T4', style: style); break;
                          case 3: text = const Text('T5', style: style); break;
                          case 4: text = const Text('T6', style: style); break;
                          case 5: text = const Text('T7', style: style); break;
                          case 6: text = const Text('CN', style: style); break;
                          default: text = const Text('', style: style); break;
                        }
                        return SideTitleWidget(meta: meta, child: text);
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 0.4, color: theme.colorScheme.secondary, width: 24, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 0.2, color: theme.colorScheme.error, width: 24, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 0.6, color: theme.colorScheme.secondary, width: 24, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 0.3, color: theme.colorScheme.error, width: 24, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 0.8, color: theme.colorScheme.secondary, width: 24, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
                  BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 0.45, color: theme.colorScheme.error, width: 24, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
                  BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 0.9, color: theme.colorScheme.secondary, width: 24, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingBills(BuildContext context, ThemeData theme, bool isDesktop) {
    return GlassCard(
      padding: isDesktop ? EdgeInsets.zero : const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: isDesktop ? const EdgeInsets.all(24.0) : EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hóa đơn sắp tới',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('Xem tất cả', style: TextStyle(color: theme.colorScheme.primary)),
                ),
              ],
            ),
          ),
          if (isDesktop) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 500),
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(theme.colorScheme.surfaceContainer),
                  columns: const [
                    DataColumn(label: Text('Hóa đơn')),
                    DataColumn(label: Text('Ngày đến hạn')),
                    DataColumn(label: Text('Số tiền')),
                  ],
                  rows: [
                    DataRow(cells: [
                      DataCell(Row(
                        children: [
                          Icon(Icons.description, color: theme.colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          const Text('Lưu trữ AWS', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )),
                      const DataCell(Text('Đến hạn trong 2 ngày')),
                      const DataCell(Text('\$450.00', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'))),
                    ]),
                    DataRow(cells: [
                      DataCell(Row(
                        children: [
                          Icon(Icons.home_work, color: theme.colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          const Text('Thuê văn phòng', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )),
                      const DataCell(Text('Đến hạn trong 5 ngày')),
                      const DataCell(Text('\$2,100.00', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'))),
                    ]),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            _buildBillItem(
              context,
              theme,
              icon: Icons.description,
              title: 'Lưu trữ AWS',
              subtitle: 'Đến hạn trong 2 ngày',
              amount: '\$450.00',
              iconColor: theme.colorScheme.error,
              iconBg: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            _buildBillItem(
              context,
              theme,
              icon: Icons.home_work,
              title: 'Thuê văn phòng',
              subtitle: 'Đến hạn trong 5 ngày',
              amount: '\$2,100.00',
              iconColor: theme.colorScheme.error,
              iconBg: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, ThemeData theme, bool isDesktop) {
    return GlassCard(
      padding: isDesktop ? EdgeInsets.zero : const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: isDesktop ? const EdgeInsets.all(24.0) : EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Giao dịch gần đây',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('Xem tất cả', style: TextStyle(color: theme.colorScheme.primary)),
                ),
              ],
            ),
          ),
          if (isDesktop) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 500),
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(theme.colorScheme.surfaceContainer),
                  columns: const [
                    DataColumn(label: Text('Giao dịch')),
                    DataColumn(label: Text('Ngày')),
                    DataColumn(label: Text('Số tiền')),
                  ],
                  rows: [
                    DataRow(cells: [
                      DataCell(Row(
                        children: [
                          Icon(Icons.arrow_downward, color: theme.colorScheme.secondary, size: 20),
                          const SizedBox(width: 8),
                          const Text('Hóa đơn khách hàng #1024', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )),
                      const DataCell(Text('Hôm nay, 2:30 CH')),
                      DataCell(Text('+\$3,400.00', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontFamily: 'Inter'))),
                    ]),
                    DataRow(cells: [
                      DataCell(Row(
                        children: [
                          Icon(Icons.shopping_cart, color: theme.colorScheme.onSurfaceVariant, size: 20),
                          const SizedBox(width: 8),
                          const Text('Văn phòng phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )),
                      const DataCell(Text('Hôm qua')),
                      DataCell(Text('-\$125.50', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontFamily: 'Inter'))),
                    ]),
                    DataRow(cells: [
                      DataCell(Row(
                        children: [
                          Icon(Icons.arrow_downward, color: theme.colorScheme.secondary, size: 20),
                          const SizedBox(width: 8),
                          const Text('Chuyển khoản Stripe', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )),
                      const DataCell(Text('24 tháng 10, 2023')),
                      DataCell(Text('+\$850.00', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontFamily: 'Inter'))),
                    ]),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            _buildTransactionItem(
              context,
              theme,
              icon: Icons.arrow_downward,
              title: 'Hóa đơn khách hàng #1024',
              subtitle: 'Hôm nay, 2:30 CH',
              amount: '+\$3,400.00',
              isPositive: true,
            ),
            const Divider(height: 24),
            _buildTransactionItem(
              context,
              theme,
              icon: Icons.shopping_cart,
              title: 'Văn phòng phẩm',
              subtitle: 'Hôm qua',
              amount: '-\$125.50',
              isPositive: false,
            ),
            const Divider(height: 24),
            _buildTransactionItem(
              context,
              theme,
              icon: Icons.arrow_downward,
              title: 'Chuyển khoản Stripe',
              subtitle: '24 tháng 10, 2023',
              amount: '+\$850.00',
              isPositive: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillItem(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            amount,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required bool isPositive,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPositive
                    ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.2)
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isPositive ? theme.colorScheme.secondary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        Text(
          amount,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isPositive ? theme.colorScheme.secondary : theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}


