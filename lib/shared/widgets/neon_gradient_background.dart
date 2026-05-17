import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/features/settings/application/theme_providers.dart';

/// Owija child w subtelny gradient tła (radial w lewym górnym rogu,
/// drugi w prawym dolnym). Aktywuje się TYLKO dla motywów neon
/// (cyber/synthwave/galaktyka) — dla pozostałych zwraca child bez
/// modyfikacji (zero overhead).
///
/// Użyć w głównym body Scaffold'a żeby cała apka miała "głębię".
class NeonGradientBackground extends ConsumerWidget {
  const NeonGradientBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(themeVariantProvider);
    if (!variant.hasNeonEffects) return child;

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = scheme.primary;
    final accent = variant.gradientAccent;
    // W ciemnym tle gradient mocniejszy (większa alpha), bo nie ginie
    // w niebycie. W jasnym subtelny.
    final alphaPrimary = isDark ? 0.18 : 0.08;
    final alphaAccent = isDark ? 0.14 : 0.06;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.8, -0.9),
                radius: 1.3,
                colors: [
                  primary.withValues(alpha: alphaPrimary),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.9, 0.9),
                radius: 1.3,
                colors: [
                  accent.withValues(alpha: alphaAccent),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
