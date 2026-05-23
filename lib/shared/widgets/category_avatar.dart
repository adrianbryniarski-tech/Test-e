import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category.dart';
import 'package:nasz_budzet_domowy/features/settings/application/theme_providers.dart';
import 'package:nasz_budzet_domowy/shared/widgets/comic_shadow.dart';
import 'package:nasz_budzet_domowy/shared/widgets/material_symbol_icon.dart';

/// Małe kółko z kolorem + ikoną kategorii. Używane w liście transakcji,
/// chipach filtrów, pickerach, wynikach voice.
///
/// W motywach komiksowych (Kredka/Manga) zamiast miękkiego pastelu rysujemy
/// płaski kolor z grubym czarnym konturem i czarną ikoną — komiksowo.
class CategoryAvatar extends ConsumerWidget {
  const CategoryAvatar({
    required this.category,
    this.size = 36,
    super.key,
  });

  final Category category;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = CategoryPalette.fromHex(category.colorHex);
    final variant = ref.watch(themeVariantProvider);

    if (variant.isComic) {
      final ink = comicInk(variant, Theme.of(context).scaffoldBackgroundColor);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: ink, width: size * 0.075),
        ),
        alignment: Alignment.center,
        child: MaterialSymbolIcon(
          name: category.icon,
          size: size * 0.5,
          color: ink,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: MaterialSymbolIcon(
        name: category.icon,
        size: size * 0.55,
        color: color,
      ),
    );
  }
}
