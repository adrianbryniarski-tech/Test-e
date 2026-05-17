import 'dart:math';

import 'package:flutter/material.dart';

/// Generic animacja-deszcz emoji. Podajesz listę glyph'ów (np. ['🚗','⛽']),
/// widget renderuje ~20 sztuk spadających z górnej krawędzi z różnymi
/// rozmiarami, rotacją i opóźnieniem. Używane do "ekspresyjnych" wydatków
/// per kategoria (transport, zdrowie, dzieci, rozrywka, itp.).
///
/// Dla "specjalnych" animacji (np. T-rex zjadający burgera) używaj
/// dedykowanych widgetów. Ten widget jest dla "typowych" wydatków.
class EmojiBurst extends StatefulWidget {
  const EmojiBurst({
    required this.glyphs,
    this.count = 22,
    this.duration = const Duration(milliseconds: 1400),
    super.key,
  });

  final List<String> glyphs;
  final int count;
  final Duration duration;

  static void show(
    BuildContext context, {
    required List<String> glyphs,
  }) {
    if (glyphs.isEmpty) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(child: EmojiBurst(glyphs: glyphs)),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(
      const Duration(milliseconds: 1600),
      entry.remove,
    );
  }

  @override
  State<EmojiBurst> createState() => _EmojiBurstState();
}

class _EmojiBurstState extends State<EmojiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
    final rng = Random();
    _particles = List.generate(widget.count, (_) {
      return _Particle(
        glyph: widget.glyphs[rng.nextInt(widget.glyphs.length)],
        startXFraction: rng.nextDouble(),
        fontSize: 28.0 + rng.nextDouble() * 22,
        rotation: (rng.nextDouble() - 0.5) * 0.8,
        fallDelay: rng.nextDouble() * 0.35,
        horizontalSway: (rng.nextDouble() - 0.5) * 50,
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
          painter: _BurstPainter(
            t: _controller.value,
            particles: _particles,
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

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.t, required this.particles});

  final double t;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final particleT =
          ((t - p.fallDelay) / (1.0 - p.fallDelay)).clamp(0.0, 1.0);
      if (particleT == 0) continue;

      final startY = -p.fontSize;
      final endY = size.height + p.fontSize;
      final y = startY + (endY - startY) * particleT;
      final x = p.startXFraction * size.width +
          sin(particleT * 2 * pi) * p.horizontalSway;

      final opacity =
          particleT < 0.85 ? 1.0 : (1 - (particleT - 0.85) / 0.15);
      final rotationNow = p.rotation + particleT * pi * 0.5;

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
  bool shouldRepaint(_BurstPainter oldDelegate) => oldDelegate.t != t;
}

/// Mapowanie kategorii (po słowach kluczowych w nazwie) na zestaw emoji.
/// `null` = brak dopasowania → caller użyje fallback'a (ExpenseFlash).
///
/// Sprawdzamy lowercase + bez polskich znaków po podstawowych prefiksach,
/// żeby user mógł nazwać kategorię "Spożywcze", "Spożywka", "Jedzenie" itp.
List<String>? emojisForCategory(String categoryName) {
  final n = categoryName.toLowerCase();
  bool has(List<String> keys) => keys.any(n.contains);

  if (has(['transport', 'paliw', 'samoch'])) {
    return const ['🚗', '⛽', '🛣️', '🚙'];
  }
  if (has(['zdrow', 'aptek', 'lekarz', 'medyc'])) {
    return const ['💊', '🩺', '🏥', '💉'];
  }
  if (has(['dziec', 'niemowl', 'maluch'])) {
    return const ['🧸', '🍼', '🎈', '🚼'];
  }
  if (has(['rozryw', 'kino', 'gier', 'koncert'])) {
    return const ['🎬', '🍿', '🎮', '🎤'];
  }
  if (has(['mieszk', 'dom', 'remont', 'czynsz'])) {
    return const ['🏠', '🛋️', '🪴', '🔨'];
  }
  if (has(['ubran', 'odzież', 'butów'])) {
    return const ['👕', '👗', '👟', '🧥'];
  }
  if (has(['rachun', 'prąd', 'gaz', 'wod', 'internet'])) {
    return const ['📄', '💡', '💸', '⚡'];
  }
  if (has(['subskryp', 'netflix', 'spotify'])) {
    return const ['📺', '🎵', '☁️', '🔔'];
  }
  if (has(['hobby', 'sport', 'siłow'])) {
    return const ['🏋️', '⚽', '🎨', '📚'];
  }
  if (has(['uroda', 'kosmet', 'fryzj'])) {
    return const ['💄', '💅', '💆', '✨'];
  }
  if (has(['prezent', 'urodz', 'święt'])) {
    return const ['🎁', '🎉', '🎂', '🎈'];
  }
  if (has(['oszczęd', 'inwest'])) {
    return const ['🐷', '💰', '📈', '🏦'];
  }
  // Pensja / inne dochody traktujemy osobno (deszcz monet w MoneyRain).
  return null;
}
