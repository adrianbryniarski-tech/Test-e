import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/features/categories/data/category.dart';
import 'package:nasz_budzet_domowy/features/transactions/data/transaction.dart';

void main() {
  Category make(String id, {String name = 'Jedzenie'}) => Category(
        id: id,
        householdId: 'h1',
        name: name,
        icon: 'restaurant',
        colorHex: '#FF0000',
        type: TransactionType.expense,
        isSystem: false,
      );

  group('Category równość', () {
    test('dwie instancje o tym samym id są równe (mimo różnych pól)', () {
      // Symuluje przeładowanie listy z bazy: nowa instancja, ten sam id.
      expect(make('c1'), equals(make('c1', name: 'Inna nazwa')));
      expect(make('c1').hashCode, make('c1', name: 'Inna nazwa').hashCode);
    });

    test('różne id → różne', () {
      expect(make('c1'), isNot(equals(make('c2'))));
    });

    test('contains po id działa na liście świeżych instancji', () {
      final stary = make('c1');
      final swiezaLista = [make('c1'), make('c2')];
      // Klucz dla DropdownButton: zaznaczona wartość musi być w liście.
      expect(swiezaLista.contains(stary), isTrue);
      expect(swiezaLista.where((c) => c.id == stary.id).length, 1);
    });
  });

  group('Category podkategorie', () {
    Map<String, dynamic> json({String? parentId}) => {
          'id': 'c1',
          'household_id': 'h1',
          'name': 'Paliwo',
          'icon': 'local_gas_station',
          'color': '#E8A24A',
          'type': 'expense',
          'is_system': false,
          'parent_id': parentId,
        };

    test('parent_id null → kategoria główna', () {
      final c = Category.fromJson(json());
      expect(c.parentId, isNull);
      expect(c.isSubcategory, isFalse);
    });

    test('parent_id ustawione → podkategoria', () {
      final c = Category.fromJson(json(parentId: 'parent-1'));
      expect(c.parentId, 'parent-1');
      expect(c.isSubcategory, isTrue);
    });
  });
}
