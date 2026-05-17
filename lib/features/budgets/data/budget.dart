/// Budżet miesięczny per kategoria. Mirror tabeli `budgets`.
///
/// `period` w MVP zawsze `'monthly'` — schema dopuszcza tylko tę wartość.
/// `startsOn` jest pierwszym dniem miesiąca od kiedy budżet obowiązuje.
class Budget {
  const Budget({
    required this.id,
    required this.householdId,
    required this.categoryId,
    required this.amountCents,
    required this.startsOn,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      categoryId: json['category_id'] as String,
      amountCents: (json['amount_cents'] as num).toInt(),
      startsOn: DateTime.parse(json['starts_on'] as String),
    );
  }

  final String id;
  final String householdId;
  final String categoryId;
  final int amountCents;
  final DateTime startsOn;
}

/// Wyliczona pozycja budżetu z postępem — łączy [Budget] z sumą wydatków
/// w bieżącym miesiącu.
class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spentCents,
  });

  final Budget budget;
  final int spentCents;

  /// Wartość 0..1. Powyżej 1.0 = przekroczone.
  double get fraction =>
      budget.amountCents == 0 ? 0 : spentCents / budget.amountCents;

  bool get isExceeded => spentCents > budget.amountCents;
  bool get isNearLimit => fraction >= 0.8 && !isExceeded;
}
