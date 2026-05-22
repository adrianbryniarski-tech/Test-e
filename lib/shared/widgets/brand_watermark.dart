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
    canvas
      ..drawCircle(c, r, Paint()..color = const Color(0xFFF2A33C))
      // Połysk w lewym górnym rogu.
      ..drawCircle(
        Offset(c.dx - r * 0.3, c.dy - r * 0.3),
        r * 0.35,
        Paint()..color = const Color(0x66FFFFFF),
      )
      ..drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFFC85A12),
      );
    // Cztery czerwone gwiazdki w kwadracie.
    final star = Paint()..color = const Color(0xFFD32F2F);
    final d = r * 0.38;
    final sr = r * 0.22;
    for (final o in [
      Offset(c.dx - d, c.dy - d),
      Offset(c.dx + d, c.dy - d),
      Offset(c.dx - d, c.dy + d),
      Offset(c.dx + d, c.dy + d),
    ]) {
      canvas.drawPath(_starPath(o, sr), star);
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
