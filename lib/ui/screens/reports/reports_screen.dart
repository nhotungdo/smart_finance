import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/bento_grid.dart';
import 'package:smart_finance/ui/widgets/page_header.dart';
import 'package:smart_finance/providers/reports_provider.dart';
import 'package:smart_finance/data/models/report_model.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _isCashFlow = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width > 768;
    final reportState = ref.watch(reportsProvider);
    final selectedPeriod = ref.watch(reportPeriodProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: 'Báo cáo tài chính',
                  subtitle: 'Phân tích chi tiết theo từng kỳ báo cáo.',
                  action: _buildToggle(theme),
                ),
                const SizedBox(height: 16),
                // ── Bộ lọc thời gian ──
                _PeriodFilterBar(
                  selected: selectedPeriod,
                  onChanged: (p) =>
                      ref.read(reportPeriodProvider.notifier).update(p),
                ),
                const SizedBox(height: 24),
                reportState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 12),
                        Text('Lỗi tải báo cáo: $err',
                            style: TextStyle(color: theme.colorScheme.error)),
                      ],
                    ),
                  ),
                  data: (reportExt) {
                    final barChart = _buildBarChartCard(theme, reportExt);
                    final pieChart = _buildPieChartCard(theme, reportExt);
                    final summaryTable = _buildSummaryTable(context, theme, isDesktop, reportExt);

                    return BentoGrid(
                      children: [
                        BentoItem(
                          colSpan: 2,
                          child: barChart,
                        ),
                        BentoItem(
                          colSpan: 1,
                          child: pieChart,
                        ),
                        BentoItem(
                          colSpan: 3,
                          child: summaryTable,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            title: 'Dòng tiền',
            isSelected: _isCashFlow,
            onTap: () => setState(() => _isCashFlow = true),
          ),
          _ToggleBtn(
            title: 'Cân đối kế toán',
            isSelected: !_isCashFlow,
            onTap: () => setState(() => _isCashFlow = false),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartCard(ThemeData theme, ReportDataExtended ext) {
    return BentoCard(
      showAccentStrip: true,
      accentColor: theme.colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Lãi & Lỗ',
                  style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold)),
              Row(children: [
                _Dot(color: theme.colorScheme.primary, label: 'Thu'),
                const SizedBox(width: 12),
                _Dot(color: theme.colorScheme.error, label: 'Chi'),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _rangeLabel(ext),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: ext.current.profitLossChart.isEmpty
                ? _emptyChart(theme)
                : _BarChartWidget(
                    data: ext.current.profitLossChart,
                    theme: theme,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(ThemeData theme, ReportDataExtended ext) {
    return BentoCard(
      showAccentStrip: true,
      accentColor: const Color(0xFF10B981),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phân tích chi phí',
              style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ext.current.expenseAnalysis.isEmpty
                ? _emptyChart(theme)
                : _PieChartWidget(data: ext.current.expenseAnalysis),
          ),
          const SizedBox(height: 16),
          _buildLegends(theme, ext.current.expenseAnalysis),
        ],
      ),
    );
  }

  String _rangeLabel(ReportDataExtended ext) {
    final fmt = DateFormat('dd/MM/yyyy');
    return '${fmt.format(ext.dateRange.start)} – ${fmt.format(ext.dateRange.end)}';
  }

  Widget _emptyChart(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Text('Không có dữ liệu trong kỳ này',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildLegends(ThemeData theme, List<ExpenseAnalysisModel> data) {
    if (data.isEmpty) return const SizedBox.shrink();
    final top = data.take(6).toList();
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: top.map((e) {
        final color = _parseColor(e.colorCode);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              '${e.categoryName} (${e.percentage.toStringAsFixed(0)}%)',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSummaryTable(BuildContext context, ThemeData theme,
      bool isDesktop, ReportDataExtended ext) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final cur = ext.current.summary;
    final prev = ext.previous;

    String trend(double c, double p) => ext.trendLabel(c, p);
    bool positive(double c, double p) => ext.isTrendPositive(c, p);

    final rows = _isCashFlow
        ? [
            _SummaryRow(
              label: 'Tổng thu nhập',
              current: currency.format(cur.totalIncome),
              previous: currency.format(prev.totalIncome),
              trend: trend(cur.totalIncome, prev.totalIncome),
              isPositive: positive(cur.totalIncome, prev.totalIncome),
            ),
            _SummaryRow(
              label: 'Tổng chi phí',
              current: currency.format(cur.totalExpense),
              previous: currency.format(prev.totalExpense),
              trend: trend(cur.totalExpense, prev.totalExpense),
              isPositive: !positive(cur.totalExpense, prev.totalExpense),
            ),
            _SummaryRow(
              label: 'Lợi nhuận ròng',
              current: currency.format(cur.netProfit),
              previous: currency.format(prev.netProfit),
              trend: trend(cur.netProfit, prev.netProfit),
              isPositive: positive(cur.netProfit, prev.netProfit),
              isTotal: true,
            ),
          ]
        : [
            _SummaryRow(
              label: 'Tài sản hiện tại',
              current: currency.format(cur.currentAssets),
              previous: currency.format(prev.currentAssets),
              trend: trend(cur.currentAssets, prev.currentAssets),
              isPositive: positive(cur.currentAssets, prev.currentAssets),
            ),
            _SummaryRow(
              label: 'Nợ phải trả',
              current: currency.format(cur.currentLiabilities),
              previous: currency.format(prev.currentLiabilities),
              trend: trend(cur.currentLiabilities, prev.currentLiabilities),
              isPositive:
                  !positive(cur.currentLiabilities, prev.currentLiabilities),
            ),
            _SummaryRow(
              label: 'Vốn chủ sở hữu',
              current: currency.format(cur.totalEquity),
              previous: currency.format(prev.totalEquity),
              trend: trend(cur.totalEquity, prev.totalEquity),
              isPositive: positive(cur.totalEquity, prev.totalEquity),
              isTotal: true,
            ),
          ];

    return BentoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              border: Border(
                  bottom: BorderSide(
                      color:
                          theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Text(
              _isCashFlow ? 'Tóm tắt Dòng tiền' : 'Tóm tắt Cân đối kế toán',
              style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold),
            ),
          ),
          if (isDesktop)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 700),
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(
                      theme.colorScheme.surfaceContainer),
                  columns: const [
                    DataColumn(label: Text('DANH MỤC')),
                    DataColumn(label: Text('KỲ HIỆN TẠI'), numeric: true),
                    DataColumn(label: Text('KỲ TRƯỚC'), numeric: true),
                    DataColumn(label: Text('THAY ĐỔI'), numeric: true),
                  ],
                  rows: rows
                      .map((r) => _buildDataRow(theme, r))
                      .toList(),
                ),
              ),
            )
          else
            Column(
              children: rows
                  .map((r) => _buildMobileRow(theme, r))
                  .toList(),
            ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(ThemeData theme, _SummaryRow r) {
    final bold = r.isTotal;
    final base = bold
        ? theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary, fontWeight: FontWeight.bold)
        : theme.textTheme.bodyMedium;
    return DataRow(
      color: bold
          ? WidgetStatePropertyAll(
              theme.colorScheme.surface.withValues(alpha: 0.5))
          : null,
      cells: [
        DataCell(Text(r.label, style: base)),
        DataCell(Text(r.current, style: base)),
        DataCell(Text(r.previous,
            style: base?.copyWith(
                color: theme.colorScheme.onSurfaceVariant))),
        DataCell(Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              r.isPositive ? Icons.trending_up : Icons.trending_down,
              size: 14,
              color: r.isPositive
                  ? Colors.green.shade600
                  : theme.colorScheme.error,
            ),
            const SizedBox(width: 4),
            Text(r.trend,
                style: base?.copyWith(
                    color: r.isPositive
                        ? Colors.green.shade600
                        : theme.colorScheme.error)),
          ],
        )),
      ],
    );
  }

  Widget _buildMobileRow(ThemeData theme, _SummaryRow r) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.label,
                        style: r.isTotal
                            ? theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold)
                            : theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text('Kỳ trước: ${r.previous}',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(r.current,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      Icon(
                        r.isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 12,
                        color: r.isPositive
                            ? Colors.green.shade600
                            : theme.colorScheme.error,
                      ),
                      const SizedBox(width: 2),
                      Text(r.trend,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: r.isPositive
                                  ? Colors.green.shade600
                                  : theme.colorScheme.error,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Color _parseColor(String code) {
    try {
      return Color(int.parse(code.replaceFirst('#', '0xff')));
    } catch (_) {
      return Colors.grey;
    }
  }
}

// ─── Data class nội bộ cho summary row ───────────────────────
class _SummaryRow {
  final String label;
  final String current;
  final String previous;
  final String trend;
  final bool isPositive;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.current,
    required this.previous,
    required this.trend,
    required this.isPositive,
    this.isTotal = false,
  });
}

// ─── Bộ lọc thời gian ────────────────────────────────────────
class _PeriodFilterBar extends StatelessWidget {
  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onChanged;

  const _PeriodFilterBar(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ReportPeriod.values
            .map((period) {
          final isSelected = selected == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onChanged(period),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    period.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Bar Chart Widget ─────────────────────────────────────────
class _BarChartWidget extends StatelessWidget {
  final List<ChartDataPoint> data;
  final ThemeData theme;

  const _BarChartWidget({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    double maxY = data.fold(0.0, (m, p) {
      final v = p.value1 > p.value2 ? p.value1 : p.value2;
      return v > m ? v : m;
    });
    if (maxY == 0) maxY = 1000;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.25,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) =>
                theme.colorScheme.surfaceContainerHighest,
            getTooltipItem: (group, gi, rod, ri) {
              final lbl = ri == 0 ? 'Thu' : 'Chi';
              final val = NumberFormat.compactCurrency(
                      locale: 'vi_VN', symbol: '₫')
                  .format(rod.toY);
              return BarTooltipItem(
                '$lbl: $val',
                TextStyle(
                    color: theme.colorScheme.onSurface, fontSize: 11),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(data[i].label,
                      style: TextStyle(
                          fontSize: 10,
                          color:
                              theme.colorScheme.onSurfaceVariant)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (v, meta) {
                if (v == 0) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    NumberFormat.compactCurrency(
                            locale: 'vi_VN', symbol: '₫')
                        .format(v),
                    style: TextStyle(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color:
                theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: e.value.value1,
                color: theme.colorScheme.primary,
                width: 10,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: e.value.value2,
                color: theme.colorScheme.error,
                width: 10,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Pie Chart Widget ─────────────────────────────────────────
class _PieChartWidget extends StatelessWidget {
  final List<ExpenseAnalysisModel> data;
  const _PieChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 36,
        sections: data.map((e) {
          Color color;
          try {
            color =
                Color(int.parse(e.colorCode.replaceFirst('#', '0xff')));
          } catch (_) {
            color = Colors.grey;
          }
          return PieChartSectionData(
            color: color,
            value: e.percentage,
            title: e.percentage > 6
                ? '${e.percentage.toStringAsFixed(0)}%'
                : '',
            radius: 48,
            titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Toggle Button ────────────────────────────────────────────
class _ToggleBtn extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleBtn(
      {required this.title,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Legend dot ───────────────────────────────────────────────
class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }
}
