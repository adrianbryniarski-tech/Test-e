import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/features/auth/application/auth_providers.dart';
import 'package:nasz_budzet_domowy/features/auth/data/auth_repository.dart';
import 'package:nasz_budzet_domowy/features/auth/presentation/forgot_password_screen.dart';

class _FakeAuthRepository extends AuthRepository {
  const _FakeAuthRepository({required this.resetResult});

  final AuthResult resetResult;

  @override
  Future<AuthResult> sendPasswordResetCode(String email) async =>
      const AuthSuccess();

  @override
  Future<AuthResult> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async =>
      resetResult;
}

Future<void> _pump(WidgetTester tester, AuthResult resetResult) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(resetResult: resetResult),
        ),
      ],
      child: const MaterialApp(
        home: ForgotPasswordScreen(initialEmail: 'zona@dom.pl'),
      ),
    ),
  );
}

void main() {
  testWidgets('krok 1 → krok 2: po wysłaniu kodu pojawia się pole na kod',
      (tester) async {
    await _pump(tester, const AuthSuccess());

    expect(find.text('Kod z maila (6 cyfr)'), findsNothing);

    await tester.tap(find.text('Wyślij kod'));
    await tester.pumpAndSettle();

    expect(find.text('Kod z maila (6 cyfr)'), findsOneWidget);
    expect(find.text('Nowe hasło (min. 6 znaków)'), findsOneWidget);
  });

  testWidgets('błędny kod → czytelny komunikat', (tester) async {
    await _pump(tester, const AuthInvalidOtp());

    await tester.tap(find.text('Wyślij kod'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.enterText(find.byType(TextFormField).at(2), 'noweHaslo1');
    await tester.tap(find.text('Ustaw nowe hasło'));
    await tester.pumpAndSettle();

    expect(find.textContaining('niepoprawny lub wygasł'), findsOneWidget);
  });
}
