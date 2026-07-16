import 'package:flutter/material.dart';

/// [BentoGrid] — Layout container cho Bento Grid.
///
/// Tự động responsive: 2 col (mobile) → 3 col (tablet) → 4 col (desktop).
/// Dùng [BentoItem] để wrap từng child với `colSpan` và `rowSpan`.
class BentoGrid extends StatelessWidget {
  final List<BentoItem> children;
  final double spacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double? cellHeight; // Base height of 1 row

  const BentoGrid({
    super.key,
    required this.children,
    this.spacing = 14,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.cellHeight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = _getColumns(width);
        final baseH = cellHeight ?? _baseHeight(width);

        return _BentoGridLayout(
          columns: cols,
          spacing: spacing,
          baseHeight: baseH,
          items: children,
        );
      },
    );
  }

  int _getColumns(double width) {
    if (width < 600) return mobileColumns ?? 2;
    if (width < 1024) return tabletColumns ?? 3;
    return desktopColumns ?? 4;
  }

  double _baseHeight(double width) {
    if (width < 600) return 160;
    if (width < 1024) return 180;
    return 200;
  }
}

/// [BentoItem] — Wraps một child với thông tin span.
class BentoItem extends StatelessWidget {
  final Widget child;
  final int colSpan;
  final int rowSpan;

  const BentoItem({
    super.key,
    required this.child,
    this.colSpan = 1,
    this.rowSpan = 1,
  });

  @override
  Widget build(BuildContext context) => child;
}

/// Internal layout engine cho BentoGrid.
class _BentoGridLayout extends StatelessWidget {
  final int columns;
  final double spacing;
  final double baseHeight;
  final List<BentoItem> items;

  const _BentoGridLayout({
    required this.columns,
    required this.spacing,
    required this.baseHeight,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final totalWidth = constraints.maxWidth;
      final cellWidth =
          (totalWidth - spacing * (columns - 1)) / columns;

      // Build rows greedily
      final rows = <List<_SlottedItem>>[];
      final occupied = <String>{};

      int row = 0;
      int colCursor = 0;

      for (final item in items) {
        final span = item.colSpan.clamp(1, columns);
        final rspan = item.rowSpan.clamp(1, 4);

        // Find next available slot
        while (true) {
          if (colCursor + span > columns) {
            colCursor = 0;
            row++;
          }
          bool fits = true;
          for (int r = row; r < row + rspan && fits; r++) {
            for (int c = colCursor; c < colCursor + span && fits; c++) {
              if (occupied.contains('$r-$c')) fits = false;
            }
          }
          if (fits) break;
          colCursor++;
        }

        // Mark occupied
        for (int r = row; r < row + rspan; r++) {
          for (int c = colCursor; c < colCursor + span; c++) {
            occupied.add('$r-$c');
          }
        }

        while (rows.length <= row + rspan - 1) {
          rows.add([]);
        }
        rows[row].add(_SlottedItem(
          child: item.child,
          col: colCursor,
          colSpan: span,
          rowSpan: rspan,
          row: row,
        ));

        colCursor += span;
        if (colCursor >= columns) {
          colCursor = 0;
          row++;
        }
      }

      // Calculate total rows needed
      final maxRow = occupied.isEmpty
          ? 0
          : occupied
              .map((s) => int.parse(s.split('-')[0]))
              .reduce((a, b) => a > b ? a : b) +
          1;

      return SizedBox(
        height: maxRow * baseHeight + (maxRow - 1) * spacing,
        child: Stack(
          children: [
            for (final rowItems in rows)
              for (final item in rowItems)
                Positioned(
                  left: item.col * (cellWidth + spacing),
                  top: item.row * (baseHeight + spacing),
                  width: item.colSpan * cellWidth +
                      (item.colSpan - 1) * spacing,
                  height: item.rowSpan * baseHeight +
                      (item.rowSpan - 1) * spacing,
                  child: item.child,
                ),
          ],
        ),
      );
    });
  }
}

class _SlottedItem {
  final Widget child;
  final int col;
  final int colSpan;
  final int rowSpan;
  final int row;

  _SlottedItem({
    required this.child,
    required this.col,
    required this.colSpan,
    required this.rowSpan,
    required this.row,
  });
}

/// [ResponsiveBentoRow] — Hàng Bento đơn giản: Row trên desktop, Column trên mobile.
/// Dễ dùng hơn BentoGrid khi chỉ cần 1 hàng responsive.
class ResponsiveBentoRow extends StatelessWidget {
  final List<Widget> children;
  final List<int>? flexes;
  final double spacing;
  final double breakpoint;

  const ResponsiveBentoRow({
    super.key,
    required this.children,
    this.flexes,
    this.spacing = 14,
    this.breakpoint = 600,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < breakpoint) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children
              .expand((c) => [c, SizedBox(height: spacing)])
              .toList()
            ..removeLast(),
        );
      }

      final items = <Widget>[];
      for (int i = 0; i < children.length; i++) {
        if (i > 0) items.add(SizedBox(width: spacing));
        items.add(
          Expanded(
            flex: flexes != null && i < flexes!.length ? flexes![i] : 1,
            child: children[i],
          ),
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      );
    });
  }
}
