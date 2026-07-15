import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_finance/ui/widgets/glass_card.dart';
import 'package:smart_finance/ui/widgets/page_header.dart';


class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

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
              const PageHeader(
                title: 'Chi phí',
                subtitle: 'Theo dõi chi phí và quản lý hóa đơn hàng tháng.',
              ),
              const SizedBox(height: 32),
              isDesktop ? _buildDesktopLayout(context, theme) : _buildMobileLayout(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: _buildLeftColumn(context, theme),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 8,
          child: _buildRightColumn(context, theme, true),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLeftColumn(context, theme),
        const SizedBox(height: 24),
        _buildRightColumn(context, theme, false),
      ],
    );
  }

  Widget _buildLeftColumn(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // Monthly Budget Card
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ngân sách hàng tháng',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '\$4,250',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'đã tiêu',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.65,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Còn lại \$2,250',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Tổng cộng \$6,500',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Scan Receipt Action
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.document_scanner),
          label: const Text('Quét biên lai'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            minimumSize: const Size(double.infinity, 56),
            textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Nhập thủ công'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload_file),
                label: const Text('Tải lên CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRightColumn(BuildContext context, ThemeData theme, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chi phí gần đây',
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
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.search),
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildExpensesList(context, theme, isDesktop),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {},
            child: Text(
              'Xem tất cả chi phí',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesList(BuildContext context, ThemeData theme, bool isDesktop) {
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
                DataColumn(label: Text('Chi phí')),
                DataColumn(label: Text('Danh mục')),
                DataColumn(label: Text('Ngày')),
                DataColumn(label: Text('Số tiền')),
                DataColumn(label: Text('Hành động')),
              ],
              rows: [
                DataRow(cells: [
                  DataCell(Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(Icons.flight, color: theme.colorScheme.tertiary, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Delta Airlines', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Chuyến công tác NYC', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  )),
                  const DataCell(Text('Du lịch')),
                  const DataCell(Text('Hôm nay, 24 tháng 10')),
                  DataCell(Text('-\$450.00', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', color: theme.colorScheme.primary))),
                  DataCell(IconButton(icon: const Icon(Icons.more_vert, size: 20), onPressed: () {})),
                ]),
                DataRow(cells: [
                  DataCell(Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(Icons.restaurant, color: theme.colorScheme.secondary, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Sweetgreen', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Ăn trưa nhóm', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  )),
                  const DataCell(Text('Ăn uống')),
                  const DataCell(Text('Hôm nay, 24 tháng 10')),
                  DataCell(Text('-\$45.20', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', color: theme.colorScheme.primary))),
                  DataCell(IconButton(icon: const Icon(Icons.more_vert, size: 20), onPressed: () {})),
                ]),
                DataRow(cells: [
                  DataCell(Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(Icons.computer, color: theme.colorScheme.primary, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Apple Store', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Màn hình mới', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  )),
                  const DataCell(Text('Văn phòng')),
                  const DataCell(Text('Hôm qua, 23 tháng 10')),
                  DataCell(Text('-\$1,299.00', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', color: theme.colorScheme.primary))),
                  DataCell(IconButton(icon: const Icon(Icons.more_vert, size: 20), onPressed: () {})),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateGroup(context, theme, 'Hôm nay, 24 tháng 10'),
            _buildExpenseItem(
              context,
              theme,
              icon: Icons.flight,
              title: 'Delta Airlines',
              category: 'Du lịch',
              description: 'Chuyến công tác NYC',
              amount: '-\$450.00',
              iconColor: theme.colorScheme.tertiary,
              iconBg: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.1),
            ),
            const Divider(height: 1),
            _buildExpenseItem(
              context,
              theme,
              icon: Icons.restaurant,
              title: 'Sweetgreen',
              category: 'Ăn uống',
              description: 'Ăn trưa nhóm',
              amount: '-\$45.20',
              iconColor: theme.colorScheme.secondary,
              iconBg: theme.colorScheme.secondaryContainer.withValues(alpha: 0.1),
            ),
            _buildDateGroup(context, theme, 'Hôm qua, 23 tháng 10'),
            _buildExpenseItem(
              context,
              theme,
              icon: Icons.computer,
              title: 'Apple Store',
              category: 'Văn phòng',
              description: 'Màn hình mới',
              amount: '-\$1,299.00',
              iconColor: theme.colorScheme.primary,
              iconBg: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
            ),
            const Divider(height: 1),
            _buildExpenseItem(
              context,
              theme,
              icon: Icons.local_cafe,
              title: 'Starbucks',
              category: 'Ăn uống',
              description: 'Mua cà phê',
              amount: '-\$12.50',
              iconColor: theme.colorScheme.secondary,
              iconBg: theme.colorScheme.secondaryContainer.withValues(alpha: 0.1),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDateGroup(BuildContext context, ThemeData theme, String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
        ),
      ),
      child: Text(
        date.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildExpenseItem(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String category,
    required String description,
    required String amount,
    required Color iconColor,
    required Color iconBg,
  }) {
    return InkWell(
      onTap: () {},
      child: Padding(
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
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor),
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
                      '$category • $description',
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
                color: theme.colorScheme.primary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}


