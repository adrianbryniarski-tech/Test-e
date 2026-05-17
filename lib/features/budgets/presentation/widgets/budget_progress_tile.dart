import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/budgets/data/budget.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category.dart';
import 'package:nasz_budzet_domowy/shared/widgets/category_avatar.dart';

/// Wiersz z kategorią + paskiem postępu wydatków vs budżet.
/// Kolor paska: zielony (<80%), żółty (80-100%), czerwony (>100%).
class BudgetProgressTile extends StatelessWidget {
  const BudgetProgressTile({
    required this.progress,
    required this.category,
    this.onTap,
    super.key,
  });

  final BudgetProgress progress;
  final Category category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##0.00', 'pl_PL');
    final spent = fmt.format(progress.spentCents / 100);
    final limit = fmt.format(progress.budget.amountCents / 100);
    final remaining = progress.budget.amountCents - progress.spentCents;
    final remainingFmt = fmt.format(remaining.abs() / 100);

    final color = progress.isExceeded
        ? AppTheme.expenseAccent
        : progress.isNearLimit
            ? const Color(0xFFE8C24A)
            : AppTheme.incomeAccent;

    final clampedFraction = progress.fraction.clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CategoryAvatar(category: category),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        progress.isExceeded
                            ? 'przekroczone o $remainingFmt zł'
                            : '$remainingFmt zł zostało',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: progress.isExceeded
                              ? AppTheme.expenseAccent
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$spent / $limit zł',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: clampedFraction,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
