import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nasz_budzet_domowy/features/budgets/application/budget_providers.dart';
import 'package:nasz_budzet_domowy/features/budgets/data/budget.dart';
import 'package:nasz_budzet_domowy/features/categories/application/category_providers.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category.dart';
import 'package:nasz_budzet_domowy/features/dashboard/application/dashboard_providers.dart';
import 'package:nasz_budzet_domowy/features/dashboard/application/date_range_filter.dart';
import 'package:nasz_budzet_domowy/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nasz_budzet_domowy/features/household/application/household_providers.dart';
import 'package:nasz_budzet_domowy/features/investments/application/investment_providers.dart';
import 'package:nasz_budzet_domowy/features/transactions/application/transaction_providers.dart';
import 'package:nasz_budzet_domowy/features/transactions/data/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

Transaction _tx(int amount, TransactionType type, DateTime when) => Transaction(
      id: 'tx-${when.microsecondsSinceEpoch}-$amount',
      householdId: 'h1',
      occurredAt: when,
      amountCents: amount,
      type: type,
      categoryId: 'c',
      source: TransactionSource.manual,
      dedupHash: 'hash',
      createdAt: when,
    );

void main() {
  final now = DateTime.now();
  final thisMonthDate = DateTime(now.year, now.month, 2, 12);
  final lastMonthDate = DateTime(now.year, now.month - 1, 10, 12);
  final thisMonthExp = _tx(3000, TransactionType.expense, thisMonthDate);
  final lastMonthExp = _tx(7000, TransactionType.expense, lastMonthDate);
  final budget = Budget(
    id: 'b1',
    householdId: 'h1',
    categoryId: 'c',
    amountCents: 100000,
    startsOn: DateTime(now.year, now.month - 2),
  );

  final dataOverrides = [
    transactionsProvider
        .overrideWith((ref) => Stream.value([thisMonthExp, lastMonthExp])),
    budgetsProvider.overrideWith((ref) => Stream.value([budget])),
    currentHouseholdIdProvider.overrideWith((ref) async => 'h1'),
  ];

  group('periodBudgetProgressProvider — śledzi wybrany zakres dat', () {
    test('domyślnie (bieżący miesiąc) sumuje wydatki bieżącego miesiąca',
        () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(overrides: dataOverrides);
      addTearDown(container.dispose);
      container.listen(periodBudgetProgressProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final p = container.read(periodBudgetProgressProvider);
      expect(p, hasLength(1));
      expect(p.single.spentCents, 3000);
    });

    test('po wyborze poprzedniego miesiąca sumuje jego wydatki', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(overrides: dataOverrides);
      addTearDown(container.dispose);
      container.listen(periodBudgetProgressProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container
          .read(dateRangeFilterProvider.notifier)
          .selectPreset(DateRangePreset.previousMonth);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final p = container.read(periodBudgetProgressProvider);
      expect(
        p.single.spentCents,
        7000,
        reason: 'panel kategorii musi reagować na zmianę okresu',
      );
    });
  });

  testWidgets(
      'MANGA: panel „Wydatki wg kategorii" aktualizuje się przy zmianie okresu',
      (tester) async {
    await initializeDateFormatting('pl_PL');
    SharedPreferences.setMockInitialValues({'theme_variant': 'manga'});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...dataOverrides,
          categoriesProvider.overrideWith(
            (ref) => Stream.value(const [
              Category(
                id: 'c',
                householdId: 'h1',
                name: 'Jedzenie',
                icon: 'food',
                colorHex: '#FF0000',
                type: TransactionType.expense,
                isSystem: false,
              ),
            ]),
          ),
          investmentsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(
          locale: Locale('pl'),
          supportedLocales: [Locale('pl')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: DashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    bool catRow(String spent) => tester
        .widgetList<Text>(find.byType(Text))
        .any((t) => (t.data ?? '').startsWith('$spent /'));

    expect(catRow('30'), isTrue, reason: 'bieżący miesiąc = 30 zł');

    await tester.tap(find.text('Poprzedni'));
    await tester.pumpAndSettle();

    expect(catRow('70'), isTrue, reason: 'poprzedni miesiąc = 70 zł');
    expect(
      catRow('30'),
      isFalse,
      reason: 'nie pokazuje już bieżącego miesiąca',
    );
  });
}
