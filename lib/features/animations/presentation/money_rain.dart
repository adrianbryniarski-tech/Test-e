import 'dart:math';

import 'package:flutter/material.dart';

/// Animacja: z górnej krawędzi ekranu spada N emoji-monet/banknotów.
/// Pokazywana jako fullscreen Overlay przez ~1.5s przy dodaniu dochodu.
///
/// Implementacja: jeden `AnimationController` (0..1) driver'uje N
/// `_Particle` (random start x, random fall speed, random rotation),
/// `CustomPaint` rysuje wszystkie w jednym repaint cyklu — taniej niż
/// N osobnych widgetów z AnimationBuildera.
class MoneyRain extends StatefulWidget {
  const MoneyRain({
    this.duration = const Duration(milliseconds: 1500),
    super.key,
  });

  final Duration duration;

  /// Pokazuje animację jako Overlay nad bieżącym ekranem.
  /// Automatycznie się ściąga po zakończeniu — caller nie musi sprzątać.
  static void show(BuildContext context, {Duration? duration}) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          child: MoneyRain(
            duration: duration ?? const Duration(milliseconds: 1500),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(
      (duration ?? const Duration(milliseconds: 1500)) +
          const Duration(milliseconds: 200),
      entry.remove,
    );
  }

  @override
  State<MoneyRain> createState() => _MoneyRainState();
}

class _MoneyRainState extends State<MoneyRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  static const _glyphs = ['💵', '💰', '💸', '🪙', '💶', '💴'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
    final rng = Random();
    _particles = List.generate(28, (i) {
      return _Particle(
        glyph: _glyphs[rng.nextInt(_glyphs.length)],
        startXFraction: rng.nextDouble(),
        fontSize: 24.0 + rng.nextDouble() * 24,
        rotation: (rng.nextDouble() - 0.5) * 0.8,
        fallDelay: rng.nextDouble() * 0.3,
        horizontalSway: (rng.nextDouble() - 0.5) * 60,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _RainPainter(
            t: _controller.value,
            particles: _particles,
            screenSize: MediaQuery.of(context).size,
          ),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}

class _Particle {
  const _Particle({
    required this.glyph,
    required this.startXFraction,
    required this.fontSize,
    required this.rotation,
    required this.fallDelay,
    required this.horizontalSway,
  });

  final String glyph;
  final double startXFraction;
  final double fontSize;
  final double rotation;
  final double fallDelay;
  final double horizontalSway;
}

class _RainPainter extends CustomPainter {
  _RainPainter({
    required this.t,
    required this.particles,
    required this.screenSize,
  });

  final double t;
  final List<_Particle> particles;
  final Size screenSize;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final particleT = ((t - p.fallDelay) / (1.0 - p.fallDelay))
          .clamp(0.0, 1.0);
      if (particleT == 0) continue;

      final startY = -p.fontSize;
      final endY = size.height + p.fontSize;
      final y = startY + (endY - startY) * particleT;

      final swayProgress = particleT * 2 * pi;
      final x = p.startXFraction * size.width +
          sin(swayProgress) * p.horizontalSway;

      final opacity =
          particleT < 0.85 ? 1.0 : (1 - (particleT - 0.85) / 0.15);
      final rotationNow = p.rotation + particleT * pi * 0.6;

      final tp = TextPainter(
        text: TextSpan(
          text: p.glyph,
          style: TextStyle(
            fontSize: p.fontSize,
            color: Colors.white.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas
        ..save()
        ..translate(x, y)
        ..rotate(rotationNow);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RainPainter oldDelegate) => oldDelegate.t != t;
}
