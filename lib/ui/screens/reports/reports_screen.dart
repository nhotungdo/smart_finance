import 'package:flutter/material.dart';
import 'package:smart_finance/ui/widgets/glass_card.dart';
import 'package:smart_finance/ui/widgets/page_header.dart';


class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isCashFlow = true;

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
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Toggle
                PageHeader(
                  title: 'Báo cáo tài chính',
                  subtitle: 'Thông tin trực quan cho doanh nghiệp của bạn.',
                  action: _buildToggle(theme),
                ),
                const SizedBox(height: 32),

                // Charts Area
                _buildChartsArea(context, theme, isDesktop),
                const SizedBox(height: 24),

                // Summary Table
                _buildSummaryTable(context, theme, isDesktop),
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
          _ToggleButton(
            title: 'Dòng tiền',
            isSelected: _isCashFlow,
            onTap: () => setState(() => _isCashFlow = true),
            theme: theme,
          ),
          _ToggleButton(
            title: 'Bảng cân đối kế toán',
            isSelected: !_isCashFlow,
            onTap: () => setState(() => _isCashFlow = false),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildChartsArea(BuildContext context, ThemeData theme, bool isDesktop) {
    final children = [
      Expanded(
        flex: isDesktop ? 2 : 1,
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lãi & Lỗ',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: 'YTD 2024',
                        items: ['YTD 2024', '2023'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: theme.textTheme.bodySmall),
                          );
                        }).toList(),
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                height: 250,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 64, color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                    Text(
                      'Biểu đồ (Placeholder)',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phân tích chi phí',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 200,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pie_chart, size: 64, color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                    Text(
                      'Biểu đồ Donut (Placeholder)',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildLegendItem(theme, 'Lương (45%)', theme.colorScheme.primary)),
                      Expanded(child: _buildLegendItem(theme, 'Phần mềm (25%)', theme.colorScheme.secondary)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildLegendItem(theme, 'Tiếp thị (20%)', theme.colorScheme.tertiaryContainer)),
                      Expanded(child: _buildLegendItem(theme, 'Khác (10%)', theme.colorScheme.outline)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ];

    if (isDesktop) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );
    } else {
      return Column(
        children: children.map((e) => e is Expanded ? e.child : e).toList(),
      );
    }
  }

  Widget _buildLegendItem(ThemeData theme, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTable(BuildContext context, ThemeData theme, bool isDesktop) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Text(
              _isCashFlow ? 'Tóm tắt Dòng tiền' : 'Tóm tắt Bảng cân đối kế toán',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isDesktop)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: isDesktop ? 800 : MediaQuery.sizeOf(context).width - 32),
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(theme.colorScheme.surface),
                  columns: const [
                    DataColumn(label: Text('DANH MỤC')),
                    DataColumn(label: Text('Q1'), numeric: true),
                    DataColumn(label: Text('Q2'), numeric: true),
                    DataColumn(label: Text('XU HƯỚNG'), numeric: true),
                  ],
                  rows: _isCashFlow ? _buildCashFlowRows(theme) : _buildBalanceSheetRows(theme),
                ),
              ),
            )
          else
            _buildMobileSummaryList(theme),
        ],
      ),
    );
  }

  Widget _buildMobileSummaryList(ThemeData theme) {
    if (_isCashFlow) {
      return Column(
        children: [
          _buildMobileSummaryCard(theme, 'Dòng tiền HĐKD', '\$24,500', '\$28,200', '+15%', true),
          const Divider(height: 1),
          _buildMobileSummaryCard(theme, 'Dòng tiền đầu tư', '-\$5,000', '-\$2,000', '-', null),
          const Divider(height: 1),
          _buildMobileSummaryCard(theme, 'Dòng tiền thuần', '\$19,500', '\$26,200', '+34%', true, isTotal: true),
        ],
      );
    } else {
      return Column(
        children: [
          _buildMobileSummaryCard(theme, 'Tài sản ngắn hạn', '\$145,000', '\$162,000', '+11%', true),
          const Divider(height: 1),
          _buildMobileSummaryCard(theme, 'Nợ ngắn hạn', '\$42,000', '\$48,500', '-15%', false),
          const Divider(height: 1),
          _buildMobileSummaryCard(theme, 'Tổng vốn chủ sở hữu', '\$103,000', '\$113,500', '+10%', true, isTotal: true),
        ],
      );
    }
  }

  Widget _buildMobileSummaryCard(ThemeData theme, String category, String q1, String q2, String trend, bool? isPositiveTrend, {bool isTotal = false}) {
    Color? trendColor;
    IconData? trendIcon;

    if (isPositiveTrend == true) {
      trendColor = theme.colorScheme.secondary;
      trendIcon = Icons.trending_up;
    } else if (isPositiveTrend == false) {
      trendColor = theme.colorScheme.error;
      trendIcon = Icons.trending_down;
    } else {
      trendColor = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      color: isTotal ? theme.colorScheme.surface.withValues(alpha: 0.5) : null,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: isTotal
                    ? theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)
                    : theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  if (trendIcon != null) Icon(trendIcon, size: 16, color: trendColor),
                  if (trendIcon != null) const SizedBox(width: 4),
                  Text(
                    trend,
                    style: theme.textTheme.bodyMedium?.copyWith(color: trendColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q1', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(q1, style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'Inter', fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Q2', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(q2, style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'Inter', fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<DataRow> _buildCashFlowRows(ThemeData theme) {
    return [
      _buildDataRow(theme, 'Dòng tiền HĐKD', '\$24,500', '\$28,200', '+15%', true),
      _buildDataRow(theme, 'Dòng tiền đầu tư', '-\$5,000', '-\$2,000', '-', null),
      _buildDataRow(theme, 'Dòng tiền thuần', '\$19,500', '\$26,200', '+34%', true, isTotal: true),
    ];
  }

  List<DataRow> _buildBalanceSheetRows(ThemeData theme) {
    return [
      _buildDataRow(theme, 'Tài sản ngắn hạn', '\$145,000', '\$162,000', '+11%', true),
      _buildDataRow(theme, 'Nợ ngắn hạn', '\$42,000', '\$48,500', '-15%', false),
      _buildDataRow(theme, 'Tổng vốn chủ sở hữu', '\$103,000', '\$113,500', '+10%', true, isTotal: true),
    ];
  }

  DataRow _buildDataRow(ThemeData theme, String category, String q1, String q2, String trend, bool? isPositiveTrend, {bool isTotal = false}) {
    Color? trendColor;
    IconData? trendIcon;

    if (isPositiveTrend == true) {
      trendColor = theme.colorScheme.secondary;
      trendIcon = Icons.trending_up;
    } else if (isPositiveTrend == false) {
      trendColor = theme.colorScheme.error;
      trendIcon = Icons.trending_down;
    } else {
      trendColor = theme.colorScheme.onSurfaceVariant;
    }

    final textStyle = isTotal
        ? theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)
        : theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface);

    final monoStyle = isTotal
        ? theme.textTheme.titleMedium?.copyWith(fontFamily: 'Inter', fontWeight: FontWeight.bold)
        : theme.textTheme.bodyMedium?.copyWith(fontFamily: 'Inter');

    return DataRow(
      color: isTotal ? WidgetStatePropertyAll(theme.colorScheme.surface.withValues(alpha: 0.5)) : null,
      cells: [
        DataCell(Text(category, style: textStyle)),
        DataCell(Text(q1, style: monoStyle)),
        DataCell(Text(q2, style: monoStyle)),
        DataCell(
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (trendIcon != null) Icon(trendIcon, size: 16, color: trendColor),
              if (trendIcon != null) const SizedBox(width: 4),
              Text(
                trend,
                style: monoStyle?.copyWith(color: trendColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _ToggleButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

