import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/features/household/application/household_providers.dart';
import 'package:nasz_budzet_domowy/features/investments/data/investment.dart';
import 'package:nasz_budzet_domowy/features/investments/data/investment_repository.dart';
import 'package:nasz_budzet_domowy/features/investments/data/price_service.dart';

final investmentRepositoryProvider = Provider<InvestmentRepository>((ref) {
  return const InvestmentRepository();
});

final priceServiceProvider = Provider<PriceService>((ref) {
  final svc = PriceService();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Pozycje portfela gospodarstwa (realtime).
final investmentsProvider = StreamProvider<List<Investment>>((ref) {
  final householdId = ref.watch(currentHouseholdIdProvider).value;
  if (householdId == null) return Stream.value(const <Investment>[]);
  return ref.watch(investmentRepositoryProvider).watchAll(householdId);
});

/// Snapshoty wartości portfela w czasie (realtime, do wykresu).
final portfolioSnapshotsProvider =
    StreamProvider<List<PortfolioSnapshot>>((ref) {
  final householdId = ref.watch(currentHouseholdIdProvider).value;
  if (householdId == null) {
    return Stream.value(const <PortfolioSnapshot>[]);
  }
  return ref.watch(investmentRepositoryProvider).watchSnapshots(householdId);
});

/// Aktualne kursy dla symboli w portfelu (`symbol → PLN za jednostkę`).
/// FutureProvider — re-fetch przy invalidate (pull-to-refresh / wejście).
/// Zależy od `investmentsProvider` żeby wiedzieć które symbole pobrać.
final pricesProvider = FutureProvider<Map<String, double>>((ref) async {
  final items = ref.watch(investmentsProvider).value ?? const [];
  if (items.isEmpty) return const {};
  final prices =
      await ref.watch(priceServiceProvider).fetchPrices(items);

  // Po pobraniu kursów — zapisz dzienny snapshot wartości portfela.
  // (best-effort, nie blokuje gdy padnie)
  final householdId = ref.read(currentHouseholdIdProvider).value;
  if (householdId != null && prices.isNotEmpty) {
    var totalCents = 0;
    for (final inv in items) {
      final key =
          inv.assetType == AssetType.crypto ? inv.symbol : _metalKey(inv);
      final price = prices[key];
      final value = price == null
          ? inv.buyValuePln
          : inv.quantity * price;
      totalCents += (value * 100).round();
    }
    await ref.read(investmentRepositoryProvider).upsertSnapshot(
          householdId: householdId,
          totalValueCents: totalCents,
        );
  }
  return prices;
});

/// Wyceny pozycji (Investment + aktualny kurs). Sortowane: zysk malejąco.
final investmentValuationsProvider =
    Provider<List<InvestmentValuation>>((ref) {
  final items = ref.watch(investmentsProvider).value ?? const [];
  final prices = ref.watch(pricesProvider).value ?? const {};
  final out = items.map((inv) {
    final key =
        inv.assetType == AssetType.crypto ? inv.symbol : _metalKey(inv);
    return InvestmentValuation(investment: inv, pricePln: prices[key]);
  }).toList()
    ..sort((a, b) => b.currentValuePln.compareTo(a.currentValuePln));
  return out;
});

/// Łączna wartość portfela teraz + łączny zysk/strata.
final portfolioTotalsProvider = Provider<({double value, double profit})>((
  ref,
) {
  final valuations = ref.watch(investmentValuationsProvider);
  var value = 0.0;
  var buy = 0.0;
  for (final v in valuations) {
    value += v.currentValuePln;
    buy += v.investment.buyValuePln;
  }
  return (value: value, profit: value - buy);
});

String _metalKey(Investment inv) =>
    inv.assetType == AssetType.gold ? 'XAU' : 'XAG';
