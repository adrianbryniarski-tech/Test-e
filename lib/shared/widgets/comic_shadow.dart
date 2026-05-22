import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/settings/application/theme_providers.dart';

/// Kolor „tuszu" Kredki (obrys + komiksowy cień) zależny od jasności.
Color kredkaInk(Brightness brightness) => brightness == Brightness.dark
    ? const Color(0xFFFFE0C2)
    : const Color(0xFF231A12);

/// Dokłada twardy, przesunięty „komiksowy" cień (czarna kreska bez rozmycia)
/// pod dzieckiem — TYLKO dla motywu „Kredka". Dla pozostałych motywów zwraca
/// child bez zmian (zero kosztu). Promień musi pasować do zaokrąglenia karty.
class ComicShadow extends ConsumerWidget {
  const ComicShadow({
    required this.child,
    this.borderRadius = 16,
    super.key,
  });

  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(themeVariantProvider) != AppThemeVariant.kredka) {
      return child;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: kredkaInk(Theme.of(context).brightness),
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// `Card` z komiksowym cieniem dla „Kredki" (poza tym zachowuje się jak zwykły
/// Card). Drop-in zamiennik: wystarczy `Card(` → `ComicCard(`.
class ComicCard extends ConsumerWidget {
  const ComicCard({
    super.key,
    this.child,
    this.color,
    this.elevation,
    this.margin,
    this.shape,
    this.clipBehavior,
  });

  final Widget? child;
  final Color? color;
  final double? elevation;
  final EdgeInsetsGeometry? margin;
  final ShapeBorder? shape;
  final Clip? clipBehavior;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ComicShadow(
      child: Card(
        color: color,
        elevation: elevation,
        margin: margin,
        shape: shape,
        clipBehavior: clipBehavior,
        child: child,
      ),
    );
  }
}
