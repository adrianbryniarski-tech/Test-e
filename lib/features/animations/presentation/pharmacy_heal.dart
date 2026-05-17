import 'dart:math';

import 'package:flutter/material.dart';

/// Animacja "Pharmacy Heal" — chory 🤧 w środku, lecą do niego pigułki
/// 💊 z różnych stron, po połknięciu zmienia się w 😎. Krótka,
/// satysfakcjonująca sekwencja dla wydatków na Zdrowie / Aptekę.
class PharmacyHeal extends StatefulWidget {
  const PharmacyHeal({super.key});

  static void show(BuildContext context) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => const Positioned.fill(
        child: IgnorePointer(child: PharmacyHeal()),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(const Duration(milliseconds: 1900), entry.remove);
  }

  @override
  State<PharmacyHeal> createState() => _PharmacyHealState();
}

class _PharmacyHealState extends State<PharmacyHeal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = size.height * 0.5;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // Faza 1 (0..0.45): pigułki lecą do centrum z 6 kierunków
        // Faza 2 (0.45..0.60): wchłaniają się
        // Faza 3 (0.60..0.85): pacjent zmienia 🤧 → 😎 + scale up
        // Faza 4 (0.85..1.0): fade out
        final fadeT = ((t - 0.85) / 0.15).clamp(0.0, 1.0);
        final globalOpacity = 1 - fadeT;
        final pillsT = (t / 0.45).clamp(0.0, 1.0);
        final healedT = ((t - 0.6) / 0.25).clamp(0.0, 1.0);

        final pills = List<Widget>.generate(6, (i) {
          final angle = 60.0 * i * pi / 180;
          final dx = 200.0 * (1 - pillsT);
          final pillX = centerX + dx * cos(angle) - 16;
          final pillY = centerY + dx * sin(angle) - 16;
          final pillOpacity = pillsT < 0.9 ? 1.0 : (1 - (pillsT - 0.9) * 10);
          return Positioned(
            left: pillX,
            top: pillY,
            child: Opacity(
              opacity: pillOpacity * globalOpacity,
              child: Transform.rotate(
                angle: pillsT * 4,
                child: const Text('💊', style: TextStyle(fontSize: 32)),
              ),
            ),
          );
        });

        final patientGlyph = healedT < 0.5 ? '🤧' : '😎';
        final patientScale = 1.0 + healedT * 0.3;

        return Stack(
          children: [
            ...pills,
            Positioned(
              left: centerX - 40,
              top: centerY - 40,
              child: Opacity(
                opacity: globalOpacity,
                child: Transform.scale(
                  scale: patientScale,
                  child: Text(
                    patientGlyph,
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
