import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Tłumaczenie kodów błędów RPC na komunikaty po polsku — to, co user widzi
// gdy usuwanie kategorii z przeniesieniem transakcji się nie uda.
void main() {
  const repo = CategoryRepository();

  PostgrestException err(String? code) =>
      PostgrestException(message: 'raw', code: code);

  group('humanizeRpcError', () {
    test('P0010 → kategoria systemowa', () {
      expect(
        repo.humanizeRpcError(err('P0010')),
        'Nie można usunąć kategorii systemowej.',
      );
    });

    test('P0011 → inne gospodarstwo', () {
      expect(
        repo.humanizeRpcError(err('P0011')),
        'Kategoria docelowa należy do innego gospodarstwa.',
      );
    });

    test('P0012 → inny typ', () {
      expect(
        repo.humanizeRpcError(err('P0012')),
        'Kategoria docelowa ma inny typ (dochód/wydatek) niż usuwana.',
      );
    });

    test('42501 → brak uprawnień', () {
      expect(repo.humanizeRpcError(err('42501')), 'Brak uprawnień.');
    });

    test('nieznany kod → surowy message', () {
      expect(repo.humanizeRpcError(err('99999')), 'raw');
      expect(repo.humanizeRpcError(err(null)), 'raw');
    });
  });

  group('CategoryWriteResult — sealed', () {
    test('switch wyczerpuje warianty (guard kompilatora)', () {
      String describe(CategoryWriteResult r) => switch (r) {
            CategoryWriteSuccess() => 'ok',
            CategoryDuplicateName() => 'dup',
            CategoryWriteFailure(:final message) => 'fail:$message',
          };
      expect(describe(const CategoryWriteSuccess()), 'ok');
      expect(describe(const CategoryDuplicateName()), 'dup');
      expect(describe(const CategoryWriteFailure('x')), 'fail:x');
    });
  });
}
