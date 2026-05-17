import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category_repository.dart';
import 'package:nasz_budzet_domowy/features/household/application/household_providers.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return const CategoryRepository();
});

/// Lista kategorii gospodarstwa. Auto-reload przy zmianie householdId.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final householdId = ref.watch(currentHouseholdIdProvider).value;
  if (householdId == null) {
    return Stream.value(const <Category>[]);
  }
  return ref.watch(categoryRepositoryProvider).watchAll(householdId);
});
