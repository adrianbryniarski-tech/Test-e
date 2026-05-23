import 'package:flutter/material.dart';
import 'package:nasz_budzet_domowy/shared/widgets/manga_icons.dart';

/// Inline banner z komunikatem błędu — czerwony akcent, ikona ostrzeżenia,
/// 12% opacity tła. Używany pod polem formularza zamiast `SnackBar`-a
/// (lepiej widoczny, nie znika sam, czytelny dla nawigacji klawiaturą).
class InlineError extends StatelessWidget {
  const InlineError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(Icons.error_outline, size: 20, color: scheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
