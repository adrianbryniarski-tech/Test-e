import 'package:flutter/material.dart';

/// Ikona po nazwie (string) — Material Icons mają `IconData` jako
/// compile-time constants (`Icons.shopping_cart`), więc lookup wymaga
/// statycznej mapy.
///
/// v1: mapuje 12 systemowych kategorii + paru ikon użytych w UI.
/// Ticket 7 rozszerza do pełnych 80 z `assets/icons/category_icons.json`.
class MaterialSymbolIcon extends StatelessWidget {
  const MaterialSymbolIcon({
    required this.name,
    this.size,
    this.color,
    super.key,
  });

  final String name;
  final double? size;
  final Color? color;

  static const Map<String, IconData> _map = {
    // Systemowe kategorie (seed migracji 0001).
    'shopping_cart': Icons.shopping_cart,
    'receipt_long': Icons.receipt_long,
    'directions_car': Icons.directions_car,
    'theaters': Icons.theaters,
    'local_pharmacy': Icons.local_pharmacy,
    'child_care': Icons.child_care,
    'home_work': Icons.home_work,
    'checkroom': Icons.checkroom,
    'payments': Icons.payments,
    'savings': Icons.savings,
    'account_balance': Icons.account_balance,
    'more_horiz': Icons.more_horiz,
    // Często używane w UI.
    'restaurant': Icons.restaurant,
    'local_gas_station': Icons.local_gas_station,
    'school': Icons.school,
    'pets': Icons.pets,
    'fitness_center': Icons.fitness_center,
    'trending_up': Icons.trending_up,
    'card_giftcard': Icons.card_giftcard,
  };

  @override
  Widget build(BuildContext context) {
    return Icon(
      _map[name] ?? Icons.more_horiz,
      size: size,
      color: color,
    );
  }
}
