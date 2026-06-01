import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nasz_budzet_domowy/features/categories/application/category_providers.dart';
import 'package:nasz_budzet_domowy/features/dashboard/application/date_range_filter.dart';
import 'package:nasz_budzet_domowy/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nasz_budzet_domowy/features/household/application/household_providers.dart';
import 'package:nasz_budzet_domowy/features/investments/application/investment_providers.dart';
import 'package:nasz_budzet_domowy/features/transactions/application/transaction_providers.dart';
import 'package:nasz_budzet_domowy/features/transactions/data/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

Transaction _tx(int amount, DateTime when) => Transaction(
      id: 'tx-${when.microsecondsSinceEpoch}-$amount',
      householdId: 'h1',
      occurredAt: when,
      amountCents: amount,
      type: TransactionType.income,
      categoryId: 'c',
      source: TransactionSource.manual,
      dedupHash: 'h',
      createdAt: when,
    );

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));

  testWidgets(
      'klasyczny pulpit: własny tydzień zawęża saldo i widać aktywny zakres',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    // Kotwiczymy dane w miesiącu sprzed 2 miesięcy — w pełni w przeszłości,
    // a zakresy „własne" nie są cięte do dzisiaj → test jest deterministyczny
    // niezależnie od daty uruchomienia (np. 1. dnia miesiąca).
    final now = DateTime.now();
    final m = DateTime(now.year, now.month - 2);
    final txs = [
      _tx(10000, DateTime(m.year, m.month, 3, 12)),
      _tx(20000, DateTime(m.year, m.month, 12, 12)),
      _tx(40000, DateTime(m.year, m.month, 25, 12)),
    ];

    final container = ProviderContainer(
      overrides: [
        transactionsProvider.overrideWith((ref) => Stream.value(txs)),
        categoriesProvider.overrideWith((ref) => Stream.value(const [])),
        investmentsProvider.overrideWith((ref) => Stream.value(const [])),
        currentHouseholdIdProvider.overrideWith((ref) async => 'h1'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
      ),
    );
    await tester.pumpAndSettle();

    bool money(String s) => tester
        .widgetList<Text>(find.byType(Text))
        .any((t) => (t.data ?? '').contains(s));

    // Aktywny zakres jest zawsze widoczny na pasku.
    expect(find.textContaining('Pokazuję:'), findsOneWidget);

    // Własny zakres = cały miesiąc docelowy → 100+200+400 = 700,00 zł.
    await container.read(dateRangeFilterProvider.notifier).selectCustom(
          DateTimeRange(
            start: DateTime(m.year, m.month),
            end: DateTime(m.year, m.month, 28),
          ),
        );
    await tester.pumpAndSettle();
    expect(money('700,00'), isTrue, reason: 'cały miesiąc = 700 zł');

    // Własny tydzień obejmujący tylko transakcję z 12-ego (200 zł).
    await container.read(dateRangeFilterProvider.notifier).selectCustom(
          DateTimeRange(
            start: DateTime(m.year, m.month, 9),
            end: DateTime(m.year, m.month, 15),
          ),
        );
    await tester.pumpAndSettle();

    expect(money('200,00'), isTrue, reason: 'tydzień zawęża saldo do 200 zł');
    expect(
      money('700,00'),
      isFalse,
      reason: 'nie pokazuje już całego miesiąca',
    );
  });
}
