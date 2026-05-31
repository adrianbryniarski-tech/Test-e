import 'package:nasz_budzet_domowy/core/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wynik próby logowania / rejestracji.
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess();
}

class AuthInvalidCredentials extends AuthResult {
  const AuthInvalidCredentials();
}

class AuthEmailAlreadyExists extends AuthResult {
  const AuthEmailAlreadyExists();
}

class AuthWeakPassword extends AuthResult {
  const AuthWeakPassword();
}

/// Kod resetu hasła błędny lub wygasły.
class AuthInvalidOtp extends AuthResult {
  const AuthInvalidOtp();
}

class AuthGenericFailure extends AuthResult {
  const AuthGenericFailure(this.message);
  final String message;
}

/// Cienka warstwa nad `supabase.auth`. Email+hasło, bez magic linków.
///
/// Powód: magic linki Supabase domyślnie przekierowują na Site URL (zwykle
/// `http://localhost:3000`), co nie działa na telefonie. Dla apki mobilnej
/// trzeba albo skonfigurować deep linki + intent filters (skomplikowane,
/// wymaga modyfikacji AndroidManifest), albo użyć password auth (proste).
///
/// W Supabase Dashboard MUSI być wyłączone "Confirm email"
/// (Auth → Sign in / providers → Email → "Confirm email" = OFF), inaczej
/// nowy user dostanie mail z linkiem potwierdzającym, który prowadzi na
/// localhost.
class AuthRepository {
  const AuthRepository();

  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) {
        return const AuthGenericFailure(
          'Nie udało się utworzyć konta. Spróbuj ponownie.',
        );
      }
      return const AuthSuccess();
    } on AuthException catch (e) {
      return _classifyAuthError(e);
    } on Object catch (e) {
      return AuthGenericFailure(e.toString());
    }
  }

  Future<AuthResult> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        return const AuthInvalidCredentials();
      }
      return const AuthSuccess();
    } on AuthException catch (e) {
      return _classifyAuthError(e);
    } on Object catch (e) {
      return AuthGenericFailure(e.toString());
    }
  }

  Future<AuthResult> changePassword(String newPassword) async {
    try {
      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return const AuthSuccess();
    } on AuthException catch (e) {
      return _classifyAuthError(e);
    } on Object catch (e) {
      return AuthGenericFailure(e.toString());
    }
  }

  /// Wysyła e-mail z 6-cyfrowym kodem resetu hasła (typ `recovery`).
  ///
  /// Świadomie NIE używamy magic-linków (przekierowują na Site URL =
  /// localhost, nie działa na telefonie). Wymaga, by szablon e-mail
  /// „Reset Password" w Supabase zawierał token `{{ .Token }}`.
  Future<AuthResult> sendPasswordResetCode(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
      return const AuthSuccess();
    } on AuthException catch (e) {
      return _classifyAuthError(e);
    } on Object catch (e) {
      return AuthGenericFailure(e.toString());
    }
  }

  /// Weryfikuje kod resetu (`recovery`) i ustawia nowe hasło. Po sukcesie
  /// użytkownik ma aktywną sesję (jest zalogowany).
  Future<AuthResult> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final res = await supabase.auth.verifyOTP(
        email: email,
        token: code.trim(),
        type: OtpType.recovery,
      );
      if (res.session == null) return const AuthInvalidOtp();
      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return const AuthSuccess();
    } on AuthException catch (e) {
      return _classifyAuthError(e);
    } on Object catch (e) {
      return AuthGenericFailure(e.toString());
    }
  }

  Future<void> signOut() => supabase.auth.signOut();

  Session? get currentSession => supabase.auth.currentSession;
  User? get currentUser => supabase.auth.currentUser;
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  AuthResult _classifyAuthError(AuthException e) {
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();
    if (code == 'invalid_credentials' ||
        msg.contains('invalid login') ||
        msg.contains('invalid credentials')) {
      return const AuthInvalidCredentials();
    }
    if (code == 'user_already_exists' ||
        msg.contains('already registered') ||
        msg.contains('already exists')) {
      return const AuthEmailAlreadyExists();
    }
    if (code == 'weak_password' ||
        msg.contains('password should be at least')) {
      return const AuthWeakPassword();
    }
    if (code == 'otp_expired' ||
        code == 'otp_disabled' ||
        msg.contains('token has expired') ||
        msg.contains('invalid token') ||
        msg.contains('otp')) {
      return const AuthInvalidOtp();
    }
    return AuthGenericFailure(e.message);
  }
}
