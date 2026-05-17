import 'package:flutter/material.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category.dart';
import 'package:nasz_budzet_domowy/shared/widgets/material_symbol_icon.dart';

/// Małe kółko z kolorem + ikoną kategorii. Używane w liście transakcji,
/// chipach filtrów, pickerach, wynikach voice.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    required this.category,
    this.size = 36,
    super.key,
  });

  final Category category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = CategoryPalette.fromHex(category.colorHex);
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
