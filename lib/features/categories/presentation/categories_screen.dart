import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/features/categories/application/category_providers.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category.dart';
import 'package:nasz_budzet_domowy/features/categories/presentation/widgets/category_edit_sheet.dart';
import 'package:nasz_budzet_domowy/features/categories/presentation/widgets/delete_category_dialog.dart';
import 'package:nasz_budzet_domowy/features/transactions/data/transaction.dart';
import 'package:nasz_budzet_domowy/shared/widgets/category_avatar.dart';
import 'package:nasz_budzet_domowy/shared/widgets/inline_error.dart';

/// Ekran zarządzania kategoriami.
/// - 12 systemowych (lock icon, nieedytowalne).
/// - Własne: tap → edycja, swipe lub long-press → usuń (z reasignmentem
///   gdy mają transakcje).
/// - "+" w AppBar → bottom sheet do dodania nowej.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoriesProvider);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final counts = ref.watch(transactionCountByCategoryProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Kategorie'),
          centerTitle: false,
          floating: true,
          snap: true,
          actions: [
            IconButton(
              tooltip: 'Odśwież',
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(categoriesProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Odświeżam dane…'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Dodaj kategorię',
              icon: const Icon(Icons.add),
              onPressed: () => _openCreateSheet(context),
            ),
          ],
        ),
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
            await Future<void>.delayed(const Duration(milliseconds: 500));
          },
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
                    (cat) => _CategoryRow(
                      category: cat,
                      count: counts[cat.id] ?? 0,
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
                    (cat) => _CategoryRow(
                      category: cat,
                      count: counts[cat.id] ?? 0,
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

Future<bool?> _openCreateSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => CategoryEditSheet(),
  );
}

Future<bool?> _openEditSheet(BuildContext context, Category category) {
  if (category.isSystem) return Future.value(false);
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => CategoryEditSheet(existing: category),
  );
}

Future<bool?> _openDeleteDialog(BuildContext context, Category category) {
  return showDialog<bool>(
    context: context,
    builder: (_) => DeleteCategoryDialog(category: category),
  );
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.category, required this.count});

  final Category category;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tile = ListTile(
      leading: CategoryAvatar(category: category),
      title: Text(category.name),
      subtitle: count > 0
          ? Text('$count ${_pluralTx(count)}')
          : Text(
              'Brak transakcji',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
      trailing: category.isSystem
          ? Tooltip(
              message: 'Kategoria systemowa (read-only)',
              child: Icon(
                Icons.lock_outline,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : const Icon(Icons.chevron_right),
      onTap: () => _openEditSheet(context, category),
    );

    if (category.isSystem) {
      return tile;
    }

    return Dismissible(
      key: ValueKey('cat-${category.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final removed = await _openDeleteDialog(context, category);
        return removed ?? false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: theme.colorScheme.errorContainer,
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      child: tile,
    );
  }

  String _pluralTx(int n) {
    if (n == 1) return 'transakcja';
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return 'transakcje';
    }
    return 'transakcji';
  }
}
