import 'package:nasz_budzet_domowy/features/categories/data/category.dart';

/// Jedna pozycja podziału wydatków wg kategorii (dla wybranego okresu).
class CategorySpend {
  const CategorySpend({
    required this.categoryId,
    required this.name,
    required this.colorHex,
    required this.amountCents,
    required this.fraction,
  });

  final String categoryId;
  final String name;

  /// `#RRGGBB` kategorii nadrzędnej; `null` gdy kategorii nie znaleziono.
  final String? colorHex;
  final int amountCents;

  /// Udział w sumie wszystkich wydatków okresu (0..1).
  final double fraction;
}

/// Podział wydatków wg kategorii dla danego okresu. Wydatki podkategorii
/// doliczane są do kategorii NADRZĘDNEJ (jeden wiersz na rodzica), tak jak
/// na wykresie kołowym. Wynik posortowany malejąco po kwocie.
///
/// `expenseByCategoryId` pochodzi z `DashboardSummary` (już odfiltrowane do
/// wybranego zakresu dat), więc podział zawsze dotyczy aktywnego okresu.
List<CategorySpend> computeCategorySpend(
  Map<String, int> expenseByCategoryId,
  List<Category> categories,
) {
  final byId = {for (final c in categories) c.id: c};

  final rolled = <String, int>{};
  expenseByCategoryId.forEach((categoryId, cents) {
    final key = byId[categoryId]?.parentId ?? categoryId;
    rolled[key] = (rolled[key] ?? 0) + cents;
  });

  final total = rolled.values.fold<int>(0, (s, v) => s + v);

  final list = rolled.entries.map((e) {
    final cat = byId[e.key];
    return CategorySpend(
      categoryId: e.key,
      name: cat?.name ?? 'Nieznana',
      colorHex: cat?.colorHex,
      amountCents: e.value,
      fraction: total == 0 ? 0 : e.value / total,
    );
  }).toList()
    ..sort((a, b) => b.amountCents.compareTo(a.amountCents));

  return list;
}
