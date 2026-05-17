import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/features/settings/application/theme_providers.dart';

/// Owija child w animowany neonowy border który "rotuje" — gradient
/// liniowy z głównego primary do accent przesuwa się wokół widgetu.
/// Daje "wow" efekt na kafelkach typu Saldo na dashboardzie.
///
/// Aktywuje się TYLKO dla motywów neon. Inne zwracają child bez modyfikacji.
class AnimatedNeonBorder extends ConsumerStatefulWidget {
  const AnimatedNeonBorder({
    required this.child,
    this.borderRadius = 20,
    this.borderWidth = 2,
    super.key,
  });

  final Widget child;
  final double borderRadius;
  final double borderWidth;

  @override
  ConsumerState<AnimatedNeonBorder> createState() => _AnimatedNeonBorderState();
}

class _AnimatedNeonBorderState extends ConsumerState<AnimatedNeonBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final variant = ref.watch(themeVariantProvider);
    if (!variant.hasNeonEffects) return widget.child;

    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final accent = variant.gradientAccent;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: _NeonBorderPainter(
            t: _controller.value,
            primary: primary,
            accent: accent,
            borderRadius: widget.borderRadius,
            borderWidth: widget.borderWidth,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _NeonBorderPainter extends CustomPainter {
  const _NeonBorderPainter({
    required this.t,
    required this.primary,
    required this.accent,
    required this.borderRadius,
    required this.borderWidth,
  });

  final double t;
  final Color primary;
  final Color accent;
  final double borderRadius;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(borderWidth / 2),
      Radius.circular(borderRadius),
    );

    // Sweep gradient rotujący zgodnie z `t`. Daje "płynące światło"
    // wokół krawędzi.
    final shader = SweepGradient(
      transform: GradientRotation(t * 2 * pi),
      colors: [
        primary.withValues(alpha: 0.9),
        accent.withValues(alpha: 0.6),
        primary.withValues(alpha: 0.2),
        primary.withValues(alpha: 0.9),
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    ).createShader(rect);

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_NeonBorderPainter old) => old.t != t;
}
