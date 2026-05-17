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
    testWidgets('renderuje email + hasło + toggle', (tester) async {
      await tester.pumpWidget(wrap(const SignInScreen()));
      expect(find.text('Nasz budżet domowy'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Zaloguj się'), findsWidgets);
      expect(find.text('Załóż konto'), findsOneWidget);
    });

    testWidgets('walidator: pusty email → komunikat', (tester) async {
      await tester.pumpWidget(wrap(const SignInScreen()));
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Wpisz email.'), findsOneWidget);
    });

    testWidgets('walidator: niepoprawny email → komunikat', (tester) async {
      await tester.pumpWidget(wrap(const SignInScreen()));
      await tester.enterText(find.byType(TextFormField).first, 'tojuznie');
      await tester.enterText(find.byType(TextFormField).last, 'sekret');
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Email wygląda na niepoprawny.'), findsOneWidget);
    });

    testWidgets('walidator: poprawny email + hasło → bez błędu',
        (tester) async {
      await tester.pumpWidget(wrap(const SignInScreen()));
      await tester.enterText(
        find.byType(TextFormField).first,
        'adrian@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'sekret123');
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);
    });
  });
}
