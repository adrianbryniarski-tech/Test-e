import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/settings/application/theme_providers.dart';

/// Kolor „tuszu" motywu komiksowego (obrys + cień) zależny od wariantu i
/// jasności. Manga = czysta czerń/biel; Kredka = ciepły grafit/krem.
Color comicInk(AppThemeVariant variant, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (variant) {
    AppThemeVariant.manga =>
      dark ? const Color(0xFFFFFFFF) : const Color(0xFF111111),
    _ => dark ? const Color(0xFFFFE0C2) : const Color(0xFF231A12),
  };
}

/// Dokłada twardy, przesunięty „komiksowy" cień (czarna kreska bez rozmycia)
/// pod dzieckiem — tylko dla motywów komiksowych (Kredka, Manga). Dla
/// pozostałych zwraca child bez zmian. Promień musi pasować do karty.
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
    final variant = ref.watch(themeVariantProvider);
    if (!variant.isComic) return child;
    // Manga = ostre kanty → cień prawie kwadratowy (pasuje do panelu).
    final radius = variant == AppThemeVariant.manga ? 1.0 : borderRadius;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: comicInk(variant, Theme.of(context).brightness),
            offset: const Offset(5, 5),
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
