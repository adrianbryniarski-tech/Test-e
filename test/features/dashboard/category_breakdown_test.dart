import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category.dart';
import 'package:nasz_budzet_domowy/features/dashboard/data/category_breakdown.dart';
import 'package:nasz_budzet_domowy/features/transactions/data/transaction.dart';

Category _cat(String id, String name, {String? parentId}) => Category(
      id: id,
      householdId: 'h1',
      name: name,
      icon: 'i',
      colorHex: '#112233',
      type: TransactionType.expense,
      isSystem: false,
      parentId: parentId,
    );

void main() {
  final categories = [
    _cat('food', 'Jedzenie'),
    _cat('rest', 'Restauracje', parentId: 'food'),
    _cat('auto', 'Auto'),
  ];

  test('subkategorie doliczają się do rodzica, sortowanie malejące, udziały',
      () {
    final spend = computeCategorySpend(
      const {'food': 1000, 'rest': 500, 'auto': 3000},
      categories,
    );

    expect(spend, hasLength(2));
    // Auto (3000) > Jedzenie (1000+500=1500).
    expect(spend.first.categoryId, 'auto');
    expect(spend.first.amountCents, 3000);
    final food = spend.firstWhere((s) => s.categoryId == 'food');
    expect(food.amountCents, 1500);
    expect(food.name, 'Jedzenie');
    // Udziały: total = 4500 → auto 2/3, food 1/3.
    expect(spend.first.fraction, closeTo(0.6667, 0.001));
    expect(food.fraction, closeTo(0.3333, 0.001));
  });

  test('nieznana kategoria → fallback nazwy, brak koloru', () {
    final spend = computeCategorySpend(const {'ghost': 200}, categories);
    expect(spend, hasLength(1));
    expect(spend.single.name, 'Nieznana');
    expect(spend.single.colorHex, isNull);
  });

  test('pusty input → pusta lista', () {
    expect(computeCategorySpend(const {}, categories), isEmpty);
  });
}
