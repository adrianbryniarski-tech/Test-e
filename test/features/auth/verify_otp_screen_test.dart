import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/features/auth/presentation/verify_otp_screen.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(home: child),
    );
  }

  group('VerifyOtpScreen', () {
    testWidgets('renderuje email i pole kodu', (tester) async {
      await tester.pumpWidget(
        wrap(const VerifyOtpScreen(email: 'adrian@example.com')),
      );
      expect(find.text('Wpisz 6-cyfrowy kod'), findsOneWidget);
      // Email jest w Text.rich z TextSpan — szukamy częściowego dopasowania.
      expect(find.textContaining('adrian@example.com'), findsOneWidget);
      expect(find.text('Zaloguj się'), findsOneWidget);
    });

    testWidgets('walidator: kod krótszy niż 6 znaków → błąd', (tester) async {
      await tester.pumpWidget(
        wrap(const VerifyOtpScreen(email: 'adrian@example.com')),
      );
      await tester.enterText(find.byType(TextFormField), '123');
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Kod ma 6 cyfr.'), findsOneWidget);
    });

    testWidgets('walidator: 6 cyfr → brak błędu', (tester) async {
      await tester.pumpWidget(
        wrap(const VerifyOtpScreen(email: 'adrian@example.com')),
      );
      await tester.enterText(find.byType(TextFormField), '123456');
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);
    });
  });
}
