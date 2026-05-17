import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/inline_error.dart';
import '../../../shared/widgets/loading_filled_button.dart';
import '../application/auth_providers.dart';

/// Pierwszy ekran auth: prosi o email, wysyła kod OTP, przechodzi do
/// `VerifyOtpScreen`.
///
/// Brak osobnego "Sign up" / "Sign in" — Supabase przy `shouldCreateUser:
/// true` tworzy konto przy pierwszym OTP automatycznie.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSending = false;
  String? _errorMessage;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).sendEmailOtp(email);
      if (!mounted) return;
      context.push('/sign-in/verify', extra: email);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _humanizeError(e));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _humanizeError(Object e) {
    // Supabase rate limit (30 maili/h na free tier) → 429.
    final raw = e.toString();
    if (raw.contains('rate limit') || raw.contains('429')) {
      return 'Wysłano za dużo prób. Spróbuj ponownie za chwilę.';
    }
    return 'Nie udało się wysłać kodu. Sprawdź połączenie i spróbuj ponownie.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Nasz budżet domowy',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Zaloguj się — wyślemy Ci 6-cyfrowy kod na email.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'adrian@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Wpisz email.';
                    if (!_emailRegex.hasMatch(v)) {
                      return 'Email wygląda na niepoprawny.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _sendOtp(),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null) ...[
                  InlineError(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],
                LoadingFilledButton(
                  label: 'Wyślij kod',
                  isLoading: _isSending,
                  icon: Icons.send_outlined,
                  onPressed: _sendOtp,
                ),
                const Spacer(),
                Center(
                  child: Text(
                    'Bez hasła — kod ważny 1 godzinę.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
