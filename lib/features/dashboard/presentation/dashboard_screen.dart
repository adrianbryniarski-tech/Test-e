import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/features/categories/application/category_providers.dart';
import 'package:nasz_budzet_domowy/features/dashboard/application/dashboard_providers.dart';
import 'package:nasz_budzet_domowy/features/dashboard/presentation/widgets/balance_tile.dart';
import 'package:nasz_budzet_domowy/features/dashboard/presentation/widgets/category_pie_tile.dart';
import 'package:nasz_budzet_domowy/features/dashboard/presentation/widgets/date_range_bar.dart';
import 'package:nasz_budzet_domowy/features/dashboard/presentation/widgets/income_expense_bar_tile.dart';
import 'package:nasz_budzet_domowy/features/dashboard/presentation/widgets/running_balance_tile.dart';
import 'package:nasz_budzet_domowy/shared/widgets/inline_error.dart';

/// Ekran główny — bento grid z podsumowaniem finansów.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          title: Text('Nasz budżet domowy'),
          centerTitle: false,
          floating: true,
          snap: true,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(56),
            child: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: DateRangeBar(),
            ),
          ),
        ),
        summaryAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(child: InlineError(message: e.toString())),
          ),
          data: (summary) {
            final categories = categoriesAsync.value ?? const [];
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  BalanceTile(summary: summary),
                  CategoryPieTile(
                    summary: summary,
                    categories: categories,
                  ),
                  IncomeExpenseBarTile(summary: summary),
                  RunningBalanceTile(summary: summary),
                ]),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  childAspectRatio: 1.35,
                  mainAxisSpacing: 12,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
