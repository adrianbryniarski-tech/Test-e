import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category.dart';
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

    final catMap = {for (final c in widget.categories) c.id: c};

    // Wydatki podkategorii doliczamy do kategorii głównej — jeden wycinek
    // na rodzica (Auto = Paliwo + Serwis + …).
    final raw = widget.summary.expenseByCategoryId;
    final data = <String, int>{};
    raw.forEach((categoryId, cents) {
      final key = catMap[categoryId]?.parentId ?? categoryId;
      data[key] = (data[key] ?? 0) + cents;
    });

    if (data.isEmpty) {
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
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (s, e) => s + e.value);

    final sections = sorted.asMap().entries.map((entry) {
      final idx = entry.key;
      final e = entry.value;
      final cat = catMap[e.key];
      final color = cat != null
          ? CategoryPalette.fromHex(cat.colorHex)
          : CategoryPalette.fallback;
      final isTouched = _touched == idx;
      // Bez procentów NA torcie — przy wąskich wycinkach zachodziły na
      // wykres. Procenty pokazujemy czytelnie w legendzie obok nazwy.
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: color,
        radius: isTouched ? 56 : 48,
        showTitle: false,
      );
    }).toList();

    final legend = sorted.take(5).toList();

    return BentoTile(
      title: 'Wydatki wg kategorii',
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 32,
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
                      _touched = response
                          .touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: legend.asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                final cat = catMap[e.key];
                final color = cat != null
                    ? CategoryPalette.fromHex(cat.colorHex)
                    : CategoryPalette.fallback;
                final pct = total > 0 ? e.value / total * 100 : 0.0;
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
                            cat?.name ?? 'Nieznana',
                            style:
                                Theme.of(context).textTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${pct.toStringAsFixed(0)}%',
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
