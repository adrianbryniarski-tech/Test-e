import 'package:flutter/foundation.dart';
import 'package:nasz_budzet_domowy/features/transactions/data/transaction.dart';

/// Kategoria z `categories`. Może być systemowa (seed, `is_system=true`,
/// `name` zablokowane do edycji) lub własna (CRUD w Ticket 7).
@immutable
class Category {
  const Category({
    required this.id,
    required this.householdId,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.type,
    required this.isSystem,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      colorHex: json['color'] as String,
      type: TransactionType.fromDbValue(json['type'] as String),
      isSystem: json['is_system'] as bool? ?? false,
    );
  }

  final String id;
  final String householdId;
  final String name;
  final String icon;

  /// Hex `#RRGGBB`. Parser do `Color`: `CategoryPalette.fromHex(colorHex)`.
  final String colorHex;
  final TransactionType type;
  final bool isSystem;

  // Równość po `id` (PK). Bez tego dwie instancje tej samej kategorii (np.
  // po przeładowaniu listy z bazy) są "różne" — a DropdownButton wymaga, by
  // zaznaczona wartość pasowała dokładnie do jednego elementu listy.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Category && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
