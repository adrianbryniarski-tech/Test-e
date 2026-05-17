import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/features/auth/presentation/sign_in_screen.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(home: child),
    );
  }

  group('SignInScreen', () {
    testWidgets('renderuje email field i przycisk', (tester) async {
      await tester.pumpWidget(wrap(const SignInScreen()));
      expect(find.text('Nasz budżet domowy'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Wyślij kod'), findsOneWidget);
    });

    testWidgets('walidator: pusty email → komunikat błędu', (tester) async {
      await tester.pumpWidget(wrap(const SignInScreen()));
      // Symulujemy submit pustego formularza przez Form.validate().
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Wpisz email.'), findsOneWidget);
    });

    testWidgets('walidator: niepoprawny email → komunikat', (tester) async {
      await tester.pumpWidget(wrap(const SignInScreen()));
      await tester.enterText(find.byType(TextFormField), 'tojuznie');
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Email wygląda na niepoprawny.'), findsOneWidget);
    });

    testWidgets('walidator: poprawny email → brak błędu', (tester) async {
      await tester.pumpWidget(wrap(const SignInScreen()));
      await tester.enterText(
        find.byType(TextFormField),
        'adrian@example.com',
      );
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);
    });
  });
}
