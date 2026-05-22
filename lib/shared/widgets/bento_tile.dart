import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/settings/application/theme_providers.dart';
import 'package:nasz_budzet_domowy/shared/widgets/comic_shadow.dart';

/// Kafelek bento — spójna karta dla dashboardu.
///
/// Używa Material 3 `surfaceContainerHigh` z subtelnymi zaokrągleniami
/// i bezpośrednim paddingiem. Tytuł + opcjonalny trailing w nagłówku,
/// `child` wypełnia resztę karty. Dla „Kredki" dostaje gruby obrys i
/// komiksowy cień.
class BentoTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isKredka = ref.watch(themeVariantProvider) == AppThemeVariant.kredka;
    // RepaintBoundary: każdy kafelek (często z wykresem) maluje się osobno,
    // więc przerysowanie jednego nie odświeża pozostałych.
    return RepaintBoundary(
      child: ComicShadow(
        borderRadius: 20,
        child: Card(
          elevation: 0,
          color: cs.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isKredka
                ? BorderSide(
                    color: kredkaInk(Theme.of(context).brightness),
                    width: 2.5,
                  )
                : BorderSide.none,
          ),
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
        ),
      ),
    );
  }
}
