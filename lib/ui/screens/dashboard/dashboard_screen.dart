import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/providers/dashboard_provider.dart';
import 'package:smart_finance/providers/sync_provider.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/bento_grid.dart';
import 'package:smart_finance/ui/widgets/page_header.dart';
import 'package:smart_finance/ui/widgets/sync_status_indicator.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final syncState = ref.watch(syncNotifierProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Tổng quan',
                subtitle: 'Tóm tắt tình hình tài chính của bạn hôm nay.',
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SyncStatusIndicator(),
                    const SizedBox(width: 12),
                    syncState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.sync_rounded),
                              tooltip: 'Đồng bộ dữ liệu',
                              color: theme.colorScheme.primary,
                              onPressed: () async {
                                await ref
                                    .read(syncNotifierProvider.notifier)
                                    .syncNow();
                                if (context.mounted) {
                                  final finalState = ref.read(
                                    syncNotifierProvider,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        finalState.error != null
                                            ? 'Lỗi đồng bộ: ${finalState.error}'
                                            : 'Đồng bộ thành công!',
                                      ),
                                      backgroundColor: finalState.error != null
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.primary,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isMobile = width < 600;

                  return BentoGrid(
                    mobileColumns: 2,
                    tabletColumns: 3,
                    desktopColumns: 3,
                    cellHeight: 180,
                    spacing: 16,
                    children: [
                      // ── Stats Row ──────────────────────────────────────
                      BentoItem(colSpan: 1, rowSpan: 1, child: _StatThuTile()),
                      BentoItem(colSpan: 1, rowSpan: 1, child: _StatChiTile()),
                      BentoItem(
                        colSpan: isMobile ? 2 : 1, // Full row on mobile
                        rowSpan: 1,
                        child: _StatDongTienTile(),
                      ),

                      // ── Chart & Recent ─────────────────────────────────
                      BentoItem(
                        colSpan: isMobile ? 2 : 2,
                        rowSpan: 2,
                        child: _CashFlowChartTile(),
                      ),
                      BentoItem(
                        colSpan: isMobile ? 2 : 1,
                        rowSpan: 2,
                        child: _RecentTransactionsTile(),
                      ),

                      // ── Grouped ────────────────────────────────────────
                      BentoItem(
                        colSpan: isMobile ? 2 : 3, // Full width always
                        rowSpan: 2,
                        child: _GroupedTransactionsTile(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat Tiles ──────────────────────────────────────────────────────────────
class _StatThuTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(financialSummaryProvider);
    final currencyFmt = NumberFormat.compactCurrency(
      locale: 'vi_VN',
      symbol: '₫',
    );

    return summaryAsync.when(
      loading: () =>
          const BentoCard(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => BentoCard(child: Center(child: Text('Lỗi'))),
      data: (summary) => BentoCard(
        showAccentStrip: true,
        accentColor: theme.colorScheme.primary,
        padding: const EdgeInsets.all(20),
        child: BentoIconTile(
          icon: Icons.trending_up_rounded,
          label: 'Tổng thu',
          value: currencyFmt.format(summary.totalIncome),
          accentColor: theme.colorScheme.primary,
          subtitle: 'Tháng này',
        ),
      ),
    );
  }
}

class _StatChiTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(financialSummaryProvider);
    final currencyFmt = NumberFormat.compactCurrency(
      locale: 'vi_VN',
      symbol: '₫',
    );

    return summaryAsync.when(
      loading: () =>
          const BentoCard(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => BentoCard(child: Center(child: Text('Lỗi'))),
      data: (summary) => BentoCard(
        showAccentStrip: true,
        accentColor: theme.colorScheme.error,
        padding: const EdgeInsets.all(20),
        child: BentoIconTile(
          icon: Icons.trending_down_rounded,
          label: 'Tổng chi',
          value: currencyFmt.format(summary.totalExpense),
          accentColor: theme.colorScheme.error,
          subtitle: 'Tháng này',
        ),
      ),
    );
  }
}

class _StatDongTienTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(financialSummaryProvider);
    final currencyFmt = NumberFormat.compactCurrency(
      locale: 'vi_VN',
      symbol: '₫',
    );

    return summaryAsync.when(
      loading: () =>
          const BentoCard(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => BentoCard(child: Center(child: Text('Lỗi'))),
      data: (summary) {
        final isPositive = summary.cashFlow >= 0;
        final color = isPositive
            ? theme.colorScheme.primary
            : theme.colorScheme.secondary;
        return BentoCard(
          showAccentStrip: true,
          accentColor: color,
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          padding: const EdgeInsets.all(20),
          child: BentoIconTile(
            icon: isPositive
                ? Icons.account_balance_wallet_rounded
                : Icons.warning_amber_rounded,
            label: 'Dòng tiền',
            value: currencyFmt.format(summary.cashFlow),
            accentColor: color,
            subtitle: 'Hiện tại',
          ),
        );
      },
    );
  }
}

// ─── Chart Tile ──────────────────────────────────────────────────────────────
class _CashFlowChartTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final chartAsync = ref.watch(cashFlowChartProvider);

    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BentoSectionHeader(
            title: 'Dòng tiền',
            subtitle: '7 ngày gần nhất',
            action: Row(
              children: [
                _LegendDot(color: theme.colorScheme.primary, label: 'Thu'),
                const SizedBox(width: 8),
                _LegendDot(color: theme.colorScheme.error, label: 'Chi'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: chartAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Lỗi',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
              data: (points) {
                if (points.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chưa có dữ liệu',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final maxVal = points.fold(0.0, (max, p) {
                  final m = (p.income > p.expense ? p.income : p.expense)
                      .toDouble();
                  return m > max ? m : max;
                });
                final maxY = maxVal == 0 ? 1.0 : maxVal * 1.2;

                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) =>
                            theme.colorScheme.surfaceContainerHighest,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final label = rodIndex == 0 ? 'Thu' : 'Chi';
                          final val = NumberFormat.compactCurrency(
                            locale: 'vi_VN',
                            symbol: '₫',
                          ).format(rod.toY);
                          return BarTooltipItem(
                            '$label: $val',
                            TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= points.length) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              space: 8,
                              child: Text(
                                points[idx].label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (val) => FlLine(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(points.length, (i) {
                      final p = points[i];
                      return BarChartGroupData(
                        x: i,
                        barsSpace: 6,
                        barRods: [
                          BarChartRodData(
                            toY: p.income.toDouble(),
                            color: theme.colorScheme.primary,
                            width: 14,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                          BarChartRodData(
                            toY: p.expense.toDouble(),
                            color: theme.colorScheme.error,
                            width: 12,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Recent Transactions Tile ────────────────────────────────────────────────
class _RecentTransactionsTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recentAsync = ref.watch(recentTransactionsProvider);
    final currencyFmt = NumberFormat.compactCurrency(
      locale: 'vi_VN',
      symbol: '₫',
    );

    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BentoSectionHeader(
            title: 'Gần đây',
            action: InkWell(
              onTap: () => context.go('/expenses'),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Tất cả',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: recentAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi')),
              data: (txList) {
                if (txList.isEmpty) {
                  return Center(
                    child: Text(
                      'Chưa có GD',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: txList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tx = txList[index];
                    final isIncome =
                        tx.transactionType == TransactionType.income;
                    final color = isIncome
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error;

                    return Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isIncome
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.description?.isNotEmpty == true
                                    ? tx.description!
                                    : (isIncome ? 'Thu nhập' : 'Chi tiêu'),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                DateFormat(
                                  'dd/MM HH:mm',
                                ).format(tx.transactionDate),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isIncome ? '+' : '-'}${currencyFmt.format(tx.amount)}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grouped Transactions Tile ───────────────────────────────────────────────
class _GroupedTransactionsTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groupedAsync = ref.watch(groupedTransactionsProvider);
    final currencyFmt = NumberFormat.compactCurrency(
      locale: 'vi_VN',
      symbol: '₫',
    );

    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BentoSectionHeader(
            title: 'Chi tiết theo ngày',
            subtitle: 'Lịch sử dòng tiền',
            action: Icon(
              Icons.calendar_month_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: groupedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi')),
              data: (groups) {
                if (groups.isEmpty) {
                  return Center(
                    child: Text(
                      'Chưa có dữ liệu',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                // Show up to 2 groups on dashboard to fit 2 rows
                final displayGroups = groups.take(2).toList();

                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayGroups.length,
                  separatorBuilder: (_, _) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final group = displayGroups[index];
                    final dayTotal = group.dayTotal;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              group.dateLabel,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              '${dayTotal >= 0 ? '+' : ''}${currencyFmt.format(dayTotal)}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: dayTotal >= 0
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...group.transactions.map((tx) {
                          final isIncome =
                              tx.transactionType == TransactionType.income;
                          final color = isIncome
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    tx.description?.isNotEmpty == true
                                        ? tx.description!
                                        : (isIncome ? 'Thu nhập' : 'Chi tiêu'),
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${isIncome ? '+' : '-'}${currencyFmt.format(tx.amount)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
