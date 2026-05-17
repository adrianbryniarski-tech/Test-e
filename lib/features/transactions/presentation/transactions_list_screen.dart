import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/auth/application/auth_providers.dart';
import 'package:nasz_budzet_domowy/features/categories/application/category_providers.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category.dart';
import 'package:nasz_budzet_domowy/features/transactions/application/transaction_providers.dart';
import 'package:nasz_budzet_domowy/features/transactions/data/transaction.dart';
import 'package:nasz_budzet_domowy/shared/widgets/category_avatar.dart';
import 'package:nasz_budzet_domowy/shared/widgets/sync_status_indicator.dart';

/// Lista transakcji bieżącego gospodarstwa.
/// Renderuje się jako CustomScrollView (bez własnego Scaffold) —
/// żyje w HomeShell, który dostarcza NavigationBar i FAB.
class TransactionsListScreen extends ConsumerWidget {
  const TransactionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Transakcje'),
          centerTitle: false,
          floating: true,
          snap: true,
          actions: [
            const SyncStatusIndicator(),
            IconButton(
              tooltip: 'Wyloguj',
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
            ),
          ],
        ),
        transactions.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Nie udało się pobrać transakcji: $e',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          data: (txs) {
            if (txs.isEmpty) {
              return const SliverFillRemaining(child: _EmptyState());
            }
            final categoriesMap = {
              for (final c in categories.value ?? const <Category>[]) c.id: c,
            };
            return _TransactionsList(
              transactions: txs,
              categoriesById: categoriesMap,
            );
          },
        ),
      ],
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
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Jeszcze nie ma transakcji',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Stuknij "Dodaj" żeby zapisać pierwszy wydatek lub dochód.',
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

class _TransactionsList extends StatelessWidget {
  const _TransactionsList({
    required this.transactions,
    required this.categoriesById,
  });

  final List<Transaction> transactions;
  final Map<String, Category> categoriesById;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDate(transactions);
    return SliverPadding(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final entry = groups[index];
            return _DateGroup(
              date: entry.key,
              transactions: entry.value,
              categoriesById: categoriesById,
            );
          },
          childCount: groups.length,
        ),
      ),
    );
  }

  static List<MapEntry<DateTime, List<Transaction>>> _groupByDate(
    List<Transaction> txs,
  ) {
    final map = <DateTime, List<Transaction>>{};
    for (final t in txs) {
      final key = DateTime(
        t.occurredAt.year,
        t.occurredAt.month,
        t.occurredAt.day,
      );
      map.putIfAbsent(key, () => []).add(t);
    }
    return map.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
  }
}

class _DateGroup extends StatelessWidget {
  const _DateGroup({
    required this.date,
    required this.transactions,
    required this.categoriesById,
  });

  final DateTime date;
  final List<Transaction> transactions;
  final Map<String, Category> categoriesById;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _dateLabel(date);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                for (final t in transactions)
                  _TransactionRow(
                    transaction: t,
                    category: categoriesById[t.categoryId],
                    isLast: t == transactions.last,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return 'Dziś';
    if (date == yesterday) return 'Wczoraj';
    return DateFormat('EEEE, d MMMM y', 'pl_PL').format(date);
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.category,
    required this.isLast,
  });

  final Transaction transaction;
  final Category? category;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == TransactionType.income;
    final sign = isIncome ? '+' : '−';
    final amount =
        NumberFormat('#,##0.00', 'pl_PL').format(transaction.amountCents / 100);
    final accent = isIncome ? AppTheme.incomeAccent : AppTheme.expenseAccent;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (category != null)
                CategoryAvatar(category: category!)
              else
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (transaction.isPending) ...[
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            (transaction.description?.isNotEmpty ?? false)
                                ? transaction.description!
                                : (category?.name ?? 'Transakcja'),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (category != null)
                      Text(
                        transaction.isPending
                            ? '${category!.name} • czeka na sync'
                            : category!.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: transaction.isPending
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$sign$amount zł',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 66,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
      ],
    );
  }
}
