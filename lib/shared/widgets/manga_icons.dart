// Plik czysto rysujący na canvasie — sekwencje `canvas.drawX` są czytelniejsze
// niż wymuszone kaskady.
// ignore_for_file: cascade_invocations

import 'package:flutter/material.dart';

/// Rodzaje komiksowych ikon rysowanych ręcznie (motyw „Manga").
enum MangaIconKind {
  dashboard,
  transactions,
  budgets,
  investments,
  categories,
  add,
  mic,
}

/// Ikona w stylu komiksowym/manga — grube czarne kontury rysowane na canvasie.
/// Kolor bierze z `IconTheme` (więc dziedziczy zaznaczenie z NavigationBar).
/// `filled` (zaznaczona) pogrubia kreskę i dokłada delikatne wypełnienie.
class MangaIcon extends StatelessWidget {
  const MangaIcon(
    this.kind, {
    this.filled = false,
    this.size = 24,
    this.color,
    super.key,
  });

  final MangaIconKind kind;
  final bool filled;
  final double size;

  /// Wymusza kolor; gdy null — bierze z `IconTheme` (zaznaczenie nav baru).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? const Color(0xFF111111);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MangaIconPainter(kind, c, filled: filled),
      ),
    );
  }
}

class _MangaIconPainter extends CustomPainter {
  _MangaIconPainter(this.kind, this.color, {required this.filled});

  final MangaIconKind kind;
  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = filled ? s * 0.12 : s * 0.095
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color.withValues(alpha: 0.18);

    switch (kind) {
      case MangaIconKind.dashboard:
        _dashboard(canvas, s, stroke, fill);
      case MangaIconKind.transactions:
        _transactions(canvas, s, stroke, fill);
      case MangaIconKind.budgets:
        _budgets(canvas, s, stroke, fill);
      case MangaIconKind.investments:
        _investments(canvas, s, stroke);
      case MangaIconKind.categories:
        _categories(canvas, s, stroke, fill);
      case MangaIconKind.add:
        _add(canvas, s, stroke);
      case MangaIconKind.mic:
        _mic(canvas, s, stroke, fill);
    }
  }

  RRect _box(double l, double t, double r, double b, double s) =>
      RRect.fromLTRBR(l * s, t * s, r * s, b * s, Radius.circular(s * 0.08));

  // Cztery komiksowe panele (2×2).
  void _dashboard(Canvas c, double s, Paint stroke, Paint fill) {
    for (final r in [
      _box(0.14, 0.14, 0.45, 0.45, s),
      _box(0.55, 0.14, 0.86, 0.45, s),
      _box(0.14, 0.55, 0.45, 0.86, s),
      _box(0.55, 0.55, 0.86, 0.86, s),
    ]) {
      if (filled) c.drawRRect(r, fill);
      c.drawRRect(r, stroke);
    }
  }

  // Paragon: prostokąt z ząbkowanym dołem i liniami.
  void _transactions(Canvas c, double s, Paint stroke, Paint fill) {
    final path = Path()
      ..moveTo(s * 0.22, s * 0.12)
      ..lineTo(s * 0.78, s * 0.12)
      ..lineTo(s * 0.78, s * 0.84)
      ..lineTo(s * 0.68, s * 0.76)
      ..lineTo(s * 0.58, s * 0.84)
      ..lineTo(s * 0.5, s * 0.76)
      ..lineTo(s * 0.42, s * 0.84)
      ..lineTo(s * 0.32, s * 0.76)
      ..lineTo(s * 0.22, s * 0.84)
      ..close();
    if (filled) c.drawPath(path, fill);
    c.drawPath(path, stroke);
    final line = Paint()
      ..color = stroke.color
      ..strokeWidth = s * 0.075
      ..strokeCap = StrokeCap.round;
    for (final y in [0.3, 0.45]) {
      c.drawLine(Offset(s * 0.32, s * y), Offset(s * 0.68, s * y), line);
    }
  }

  // Portfel: zaokrąglony prostokąt z klapką i guzikiem.
  void _budgets(Canvas c, double s, Paint stroke, Paint fill) {
    final body = _box(0.14, 0.26, 0.86, 0.78, s);
    if (filled) c.drawRRect(body, fill);
    c.drawRRect(body, stroke);
    // Guzik zapięcia po prawej.
    c.drawCircle(Offset(s * 0.7, s * 0.52), s * 0.05, stroke);
    // Linia klapki.
    c.drawLine(Offset(s * 0.14, s * 0.4), Offset(s * 0.86, s * 0.4), stroke);
  }

  // Wykres w górę: strzałka zygzak + grot.
  void _investments(Canvas c, double s, Paint stroke) {
    final path = Path()
      ..moveTo(s * 0.16, s * 0.66)
      ..lineTo(s * 0.4, s * 0.42)
      ..lineTo(s * 0.55, s * 0.57)
      ..lineTo(s * 0.82, s * 0.28);
    c.drawPath(path, stroke);
    // Grot strzałki.
    final head = Path()
      ..moveTo(s * 0.64, s * 0.28)
      ..lineTo(s * 0.82, s * 0.28)
      ..lineTo(s * 0.82, s * 0.46);
    c.drawPath(head, stroke);
  }

  // Kategorie: koło, trójkąt, kwadrat.
  void _categories(Canvas c, double s, Paint stroke, Paint fill) {
    c.drawCircle(Offset(s * 0.31, s * 0.3), s * 0.15, stroke);
    final tri = Path()
      ..moveTo(s * 0.69, s * 0.16)
      ..lineTo(s * 0.86, s * 0.45)
      ..lineTo(s * 0.52, s * 0.45)
      ..close();
    if (filled) c.drawPath(tri, fill);
    c.drawPath(tri, stroke);
    final sq = _box(0.38, 0.6, 0.66, 0.88, s);
    if (filled) c.drawRRect(sq, fill);
    c.drawRRect(sq, stroke);
  }

  // Gruby plus.
  void _add(Canvas c, double s, Paint stroke) {
    final p = Paint()
      ..color = stroke.color
      ..strokeWidth = s * 0.16
      ..strokeCap = StrokeCap.round;
    c
      ..drawLine(Offset(s * 0.5, s * 0.2), Offset(s * 0.5, s * 0.8), p)
      ..drawLine(Offset(s * 0.2, s * 0.5), Offset(s * 0.8, s * 0.5), p);
  }

  // Mikrofon: kapsuła + pałąk + nóżka.
  void _mic(Canvas c, double s, Paint stroke, Paint fill) {
    final capsule = RRect.fromRectAndRadius(
      Rect.fromLTRB(s * 0.38, s * 0.12, s * 0.62, s * 0.56),
      Radius.circular(s * 0.12),
    );
    if (filled) c.drawRRect(capsule, fill);
    c.drawRRect(capsule, stroke);
    // Pałąk.
    final arc = Path()
      ..moveTo(s * 0.26, s * 0.46)
      ..arcToPoint(
        Offset(s * 0.74, s * 0.46),
        radius: Radius.circular(s * 0.26),
        clockwise: false,
      );
    c.drawPath(arc, stroke);
    // Nóżka + podstawka.
    c
      ..drawLine(Offset(s * 0.5, s * 0.72), Offset(s * 0.5, s * 0.86), stroke)
      ..drawLine(
        Offset(s * 0.36, s * 0.86),
        Offset(s * 0.64, s * 0.86),
        stroke,
      );
  }

  @override
  bool shouldRepaint(_MangaIconPainter old) =>
      old.kind != kind || old.color != color || old.filled != filled;
}
