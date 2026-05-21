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
          // Układ pionowy: logo NAD tekstem (jak zaakceptowany szkic).
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(asset, width: 40, height: 40),
              const SizedBox(height: 2),
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
