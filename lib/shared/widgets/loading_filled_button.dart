import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/settings/application/theme_providers.dart';
import 'package:nasz_budzet_domowy/shared/widgets/comic_shadow.dart';

/// `FilledButton` z wbudowanym stanem ładowania.
///
/// Podczas `isLoading == true` przycisk jest zablokowany (onPressed = null),
/// pokazuje `CircularProgressIndicator` zamiast tekstu, ale zachowuje tę
/// samą wysokość — uniknięcie skoków layoutu w trakcie żądania sieciowego.
///
/// W motywie Manga przyjmuje komiksową fizykę: twardy przesunięty cień i
/// efekt fizycznego „wciśnięcia" (przesunięcie + zniknięcie cienia).
class LoadingFilledButton extends ConsumerWidget {
  const LoadingFilledButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 10),
              ],
              Text(label),
            ],
          );

    final isManga = ref.watch(themeVariantProvider) == AppThemeVariant.manga;
    if (isManga) {
      return _ComicButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}

/// Przycisk z komiksową „fizyką": twardy cień + wciśnięcie (Manga).
class _ComicButton extends StatefulWidget {
  const _ComicButton({required this.child, this.onPressed});

  final Widget child;
  final VoidCallback? onPressed;

  @override
  State<_ComicButton> createState() => _ComicButtonState();
}

class _ComicButtonState extends State<_ComicButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ink = comicInk(
      AppThemeVariant.manga,
      Theme.of(context).scaffoldBackgroundColor,
    );
    final enabled = widget.onPressed != null;
    final down = _pressed && enabled;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed!();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: Transform.translate(
        offset: down ? const Offset(5, 5) : Offset.zero,
        child: Container(
          width: double.infinity,
          height: 52,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: enabled ? cs.primary : cs.surfaceContainerHighest,
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: ink, width: 3),
            ),
            // Twardy cień bez rozmycia; znika przy wciśnięciu (iluzja głębi).
            shadows: down
                ? null
                : [BoxShadow(color: ink, offset: const Offset(5, 5))],
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: cs.onPrimary,
              fontWeight: FontWeight.w700,
            ),
            child: IconTheme(
              data: IconThemeData(color: cs.onPrimary),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
