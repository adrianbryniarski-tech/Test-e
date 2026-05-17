import 'package:flutter/material.dart';

/// `FilledButton` z wbudowanym stanem ładowania.
///
/// Podczas `isLoading == true` przycisk jest zablokowany (onPressed = null),
/// pokazuje `CircularProgressIndicator` zamiast tekstu, ale zachowuje tę
/// samą wysokość — uniknięcie skoków layoutu w trakcie żądania sieciowego.
class LoadingFilledButton extends StatelessWidget {
  const LoadingFilledButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 10),
              ],
              Text(label),
            ],
          );

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}
