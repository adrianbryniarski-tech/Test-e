import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/features/household/presentation/join_household_screen.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(home: child),
    );
  }

  group('JoinHouseholdScreen', () {
    testWidgets('renderuje pole kodu i przycisk dołącz', (tester) async {
      await tester.pumpWidget(wrap(const JoinHouseholdScreen()));
      expect(find.text('Wpisz kod zaproszenia'), findsOneWidget);
      expect(find.text('Dołącz'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('walidator: za krótki kod → błąd', (tester) async {
      await tester.pumpWidget(wrap(const JoinHouseholdScreen()));
      await tester.enterText(find.byType(TextFormField), 'ABC');
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Kod ma 6 znaków (ABC-XYZ).'), findsOneWidget);
    });

    testWidgets('walidator: 6 znaków bez myślnika → akceptuje',
        (tester) async {
      await tester.pumpWidget(wrap(const JoinHouseholdScreen()));
      await tester.enterText(find.byType(TextFormField), 'ABCXYZ');
      final formState = tester.state<FormState>(find.byType(Form));
      // Normalizacja wewnątrz walidatora powinna to przepuścić.
      expect(formState.validate(), isTrue);
    });

    testWidgets('walidator: 6 znaków z myślnikiem → akceptuje',
        (tester) async {
      await tester.pumpWidget(wrap(const JoinHouseholdScreen()));
      await tester.enterText(find.byType(TextFormField), 'ABC-XYZ');
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);
    });

    testWidgets('inputFormatter: lowercase → uppercase', (tester) async {
      await tester.pumpWidget(wrap(const JoinHouseholdScreen()));
      await tester.enterText(find.byType(TextFormField), 'abcxyz');
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.controller!.text, 'ABCXYZ');
    });
  });
}
