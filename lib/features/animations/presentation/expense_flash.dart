import 'package:flutter/material.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';

/// Krótki czerwony pulse na całym ekranie (~600ms) gdy zapisany został
/// wydatek. Niskobodźcowy, ale czytelny sygnał "minęła kasa".
class ExpenseFlash extends StatefulWidget {
  const ExpenseFlash({super.key});

  static void show(BuildContext context) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => const Positioned.fill(
        child: IgnorePointer(child: ExpenseFlash()),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(const Duration(milliseconds: 700), entry.remove);
  }

  @override
  State<ExpenseFlash> createState() => _ExpenseFlashState();
}

class _ExpenseFlashState extends State<ExpenseFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.35), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 0), weight: 70),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) {
        return Container(
          color: AppTheme.expenseAccent.withValues(alpha: _opacity.value),
        );
      },
    );
  }
}
