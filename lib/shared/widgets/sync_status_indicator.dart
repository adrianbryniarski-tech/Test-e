import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/core/offline/sync_providers.dart';

/// Ikona w app barze pokazująca stan sync:
///
/// - ☁️ done (brak pendingów) — `Icons.cloud_done_outlined`
/// - ⏳N pending — `Icons.cloud_sync_outlined` + badge z liczbą
/// - ⚠️ błąd na którymś rekordzie — `Icons.cloud_off_outlined`
///
/// Tap → wymusza `syncNow()` (np. żeby przyspieszyć po włączeniu wifi).
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final counts = ref.watch(pendingCountsProvider);

    final (icon, label, color) = counts.maybeWhen(
      data: (c) {
        if (c.errors > 0) {
          return (
            Icons.cloud_off_outlined,
            'Sync wstrzymany — stuknij, żeby spróbować ponownie',
            cs.error,
          );
        }
        if (c.total > 0) {
          return (
            Icons.cloud_sync_outlined,
            '${c.total} ${_pluralOps(c.total)} czeka na sync',
            cs.primary,
          );
        }
        return (
          Icons.cloud_done_outlined,
          'Wszystko zsynchronizowane',
          cs.onSurfaceVariant,
        );
      },
      orElse: () => (
        Icons.cloud_outlined,
        'Sprawdzam stan sync...',
        cs.onSurfaceVariant,
      ),
    );

    final badgeCount = counts.maybeWhen(
      data: (c) => c.total,
      orElse: () => 0,
    );

    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: () => ref.read(syncWorkerProvider).syncNow(),
        icon: badgeCount > 0
            ? Badge(
                label: Text('$badgeCount'),
                child: Icon(icon, color: color),
              )
            : Icon(icon, color: color),
      ),
    );
  }

  static String _pluralOps(int n) {
    // PL: 1 → "operacja", 2-4 → "operacje", reszta → "operacji".
    if (n == 1) return 'operacja';
    final tens = n % 100;
    final units = n % 10;
    if (tens >= 12 && tens <= 14) return 'operacji';
    if (units >= 2 && units <= 4) return 'operacje';
    return 'operacji';
  }
}
