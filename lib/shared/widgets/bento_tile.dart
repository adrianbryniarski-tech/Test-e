import 'package:flutter/material.dart';

/// Kafelek bento — spójna karta dla dashboardu.
///
/// Używa Material 3 `surfaceContainerHigh` z subtelnymi zaokrągleniami
/// i bezpośrednim paddingiem. Tytuł + opcjonalny trailing w nagłówku,
/// `child` wypełnia resztę karty.
class BentoTile extends StatelessWidget {
  const BentoTile({
    required this.title,
    required this.child,
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 16),
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: tt.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
