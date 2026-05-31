import 'package:flutter_test/flutter_test.dart';
import 'package:nasz_budzet_domowy/features/auth/data/auth_repository.dart';

void main() {
  group('AuthResult — sealed hierarchia', () {
    test('AuthSuccess to const', () {
      const a = AuthSuccess();
      const b = AuthSuccess();
      expect(identical(a, b), isTrue);
    });

    test('AuthGenericFailure trzyma message', () {
      const r = AuthGenericFailure('boom');
      expect(r.message, 'boom');
    });

    test('switch wyczerpuje wszystkie warianty (compile-time check)', () {
      // Jeśli ktoś doda nowy wariant AuthResult, kompilator zmusi do
      // dopisania case'a tutaj — to nasz "non_exhaustive" guard.
      String describe(AuthResult r) => switch (r) {
            AuthSuccess() => 'ok',
            AuthInvalidCredentials() => 'bad-creds',
            AuthEmailAlreadyExists() => 'exists',
            AuthWeakPassword() => 'weak',
            AuthInvalidOtp() => 'bad-otp',
            AuthGenericFailure(:final message) => 'fail:$message',
          };

      expect(describe(const AuthSuccess()), 'ok');
      expect(describe(const AuthInvalidCredentials()), 'bad-creds');
      expect(describe(const AuthEmailAlreadyExists()), 'exists');
      expect(describe(const AuthWeakPassword()), 'weak');
      expect(describe(const AuthInvalidOtp()), 'bad-otp');
      expect(describe(const AuthGenericFailure('x')), 'fail:x');
    });
  });
}
