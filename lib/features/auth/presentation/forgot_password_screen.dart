import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/features/auth/application/auth_providers.dart';
import 'package:nasz_budzet_domowy/features/auth/data/auth_repository.dart';
import 'package:nasz_budzet_domowy/shared/widgets/inline_error.dart';
import 'package:nasz_budzet_domowy/shared/widgets/loading_filled_button.dart';
import 'package:nasz_budzet_domowy/shared/widgets/manga_icons.dart';

/// Reset hasła kodem e-mail (OTP) — bez magic-linków.
/// Krok 1: podaj e-mail → wyślij kod. Krok 2: wpisz kod + nowe hasło.
/// Po sukcesie sesja jest aktywna i router przerzuca na ekran główny.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({this.initialEmail = '', super.key});

  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

enum _Step { email, code }

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController =
      TextEditingController(text: widget.initialEmail);
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  _Step _step = _Step.email;
  bool _showPassword = false;
  bool _submitting = false;
  String? _errorMessage;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Wpisz poprawny email.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final result =
        await ref.read(authRepositoryProvider).sendPasswordResetCode(email);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (result is AuthSuccess) {
        _step = _Step.code;
      } else {
        _errorMessage = _message(result);
      }
    });
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final result = await ref.read(authRepositoryProvider).resetPasswordWithCode(
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
          newPassword: _passwordController.text,
        );
    if (!mounted) return;
    if (result is AuthSuccess) {
      // Sesja aktywna → router przerzuci dalej; zamykamy ten ekran.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hasło zmienione. Jesteś zalogowany(a).'),
        ),
      );
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _submitting = false;
      _errorMessage = _message(result);
    });
  }

  String _message(AuthResult r) {
    return switch (r) {
      AuthSuccess() => '',
      AuthInvalidOtp() =>
        'Kod jest niepoprawny lub wygasł. Wyślij nowy i spróbuj ponownie.',
      AuthWeakPassword() => 'Nowe hasło musi mieć co najmniej 6 znaków.',
      AuthInvalidCredentials() => 'Nie udało się — sprawdź email i kod.',
      AuthEmailAlreadyExists() => 'Konto z tym emailem już istnieje.',
      AuthGenericFailure(:final message) => 'Nie udało się: $message',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmailStep = _step == _Step.email;
    return Scaffold(
      appBar: AppBar(title: const Text('Nie pamiętam hasła')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEmailStep
                      ? 'Podaj email konta. Wyślemy 6-cyfrowy kod do '
                          'zresetowania hasła.'
                      : 'Wpisz kod z maila i ustaw nowe hasło.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enableSuggestions: false,
                  enabled: isEmailStep && !_submitting,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: AppIcon(Icons.email_outlined),
                  ),
                ),
                if (!isEmailStep) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    autocorrect: false,
                    enableSuggestions: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Kod z maila (6 cyfr)',
                      prefixIcon: AppIcon(Icons.pin_outlined),
                    ),
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.length < 6) return 'Wpisz 6-cyfrowy kod.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Nowe hasło (min. 6 znaków)',
                      prefixIcon: const AppIcon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _showPassword ? 'Ukryj' : 'Pokaż',
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    validator: (v) {
                      final s = v ?? '';
                      if (s.length < 6) {
                        return 'Hasło musi mieć co najmniej 6 znaków.';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                if (_errorMessage != null) ...[
                  InlineError(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],
                LoadingFilledButton(
                  label: isEmailStep ? 'Wyślij kod' : 'Ustaw nowe hasło',
                  isLoading: _submitting,
                  icon: isEmailStep ? Icons.send : Icons.lock_reset,
                  onPressed: isEmailStep ? _sendCode : _resetPassword,
                ),
                if (!isEmailStep) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _submitting ? null : _sendCode,
                      child: const Text('Wyślij kod ponownie'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
