import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';

/// Cienka warstwa nad `supabase.auth`.
///
/// W v1 logujemy **6-cyfrowym kodem OTP wysyłanym mailem**, nie deep linkiem.
/// Powód: deep linki wymagają konfiguracji Supabase Dashboard (Site URL +
/// Redirect URLs), customowego intent-filtera Androida i działającego
/// schematu URL — wszystko poza kontrolą tej apki. Kod OTP działa
/// out-of-the-box: Supabase i tak wysyła `{{ .Token }}` w domyślnym
/// szablonie maila obok linka, więc user widzi 6 cyfr i je przepisuje.
///
/// Hasła **nie używamy** — magic-link/OTP jest wystarczający dla apki
/// dla 2 osób i eliminuje całą klasę problemów (reset, brute force, leak).
class AuthRepository {
  const AuthRepository();

  /// Wysyła 6-cyfrowy kod OTP na podany email.
  ///
  /// `shouldCreateUser: true` — pierwsze logowanie tworzy konto
  /// automatycznie, bez osobnego flow "rejestracja".
  Future<void> sendEmailOtp(String email) async {
    await supabase.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
    );
  }

  /// Weryfikuje kod OTP i tworzy sesję.
  ///
  /// Po sukcesie `supabase.auth.currentSession != null` i listener
  /// `onAuthStateChange` emituje `signedIn`.
  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    return supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  Future<void> signOut() => supabase.auth.signOut();

  Session? get currentSession => supabase.auth.currentSession;

  User? get currentUser => supabase.auth.currentUser;

  /// Strumień zmian stanu auth — używany w `routerProvider` do redirectów.
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
}
