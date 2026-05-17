import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/dashboard/data/dashboard_summary.dart';
import 'package:nasz_budzet_domowy/shared/widgets/bento_tile.dart';

/// Tile (c): bar chart dochody vs wydatki po przedziałach czasowych.
/// Auto-bucketing: dzienny (≤14 d), tygodniowy (≤90 d), miesięczny (>90 d).
class IncomeExpenseBarTile extends StatelessWidget {
  const IncomeExpenseBarTile({required this.summary, super.key});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final buckets = summary.barBuckets;

    if (buckets.isEmpty) {
      return BentoTile(
        title: 'Dochody / wydatki',
        child: Center(
          child: Text(
            'Brak transakcji w tym okresie',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    final maxY = buckets
        .expand((b) => [b.incomeCents, b.expenseCents])
        .fold(0, (a, b) => a > b ? a : b)
        .toDouble();

    final safeMaxY = maxY == 0 ? 1.0 : maxY * 1.15;
    final labelFmt = _labelFormatter(buckets.first.date, buckets.last.date);

    final groups = buckets.asMap().entries.map((entry) {
      final i = entry.key;
      final b = entry.value;
      return BarChartGroupData(
        x: i,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: b.incomeCents.toDouble(),
            color: AppTheme.incomeAccent.withAlpha(200),
            width: 10,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: b.expenseCents.toDouble(),
            color: AppTheme.expenseAccent.withAlpha(200),
            width: 10,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return BentoTile(
      title: 'Dochody / wydatki',
      trailing: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Legend(color: AppTheme.incomeAccent, label: 'Dochód'),
          SizedBox(width: 8),
          _Legend(color: AppTheme.expenseAccent, label: 'Wydatek'),
        ],
      ),
      child: BarChart(
        BarChartData(
          maxY: safeMaxY,
          barGroups: groups,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(
              color: cs.outlineVariant.withAlpha(80),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _tickInterval(buckets.length),
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= buckets.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      labelFmt(buckets[idx].date),
                      style: tt.labelSmall?.copyWith(
                        fontSize: 9,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => cs.inverseSurface,
              getTooltipItem: (group, groupIdx, rod, rodIdx) {
                final b = buckets[groupIdx];
                final label = rodIdx == 0 ? 'Dochód' : 'Wydatek';
                final val = rodIdx == 0 ? b.incomeCents : b.expenseCents;
                final fmt = NumberFormat.currency(
                  locale: 'pl_PL',
                  symbol: 'zł',
                  decimalDigits: 0,
                );
                return BarTooltipItem(
                  '$label\n${fmt.format(val / 100)}',
                  tt.labelSmall!.copyWith(
                    color: cs.onInverseSurface,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _tickInterval(int count) {
    if (count <= 6) return 1;
    if (count <= 12) return 2;
    if (count <= 24) return 4;
    return (count / 6).ceilToDouble();
  }

  String Function(DateTime) _labelFormatter(DateTime first, DateTime last) {
    final days = last.difference(first).inDays;
    if (days <= 14) {
      return (d) => DateFormat('d.M', 'pl_PL').format(d);
    } else if (days <= 90) {
      return (d) => 'T${_weekOfYear(d)}';
    } else {
      return (d) => DateFormat('MMM', 'pl_PL').format(d);
    }
  }

  int _weekOfYear(DateTime d) {
    final startOfYear = DateTime(d.year);
    final diff = d.difference(startOfYear).inDays;
    return (diff / 7).ceil() + 1;
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
