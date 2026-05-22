import 'package:flutter/material.dart';
import 'package:nasz_budzet_domowy/features/onboarding/data/changelog.dart';
import 'package:nasz_budzet_domowy/shared/widgets/comic_shadow.dart';

/// Ekran „Co nowego" — historia zmian, najnowsze na górze. Dostępny z
/// Ustawień. Treść w `changelog.dart` (lista [kChangelog]).
class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Co nowego')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          for (final entry in kChangelog)
            ComicCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      entry.date,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final change in entry.changes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '•  ',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Expanded(
                              child: Text(
                                change,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pokazuje okienko „Co nowego" RAZ po wejściu do nowej wersji. Sam decyduje
/// na podstawie zapamiętanego klucza — wywołuj bez warunków, np. z ekranu
/// głównego. `seenVersion` to ostatnio zapamiętany klucz (null = nigdy).
Future<void> showWhatsNewIfNeeded(
  BuildContext context, {
  required String? seenVersion,
  required Future<void> Function(String version) onSeen,
}) async {
  if (seenVersion == currentChangelogVersion || kChangelog.isEmpty) return;
  final entry = kChangelog.first;
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        title: Text(entry.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final change in entry.changes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(
                        child: Text(
                          change,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Super, dzięki'),
          ),
        ],
      );
    },
  );
  await onSeen(currentChangelogVersion);
}
