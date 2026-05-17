import 'dart:math';

import 'package:flutter/material.dart';

/// Burst iskier ze środka ekranu — używamy przy nowym budżecie. Tani
/// efekt celebracji, nie tak głośny jak deszcz monet.
class SparkleBurst extends StatefulWidget {
  const SparkleBurst({super.key});

  static void show(BuildContext context) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => const Positioned.fill(
        child: IgnorePointer(child: SparkleBurst()),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(const Duration(milliseconds: 1100), entry.remove);
  }

  @override
  State<SparkleBurst> createState() => _SparkleBurstState();
}

class _SparkleBurstState extends State<SparkleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Spark> _sparks;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    final rng = Random();
    _sparks = List.generate(20, (_) {
      final angle = rng.nextDouble() * 2 * pi;
      return _Spark(
        angle: angle,
        distance: 80.0 + rng.nextDouble() * 140,
        size: 12.0 + rng.nextDouble() * 14,
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
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _SparklePainter(t: _controller.value, sparks: _sparks),
            size: const Size(300, 300),
          );
        },
      ),
    );
  }
}

class _Spark {
  const _Spark({
    required this.angle,
    required this.distance,
    required this.size,
  });
  final double angle;
  final double distance;
  final double size;
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.t, required this.sparks});

  final double t;
  final List<_Spark> sparks;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final s in sparks) {
      final radius = s.distance * Curves.easeOut.transform(t);
      final position = Offset(
        center.dx + cos(s.angle) * radius,
        center.dy + sin(s.angle) * radius,
      );
      final opacity = t < 0.6 ? 1.0 : (1 - (t - 0.6) / 0.4);

      final tp = TextPainter(
        text: TextSpan(
          text: '✨',
          style: TextStyle(
            fontSize: s.size,
            color: Colors.white.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        position - Offset(tp.width / 2, tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => oldDelegate.t != t;
}
