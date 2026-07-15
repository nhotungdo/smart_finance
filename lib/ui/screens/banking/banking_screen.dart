import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_finance/ui/widgets/glass_card.dart';
import 'package:smart_finance/ui/widgets/page_header.dart';


class BankingScreen extends StatelessWidget {
  const BankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width > 768;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              PageHeader(
                title: 'Ngân hàng & Tài khoản',
                subtitle: 'Quản lý các tài khoản đã liên kết và thanh khoản của bạn.',
                action: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Liên kết tài khoản mới'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: theme.textTheme.labelLarge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              // Layout
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 1024) { // lg in Tailwind
                    return _buildDesktopLayout(context, theme);
                  }
                  return _buildMobileLayout(context, theme);
                },
              ),

              const SizedBox(height: 32),

              // Recent Activity Section
              Text(
                'Hoạt động ngân hàng gần đây',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildRecentActivity(context, theme, isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, ThemeData theme, bool isDesktop) {
    if (isDesktop) {
      return GlassCard(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 800),
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(theme.colorScheme.surfaceContainer),
              columns: const [
                DataColumn(label: Text('Hoạt động')),
                DataColumn(label: Text('Tài khoản')),
                DataColumn(label: Text('Ngày')),
                DataColumn(label: Text('Số tiền')),
                DataColumn(label: Text('Trạng thái')),
              ],
              rows: [
                DataRow(cells: [
                  DataCell(Row(
                    children: [
                      Icon(Icons.arrow_downward, color: theme.colorScheme.secondary, size: 20),
                      const SizedBox(width: 8),
                      const Text('Thanh toán Stripe', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )),
                  const DataCell(Text('Chase Business')),
                  const DataCell(Text('Hôm nay, 9:00 SA')),
                  DataCell(Text('+\$4,250.00', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontFamily: 'Inter'))),
                  const DataCell(Text('Hoàn thành')),
                ]),
                DataRow(cells: [
                  DataCell(Row(
                    children: [
                      Icon(Icons.arrow_upward, color: theme.colorScheme.onSurfaceVariant, size: 20),
                      const SizedBox(width: 8),
                      const Text('Dịch vụ Đám mây AWS', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )),
                  const DataCell(Text('Chase Business')),
                  const DataCell(Text('Hôm qua')),
                  const DataCell(Text('-\$850.00', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'))),
                  const DataCell(Text('Hoàn thành')),
                ]),
                DataRow(cells: [
                  DataCell(Row(
                    children: [
                      Icon(Icons.sync_alt, color: theme.colorScheme.secondary, size: 20),
                      const SizedBox(width: 8),
                      const Text('Chuyển sang tiết kiệm', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )),
                  const DataCell(Text('Tiết kiệm BoA')),
                  const DataCell(Text('24 tháng 10')),
                  DataCell(Text('+\$5,000.00', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontFamily: 'Inter'))),
                  const DataCell(Text('Hoàn thành')),
                ]),
              ],
            ),
          ),
        ),
      );
    } else {
      return GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _buildActivityItem(
              context,
              theme,
              icon: Icons.arrow_downward,
              title: 'Thanh toán Stripe',
              subtitle: 'Chase Business • Hôm nay, 9:00 SA',
              amount: '+\$4,250.00',
              isPositive: true,
              status: 'Hoàn thành',
            ),
            const Divider(height: 1),
            _buildActivityItem(
              context,
              theme,
              icon: Icons.arrow_upward,
              title: 'Dịch vụ Đám mây AWS',
              subtitle: 'Chase Business • Hôm qua',
              amount: '-\$850.00',
              isPositive: false,
              status: 'Hoàn thành',
            ),
            const Divider(height: 1),
            _buildActivityItem(
              context,
              theme,
              icon: Icons.sync_alt,
              title: 'Chuyển sang tiết kiệm',
              subtitle: 'Tiết kiệm BoA • 24 tháng 10',
              amount: '+\$5,000.00',
              isPositive: true,
              status: 'Hoàn thành',
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDesktopLayout(BuildContext context, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 4,
          child: _buildTotalLiquidityBox(context, theme),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 8,
          child: _buildLinkedAccountsGrid(context, theme, true),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        _buildTotalLiquidityBox(context, theme),
        const SizedBox(height: 24),
        _buildLinkedAccountsGrid(context, theme, false),
      ],
    );
  }

  Widget _buildTotalLiquidityBox(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TỔNG THANH KHOẢN',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '\$142,500.00',
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
          // Decorative graphic could go here, omitting for simplicity
        ],
      ),
    );
  }

  Widget _buildLinkedAccountsGrid(BuildContext context, ThemeData theme, bool isDesktop) {
    final children = [
      _buildAccountCard(
        context,
        theme,
        title: 'Chase Business',
        subtitle: 'Tài khoản thanh toán •••• 4289',
        balance: '\$85,200.50',
        icon: Icons.account_balance,
        iconBg: theme.colorScheme.primaryContainer,
        iconColor: theme.colorScheme.onPrimaryContainer,
      ),
      _buildAccountCard(
        context,
        theme,
        title: 'Tiết kiệm BoA',
        subtitle: 'Tiết kiệm •••• 9921',
        balance: '\$57,299.50',
        icon: Icons.savings,
        iconBg: theme.colorScheme.surfaceContainerHighest,
        iconColor: theme.colorScheme.onSurfaceVariant,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: children
            .map((e) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: children.last == e ? 0 : 24.0),
                    child: e,
                  ),
                ))
            .toList(),
      );
    } else {
      return Column(
        children: children
            .map((e) => Padding(
                  padding: EdgeInsets.only(bottom: children.last == e ? 0 : 24.0),
                  child: e,
                ))
            .toList(),
      );
    }
  }

  Widget _buildAccountCard(
    BuildContext context,
    ThemeData theme, {
    required String title,
    required String subtitle,
    required String balance,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync, size: 14, color: theme.colorScheme.onSecondaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      'Đã đồng bộ',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Số dư khả dụng',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            balance,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required bool isPositive,
    required String status,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPositive ? theme.colorScheme.secondary : theme.colorScheme.onSurface,
                  fontFamily: 'Inter', // Or your mono font
                ),
              ),
              Text(
                status,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


