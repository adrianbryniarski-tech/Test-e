import 'package:flutter/material.dart';

/// Znak wodny "made by AB Corporation" w lewym dolnym rogu. Przyklejony
/// (nie scrolluje z treścią), `IgnorePointer` (nie blokuje tapów pod
/// spodem). Logo przełącza się granat↔biały zależnie od jasności motywu;
/// kropki zawsze kolorowe.
///
/// Używać w `Stack` na poziomie shella (pokrywa wszystkie zakładki),
/// nad treścią ale pod FAB/nawigacją.
class BrandWatermark extends StatelessWidget {
  const BrandWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/icons/watermark_dark.png'
        : 'assets/icons/watermark_light.png';
    final textColor = isDark ? Colors.white : const Color(0xFF1A2B4A);

    return Positioned(
      left: 16,
      bottom: 12,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.4,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(asset, width: 34, height: 34),
              const SizedBox(width: 8),
              Text(
                'AB Corporation',
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
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
