import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/settings/application/theme_providers.dart';

/// Znak wodny "made by AB Corporation" w lewym dolnym rogu. Przyklejony
/// (nie scrolluje z treścią), `IgnorePointer` (nie blokuje tapów pod
/// spodem). Logo przełącza się granat↔biały zależnie od jasności motywu.
///
/// Dla motywów anime (Dragon Ball / Pokémon) zamiast logo PNG rysujemy
/// tematyczny emblemat (smocza kula / Poké Ball).
///
/// Używać w `Stack` na poziomie shella (pokrywa wszystkie zakładki),
/// nad treścią ale pod FAB/nawigacją.
class BrandWatermark extends ConsumerWidget {
  const BrandWatermark({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(themeVariantProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2B4A);

    final logo = switch (variant) {
      AppThemeVariant.dragonBall => const _ThemeEmblem(_EmblemKind.dragonBall),
      AppThemeVariant.pokemon => const _ThemeEmblem(_EmblemKind.pokeball),
      _ => Image.asset(
          isDark
              ? 'assets/icons/watermark_dark.png'
              : 'assets/icons/watermark_light.png',
          width: 44,
        ),
    };

    return Positioned(
      left: 16,
      bottom: 12,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              logo,
              const SizedBox(height: 1),
              Text(
                'made by AB Corporation',
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _EmblemKind { dragonBall, pokeball }

/// Prosty, oryginalny emblemat rysowany na canvasie (bez grafik z franczyz):
/// smocza kula (pomarańcz + czerwone gwiazdki) lub Poké Ball (czerwień/biel).
class _ThemeEmblem extends StatelessWidget {
  const _ThemeEmblem(this.kind);

  final _EmblemKind kind;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: CustomPaint(painter: _EmblemPainter(kind)),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  _EmblemPainter(this.kind);

  final _EmblemKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    switch (kind) {
      case _EmblemKind.dragonBall:
        _paintDragonBall(canvas, center, radius);
      case _EmblemKind.pokeball:
        _paintPokeball(canvas, center, radius);
    }
  }

  void _paintDragonBall(Canvas canvas, Offset c, double r) {
    final ballR = r * 0.72;
    final ballRect = Rect.fromCircle(center: c, radius: ballR);

    // Aura energii (złoty blask zanikający na zewnątrz).
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x55FFC107), Color(0x00FFC107)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Iskry ki dookoła kuli (na przemian długie/krótkie).
    final spark = Paint()
      ..color = const Color(0xFFFFD24D)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final inner = ballR * 1.06;
      final outer = i.isEven ? r * 0.99 : ballR * 1.32;
      canvas.drawLine(
        Offset(c.dx + inner * math.cos(a), c.dy + inner * math.sin(a)),
        Offset(c.dx + outer * math.cos(a), c.dy + outer * math.sin(a)),
        spark,
      );
    }

    // Kula z cieniowaniem 3D, połyskiem i obrysem.
    canvas
      ..drawCircle(
        c,
        ballR,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.4, -0.4),
            radius: 1.1,
            colors: [Color(0xFFFFD98A), Color(0xFFF2A33C), Color(0xFFD9740F)],
            stops: [0.0, 0.55, 1.0],
          ).createShader(ballRect),
      )
      ..drawCircle(
        Offset(c.dx - ballR * 0.32, c.dy - ballR * 0.36),
        ballR * 0.26,
        Paint()..color = const Color(0x88FFFFFF),
      )
      ..drawCircle(
        c,
        ballR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0xFFC85A12),
      );

    // Cztery czerwone gwiazdki z cienkim obrysem (lepszy kontrast).
    final starFill = Paint()..color = const Color(0xFFE53935);
    final starLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFF8E1B1B);
    final d = ballR * 0.4;
    final sr = ballR * 0.24;
    for (final o in [
      Offset(c.dx - d, c.dy - d),
      Offset(c.dx + d, c.dy - d),
      Offset(c.dx - d, c.dy + d),
      Offset(c.dx + d, c.dy + d),
    ]) {
      final p = _starPath(o, sr);
      canvas
        ..drawPath(p, starFill)
        ..drawPath(p, starLine);
    }
  }

  void _paintPokeball(Canvas canvas, Offset c, double r) {
    final whole = Rect.fromCircle(center: c, radius: r);
    final black = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.16
      ..color = const Color(0xFF111111);
    canvas
      // Górna połowa czerwona, dolna biała.
      ..drawArc(
        whole,
        math.pi,
        math.pi,
        true,
        Paint()..color = const Color(0xFFE3350D),
      )
      ..drawArc(whole, 0, math.pi, true, Paint()..color = Colors.white)
      // Połysk na czerwonej kopule.
      ..drawCircle(
        Offset(c.dx - r * 0.34, c.dy - r * 0.42),
        r * 0.24,
        Paint()..color = const Color(0x66FFFFFF),
      )
      // Czarny pas równikowy + obrys kuli.
      ..drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), black)
      ..drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFF111111),
      )
      // Środkowy guzik.
      ..drawCircle(c, r * 0.3, Paint()..color = const Color(0xFF111111))
      ..drawCircle(c, r * 0.2, Paint()..color = Colors.white)
      ..drawCircle(
        c,
        r * 0.2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFF111111),
      );
  }

  Path _starPath(Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final outerA = -math.pi / 2 + i * 2 * math.pi / 5;
      final innerA = outerA + math.pi / 5;
      final ox = c.dx + r * math.cos(outerA);
      final oy = c.dy + r * math.sin(outerA);
      final ix = c.dx + r * 0.5 * math.cos(innerA);
      final iy = c.dy + r * 0.5 * math.sin(innerA);
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_EmblemPainter oldDelegate) => oldDelegate.kind != kind;
}
