import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/features/categories/application/category_providers.dart';
import 'package:nasz_budzet_domowy/features/transactions/data/transaction.dart';
import 'package:nasz_budzet_domowy/shared/widgets/category_avatar.dart';
import 'package:nasz_budzet_domowy/shared/widgets/inline_error.dart';

/// Ekran listy kategorii (v1 — read only).
/// Pełny CRUD + ikony + kolory w Ticket 7.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoriesProvider);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          title: Text('Kategorie'),
          centerTitle: false,
          floating: true,
          snap: true,
        ),
        async.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(child: InlineError(message: e.toString())),
          ),
          data: (categories) {
            final expenses = categories
                .where((c) => c.type == TransactionType.expense)
                .toList();
            final incomes = categories
                .where((c) => c.type == TransactionType.income)
                .toList();

            return SliverList(
              delegate: SliverChildListDelegate([
                if (expenses.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      'Wydatki',
                      style: tt.labelLarge
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                  ...expenses.map(
                    (cat) => ListTile(
                      leading: CategoryAvatar(category: cat),
                      title: Text(cat.name),
                      trailing: cat.isSystem
                          ? Tooltip(
                              message: 'Kategoria systemowa',
                              child: Icon(
                                Icons.lock_outline,
                                size: 16,
                                color: cs.onSurfaceVariant,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
                if (incomes.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      'Dochody',
                      style: tt.labelLarge
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                  ...incomes.map(
                    (cat) => ListTile(
                      leading: CategoryAvatar(category: cat),
                      title: Text(cat.name),
                      trailing: cat.isSystem
                          ? Tooltip(
                              message: 'Kategoria systemowa',
                              child: Icon(
                                Icons.lock_outline,
                                size: 16,
                                color: cs.onSurfaceVariant,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
                const SizedBox(height: 96),
              ]),
            );
          },
        ),
      ],
    );
  }
}
