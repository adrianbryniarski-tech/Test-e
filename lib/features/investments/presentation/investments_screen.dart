import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/investments/application/investment_providers.dart';
import 'package:nasz_budzet_domowy/features/investments/data/investment.dart';
import 'package:nasz_budzet_domowy/features/investments/data/investment_repository.dart';
import 'package:nasz_budzet_domowy/features/investments/presentation/widgets/portfolio_chart.dart';
import 'package:nasz_budzet_domowy/shared/widgets/inline_error.dart';

/// Zakładka Inwestycje: wartość portfela + wykres + lista pozycji
/// z zyskiem/stratą. Kursy z CoinGecko/NBP/stooq (pull-to-refresh).
///
/// Trzyma `_locallyDeleted` set — po swipe-delete optimistycznie ukrywamy
/// pozycję zanim Realtime przyniesie DELETE event. Bez tego Dismissible
/// rzuca "A dismissed Dismissible widget is still part of the tree".
class InvestmentsScreen extends ConsumerStatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  ConsumerState<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends ConsumerState<InvestmentsScreen> {
  final Set<String> _locallyDeleted = {};

  void _hideLocally(String id) => setState(() => _locallyDeleted.add(id));
  void _restoreLocally(String id) =>
      setState(() => _locallyDeleted.remove(id));

  @override
  Widget build(BuildContext context) {
    final investments = ref.watch(investmentsProvider);
    final valuations = ref.watch(investmentValuationsProvider);
    final snapshots = ref.watch(portfolioSnapshotsProvider).value ?? const [];
    final pricesAsync = ref.watch(pricesProvider);
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(
      locale: 'pl_PL',
      symbol: 'zł',
      decimalDigits: 2,
    );

    // Self-cleanup: gdy Realtime usunie pozycję, czyścimy ją z setu.
    final visibleIds = valuations.map((v) => v.investment.id).toSet();
    _locallyDeleted.removeWhere((id) => !visibleIds.contains(id));
    final visibleValuations = valuations
        .where((v) => !_locallyDeleted.contains(v.investment.id))
        .toList();

    // Sumy liczone z WIDOCZNYCH pozycji — dzięki temu nagłówek aktualizuje
    // się natychmiast po swipe-delete, nie czekając na event z Realtime.
    var portfolioValue = 0.0;
    var portfolioBuy = 0.0;
    for (final v in visibleValuations) {
      portfolioValue += v.currentValuePln;
      portfolioBuy += v.investment.buyValuePln;
    }
    final portfolioProfit = portfolioValue - portfolioBuy;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Inwestycje'),
          centerTitle: false,
          floating: true,
          snap: true,
          actions: [
            if (pricesAsync.isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: 'Odśwież kursy',
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(pricesProvider),
              ),
          ],
        ),
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            ref.invalidate(pricesProvider);
            await Future<void>.delayed(const Duration(milliseconds: 600));
          },
        ),
        investments.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(child: InlineError(message: e.toString())),
          ),
          data: (items) {
            if (visibleValuations.isEmpty) {
              return const SliverFillRemaining(child: _EmptyState());
            }
            return SliverList(
              delegate: SliverChildListDelegate([
                // Header: wartość portfela + zysk + wykres
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wartość portfela',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              fmt.format(portfolioValue),
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          _ProfitLabel(
                            profit: portfolioProfit,
                            base: portfolioBuy,
                          ),
                          const SizedBox(height: 16),
                          PortfolioChart(snapshots: snapshots),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Text(
                    'Twoje aktywa',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (final v in visibleValuations)
                  _DismissibleValuationRow(
                    key: ValueKey('inv-${v.investment.id}'),
                    valuation: v,
                    onDeleteLocally: _hideLocally,
                    onDeleteFailed: _restoreLocally,
                  ),
                const SizedBox(height: 96),
              ]),
            );
          },
        ),
      ],
    );
  }
}

class _ProfitLabel extends StatelessWidget {
  const _ProfitLabel({required this.profit, required this.base});
  final double profit;
  final double base;

  @override
  Widget build(BuildContext context) {
    final positive = profit >= 0;
    final color = positive ? AppTheme.incomeAccent : AppTheme.expenseAccent;
    final fmt = NumberFormat.currency(
      locale: 'pl_PL',
      symbol: 'zł',
      decimalDigits: 2,
    );
    final pct = base == 0 ? 0.0 : profit / base * 100;
    return Row(
      children: [
        Icon(
          positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '${positive ? '+' : ''}${fmt.format(profit)} '
          '(${positive ? '+' : ''}${pct.toStringAsFixed(1)}%)',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Wrapper z Dismissible — swipe w lewo → potwierdzenie → usunięcie.
///
/// CRITICAL: po `onDismissed` widget MUSI natychmiast zniknąć z drzewa
/// (parent filtruje go w tym samym build przez `_locallyDeleted`). Inaczej
/// Flutter rzuca "A dismissed Dismissible widget is still part of the tree".
class _DismissibleValuationRow extends ConsumerWidget {
  const _DismissibleValuationRow({
    required this.valuation,
    required this.onDeleteLocally,
    required this.onDeleteFailed,
    super.key,
  });

  final InvestmentValuation valuation;
  final void Function(String id) onDeleteLocally;
  final void Function(String id) onDeleteFailed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inv = valuation.investment;
    return Dismissible(
      key: ValueKey('inv-dismiss-${inv.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDeleteInvestment(context, inv.displayName),
      onDismissed: (_) async {
        // KROK 1 (SYNC): ukryj item w parent — Dismissible może zniknąć.
        onDeleteLocally(inv.id);
        final messenger = ScaffoldMessenger.of(context);
        // KROK 2 (ASYNC): faktyczne usunięcie; Realtime odświeży listę.
        final result =
            await ref.read(investmentRepositoryProvider).delete(inv.id);
        if (result is InvestmentWriteSuccess) {
          ref.invalidate(pricesProvider);
          messenger.showSnackBar(
            SnackBar(content: Text('Usunięto „${inv.displayName}"')),
          );
        } else if (result is InvestmentWriteFailure) {
          onDeleteFailed(inv.id);
          messenger.showSnackBar(
            SnackBar(content: Text('Nie udało się usunąć: ${result.message}')),
          );
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      child: _ValuationTile(valuation: valuation),
    );
  }
}

/// Wspólny dialog potwierdzenia usunięcia pozycji.
Future<bool> _confirmDeleteInvestment(
  BuildContext context,
  String displayName,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Usunąć pozycję?'),
      content: Text(
        'Usunąć „$displayName" z portfela? Tej operacji nie można cofnąć.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: const Text('Anuluj'),
        ),
        FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogCtx).colorScheme.errorContainer,
            foregroundColor: Theme.of(dialogCtx).colorScheme.onErrorContainer,
          ),
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          child: const Text('Usuń'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class _ValuationTile extends ConsumerWidget {
  const _ValuationTile({required this.valuation});
  final InvestmentValuation valuation;

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final inv = valuation.investment;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edytuj pozycję'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                context.push('/investments/edit', extra: inv);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(sheetCtx).colorScheme.error,
              ),
              title: Text(
                'Usuń pozycję',
                style: TextStyle(color: Theme.of(sheetCtx).colorScheme.error),
              ),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _confirmDelete(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final inv = valuation.investment;
    final ok = await _confirmDeleteInvestment(context, inv.displayName);
    if (!ok || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(investmentRepositoryProvider).delete(inv.id);
    if (result is InvestmentWriteSuccess) {
      ref.invalidate(pricesProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('Usunięto „${inv.displayName}"')),
      );
    } else if (result is InvestmentWriteFailure) {
      messenger.showSnackBar(
        SnackBar(content: Text('Nie udało się usunąć: ${result.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inv = valuation.investment;
    final fmt = NumberFormat.currency(
      locale: 'pl_PL',
      symbol: 'zł',
      decimalDigits: 2,
    );
    final qtyStr = inv.quantity == inv.quantity.roundToDouble()
        ? inv.quantity.toStringAsFixed(0)
        : inv.quantity.toString();
    final color =
        valuation.isProfit ? AppTheme.incomeAccent : AppTheme.expenseAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showActions(context, ref),
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _AssetAvatar(type: inv.assetType, symbol: inv.symbol),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$qtyStr ${inv.assetType.unitLabel(inv.symbol)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt.format(valuation.currentValuePln),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (valuation.hasPrice)
                    Text(
                      '${valuation.isProfit ? '+' : ''}'
                      '${fmt.format(valuation.profitPln)} '
                      '(${valuation.isProfit ? '+' : ''}'
                      '${valuation.profitPercent.toStringAsFixed(1)}%)',
                      style: theme.textTheme.bodySmall?.copyWith(color: color),
                    )
                  else
                    Text(
                      'kurs niedostępny',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _AssetAvatar extends StatelessWidget {
  const _AssetAvatar({required this.type, required this.symbol});
  final AssetType type;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final (bg, label) = switch (type) {
      AssetType.crypto => (const Color(0xFF5B7AB9), symbol.toUpperCase()),
      AssetType.gold => (const Color(0xFFE8C24A), 'Au'),
      AssetType.silver => (const Color(0xFFB0B7C3), 'Ag'),
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        label.length > 4 ? label.substring(0, 4) : label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.trending_up,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text('Brak inwestycji', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Stuknij + żeby dodać krypto, złoto lub srebro. '
              'Apka pokaże aktualny kurs i Twój zysk/stratę.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
