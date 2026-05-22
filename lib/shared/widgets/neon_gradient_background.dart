import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/settings/application/theme_providers.dart';

/// Owija child w tło zależne od motywu:
/// - neon (cyber/synthwave/galaktyka) → subtelny podwójny radial gradient,
/// - Kredka → komiksowy raster kropek (halftone) na całej apce,
/// - pozostałe → child bez zmian (zero overhead).
///
/// Użyć w głównym body Scaffold'a żeby cała apka miała spójny charakter.
class NeonGradientBackground extends ConsumerWidget {
  const NeonGradientBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(themeVariantProvider);

    // Komiksowy raster kropek dla „Kredki". RepaintBoundary + isComplex →
    // Skia cache'uje raster i nie przerysowuje go przy każdej klatce treści
    // (inaczej ~1500 kropek malowanych co scroll = zauważalne przycinanie).
    if (variant == AppThemeVariant.kredka) {
      final ink = Theme.of(context).colorScheme.onSurface;
      return Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _HalftonePainter(ink.withValues(alpha: 0.06)),
                isComplex: true,
              ),
            ),
          ),
          child,
        ],
      );
    }

    if (!variant.hasGradientBackground) return child;

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
        // Gradienty są statyczne — RepaintBoundary izoluje je od przerysowań
        // treści (scroll/animacje), żeby nie malowały się co klatkę.
        Positioned.fill(
          child: RepaintBoundary(
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
        ),
        Positioned.fill(
          child: RepaintBoundary(
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
        ),
        child,
      ],
    );
  }
}

/// Rysuje równomierną siatkę kropek (efekt komiksowego rastra/halftone).
class _HalftonePainter extends CustomPainter {
  _HalftonePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const gap = 16.0;
    const radius = 1.4;
    for (var y = 0.0; y < size.height; y += gap) {
      for (var x = 0.0; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HalftonePainter oldDelegate) =>
      oldDelegate.color != color;
}
