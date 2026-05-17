import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/dashboard/data/dashboard_summary.dart';
import 'package:nasz_budzet_domowy/shared/widgets/bento_tile.dart';

/// Tile (d): line chart salda narastająco w wybranym okresie.
class RunningBalanceTile extends StatelessWidget {
  const RunningBalanceTile({required this.summary, super.key});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final points = summary.runningBalancePoints;

    if (points.isEmpty) {
      return BentoTile(
        title: 'Saldo narastające',
        child: Center(
          child: Text(
            'Brak transakcji w tym okresie',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    final minY = points
        .map((p) => p.balanceCents.toDouble())
        .reduce((a, b) => a < b ? a : b);
    final maxY = points
        .map((p) => p.balanceCents.toDouble())
        .reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final safeMin = minY - range * 0.1;
    final safeMax = maxY + range * 0.1;

    final spots = points.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.balanceCents.toDouble(),
      );
    }).toList();

    final lineColor = summary.balanceCents >= 0
        ? AppTheme.incomeAccent
        : AppTheme.expenseAccent;

    final fmtDate = DateFormat('d.M', 'pl_PL');
    final fmtMoney = NumberFormat.currency(
      locale: 'pl_PL',
      symbol: 'zł',
      decimalDigits: 0,
    );

    return BentoTile(
      title: 'Saldo narastające',
      child: LineChart(
        LineChartData(
          minY: safeMin,
          maxY: safeMax,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: lineColor,
              barWidth: 2.5,
              dotData: FlDotData(
                show: points.length <= 14,
                getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                  radius: 3,
                  color: lineColor,
                ),
              ),
              belowBarData: BarAreaData(
                color: lineColor.withAlpha(28),
              ),
            ),
          ],
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
                interval: _tickInterval(points.length).toDouble(),
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      fmtDate.format(points[idx].date),
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
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => cs.inverseSurface,
              getTooltipItems: (spots) => spots.map((spot) {
                final idx = spot.x.toInt();
                final date = idx < points.length ? points[idx].date : null;
                return LineTooltipItem(
                  date != null ? '${fmtDate.format(date)}\n' : '',
                  tt.labelSmall!.copyWith(color: cs.onInverseSurface),
                  children: [
                    TextSpan(
                      text: fmtMoney.format(spot.y / 100),
                      style: tt.labelMedium!.copyWith(
                        color: cs.onInverseSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  int _tickInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    return (count / 5).ceil();
  }
}
