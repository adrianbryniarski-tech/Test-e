import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/features/auth/application/auth_providers.dart';
import 'package:nasz_budzet_domowy/features/household/presentation/onboarding_choice_screen.dart';

void main() {
  Widget wrap(Widget child) {
    // Override `currentUserProvider` żeby nie próbował dotknąć Supabase
    // (które nie jest zainicjalizowane w testach jednostkowych).
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => null),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('OnboardingChoiceScreen', () {
    testWidgets('renderuje dwie opcje wyboru', (tester) async {
      await tester.pumpWidget(wrap(const OnboardingChoiceScreen()));
      expect(find.text('Skonfigurujmy Twój budżet'), findsOneWidget);
      expect(find.text('Stwórz nowe gospodarstwo'), findsOneWidget);
      expect(find.text('Mam kod zaproszenia'), findsOneWidget);
    });
  });
}
