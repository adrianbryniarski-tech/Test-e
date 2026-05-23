import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/investments/application/investment_providers.dart';
import 'package:nasz_budzet_domowy/shared/widgets/bento_tile.dart';

/// Kafelek na dashboardzie: łączna wartość portfela inwestycyjnego + zysk.
/// Pokazywany tylko gdy są jakieś inwestycje (sterowane z DashboardScreen).
class PortfolioValueTile extends ConsumerWidget {
  const PortfolioValueTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final valuations = ref.watch(investmentValuationsProvider);

    final total = valuations.fold<double>(0, (s, v) => s + v.currentValuePln);
    final profit = valuations.fold<double>(0, (s, v) => s + v.profitPln);
    final base = total - profit;
    final pct = base != 0 ? profit / base * 100 : 0.0;
    final positive = profit >= 0;
    final color = positive ? AppTheme.incomeAccent : AppTheme.expenseAccent;

    final fmt = NumberFormat.currency(
      locale: 'pl_PL',
      symbol: 'zł',
      decimalDigits: 2,
    );

    return BentoTile(
      title: 'Portfel inwestycyjny',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              fmt.format(total),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                positive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${positive ? '+' : ''}${fmt.format(profit)} '
                  '(${positive ? '+' : ''}${pct.toStringAsFixed(1)}%)',
                  style: theme.textTheme.bodyMedium?.copyWith(color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
