import 'package:nasz_budzet_domowy/core/supabase/supabase_client.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category.dart';

/// Read-only repository dla v1 — CRUD (insert/update/delete + reasignment)
/// przychodzi z Ticketem 7.
class CategoryRepository {
  const CategoryRepository();

  /// Realtime stream wszystkich kategorii gospodarstwa.
  Stream<List<Category>> watchAll(String householdId) {
    return supabase
        .from('categories')
        .stream(primaryKey: ['id'])
        .eq('household_id', householdId)
        .order('name')
        .map((rows) => rows.map(Category.fromJson).toList());
  }
}
