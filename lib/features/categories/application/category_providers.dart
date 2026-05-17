import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../household/application/household_providers.dart';
import '../data/category.dart';
import '../data/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return const CategoryRepository();
});

/// Lista kategorii bieżącego gospodarstwa. Auto-reload przy zmianie household_id.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final householdId = ref.watch(currentHouseholdIdProvider).valueOrNull;
  if (householdId == null) {
    return Stream.value(const <Category>[]);
  }
  return ref.watch(categoryRepositoryProvider).watchAll(householdId);
});
