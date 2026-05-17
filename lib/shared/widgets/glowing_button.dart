import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/features/settings/application/theme_providers.dart';

/// FilledButton z neon glow effect (BoxShadow blur+spread w kolorze
/// primary). Tylko dla neonowych motywów — dla pozostałych renderuje
/// zwykły FilledButton (kompozycja, nie hack).
class GlowingFilledButton extends ConsumerWidget {
  const GlowingFilledButton({
    required this.onPressed,
    required this.child,
    this.icon,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(themeVariantProvider);
    final scheme = Theme.of(context).colorScheme;
    final button = icon != null
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: child,
          )
        : FilledButton(onPressed: onPressed, child: child);

    if (!variant.hasNeonEffects) return button;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // Soft glow — szeroki blur, niska alpha.
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.45),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          // Wewnętrzny mocniejszy glow.
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.25),
            blurRadius: 8,
          ),
        ],
      ),
      child: button,
    );
  }
}

/// FAB z neon glow. Wrapper na FloatingActionButton dodający
/// `BoxShadow` w kolorze primary gdy motyw neon.
class GlowingFAB extends ConsumerWidget {
  const GlowingFAB({
    required this.onPressed,
    required this.child,
    this.tooltip,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(themeVariantProvider);
    final scheme = Theme.of(context).colorScheme;
    final fab = FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      child: child,
    );

    if (!variant.hasNeonEffects) return fab;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.55),
            blurRadius: 24,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.30),
            blurRadius: 10,
          ),
        ],
      ),
      child: fab,
    );
  }
}
