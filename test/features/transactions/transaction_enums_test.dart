import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/features/transactions/data/transaction.dart';

// Mapowania enum ↔ wartości DB są kontraktem zapisu/odczytu z chmury.
// Jeśli ktoś zmieni string po stronie Dart bez migracji (albo odwrotnie),
// CRUD na transakcjach po cichu się rozjedzie — te testy to wykryją.
void main() {
  group('TransactionType ↔ DB', () {
    test('round-trip dla każdej wartości', () {
      for (final t in TransactionType.values) {
        expect(TransactionType.fromDbValue(t.toDbValue()), t);
      }
    });

    test('konkretne stringi DB', () {
      expect(TransactionType.income.toDbValue(), 'income');
      expect(TransactionType.expense.toDbValue(), 'expense');
    });

    test('nieznana wartość → ArgumentError', () {
      expect(
        () => TransactionType.fromDbValue('foo'),
        throwsArgumentError,
      );
    });
  });

  group('TransactionSource ↔ DB', () {
    test('round-trip dla każdej wartości', () {
      for (final s in TransactionSource.values) {
        expect(TransactionSource.fromDbValue(s.toDbValue()), s);
      }
    });

    test('konkretne stringi DB (snake_case dla importów)', () {
      expect(TransactionSource.manual.toDbValue(), 'manual');
      expect(TransactionSource.voice.toDbValue(), 'voice');
      expect(TransactionSource.csvImport.toDbValue(), 'csv_import');
      expect(TransactionSource.pdfImport.toDbValue(), 'pdf_import');
    });

    test('nieznana wartość → ArgumentError', () {
      expect(
        () => TransactionSource.fromDbValue('xls_import'),
        throwsArgumentError,
      );
    });
  });
}
