import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category.dart';
import 'package:nasz_budzet_domowy/features/dashboard/data/category_breakdown.dart';
import 'package:nasz_budzet_domowy/features/dashboard/data/dashboard_summary.dart';
import 'package:nasz_budzet_domowy/shared/widgets/bento_tile.dart';

/// Tile (b): pie chart wydatków po kategoriach.
class CategoryPieTile extends StatefulWidget {
  const CategoryPieTile({
    required this.summary,
    required this.categories,
    super.key,
  });

  final DashboardSummary summary;
  final List<Category> categories;

  @override
  State<CategoryPieTile> createState() => _CategoryPieTileState();
}

class _CategoryPieTileState extends State<CategoryPieTile> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Podział wydatków wg kategorii dla AKTYWNEGO okresu (subkategorie
    // doliczone do rodzica). `expenseByCategoryId` jest już odfiltrowane
    // do wybranego zakresu dat.
    final spend = computeCategorySpend(
      widget.summary.expenseByCategoryId,
      widget.categories,
    );

    if (spend.isEmpty) {
      return BentoTile(
        title: 'Wydatki wg kategorii',
        child: Center(
          child: Text(
            'Brak wydatków w tym okresie',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }
    final fmtMoney = NumberFormat.currency(
      locale: 'pl_PL',
      symbol: 'zł',
      decimalDigits: 0,
    );

    final sections = spend.asMap().entries.map((entry) {
      final idx = entry.key;
      final s = entry.value;
      final color = s.colorHex != null
          ? CategoryPalette.fromHex(s.colorHex!)
          : CategoryPalette.fallback;
      final isTouched = _touched == idx;
      // Bez procentów NA torcie — przy wąskich wycinkach zachodziły na
      // wykres. Kwoty i procenty pokazujemy w legendzie obok nazwy.
      return PieChartSectionData(
        value: s.amountCents.toDouble(),
        color: color,
        radius: isTouched ? 46 : 40,
        showTitle: false,
      );
    }).toList();

    final legend = spend.take(5).toList();

    return BentoTile(
      title: 'Wydatki wg kategorii',
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 26,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touched = null;
                        return;
                      }
                      _touched = response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: legend.asMap().entries.map((entry) {
                final idx = entry.key;
                final s = entry.value;
                final color = s.colorHex != null
                    ? CategoryPalette.fromHex(s.colorHex!)
                    : CategoryPalette.fallback;
                final pct = (s.fraction * 100).round();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _touched = _touched == idx ? null : idx;
                    }),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            s.name,
                            style: Theme.of(context).textTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${fmtMoney.format(s.amountCents / 100)} · $pct%',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
