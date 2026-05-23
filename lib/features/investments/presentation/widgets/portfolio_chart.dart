import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/investments/data/investment.dart';

/// Wykres liniowy wartości portfela w czasie (z dziennych snapshotów).
/// Mniej niż 2 punkty → placeholder ("zbieramy historię").
class PortfolioChart extends StatelessWidget {
  const PortfolioChart({required this.snapshots, super.key});

  final List<PortfolioSnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (snapshots.length < 2) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Wykres pojawi się po kilku dniach — zbieramy historię '
            'wartości portfela.',
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    // Sortujemy rosnąco po dacie — najstarszy punkt z LEWEJ, najnowszy z
    // PRAWEJ (wcześniej provider dawał malejąco i wykres czytał się odwrotnie).
    final ordered = [...snapshots]
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));

    final values = ordered.map((s) => s.valuePln).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).abs();
    final pad = range == 0 ? maxY * 0.05 + 1 : range * 0.1;

    final up = values.last >= values.first;
    final color = up ? AppTheme.incomeAccent : AppTheme.expenseAccent;

    final spots = ordered.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.valuePln);
    }).toList();

    final fmtDate = DateFormat('d.M', 'pl_PL');
    final fmtMoney = NumberFormat.currency(
      locale: 'pl_PL',
      symbol: 'zł',
      decimalDigits: 0,
    );

    return SizedBox(
      height: 140,
      child: LineChart(
        LineChartData(
          minY: minY - pad,
          maxY: maxY + pad,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: color,
              barWidth: 3,
              dotData: FlDotData(show: ordered.length <= 12),
              belowBarData: BarAreaData(show: true, color: color.withAlpha(26)),
            ),
          ],
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (ordered.length / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= ordered.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      fmtDate.format(ordered[idx].capturedAt),
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
              getTooltipItems: (spots) => spots.map((s) {
                final idx = s.x.toInt();
                final d = idx < ordered.length ? ordered[idx].capturedAt : null;
                return LineTooltipItem(
                  d != null ? '${fmtDate.format(d)}\n' : '',
                  tt.labelSmall!.copyWith(color: cs.onInverseSurface),
                  children: [
                    TextSpan(
                      text: fmtMoney.format(s.y),
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
}
