import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/inline_error.dart';
import '../../../shared/widgets/loading_filled_button.dart';
import '../application/auth_providers.dart';

/// Krok 2 logowania: user wpisuje 6-cyfrowy kod z maila.
///
/// Po sukcesie sesja Supabase emituje `signedIn` → router auto-redirect
/// do `/onboarding` lub `/home`. Ten ekran NIE wywołuje `context.go`
/// po sukcesie — tym zajmuje się redirect w `routerProvider`.
class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({required this.email, super.key});

  final String email;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    final code = _codeController.text.trim();

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).verifyEmailOtp(
            email: widget.email,
            token: code,
          );
      // Sukces — router zareaguje na zmianę sesji.
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _humanizeError(e));
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).sendEmailOtp(widget.email);
      if (!mounted) return;
      setState(() => _infoMessage = 'Wysłaliśmy nowy kod. Sprawdź skrzynkę.');
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _humanizeError(e));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  String _humanizeError(Object e) {
    final raw = e.toString().toLowerCase();
    if (raw.contains('invalid') || raw.contains('expired')) {
      return 'Kod nieprawidłowy lub wygasł. Spróbuj ponownie albo poproś o nowy.';
    }
    if (raw.contains('rate limit') || raw.contains('429')) {
      return 'Wysłano za dużo prób. Spróbuj za chwilę.';
    }
    return 'Coś poszło nie tak. Spróbuj ponownie.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wpisz 6-cyfrowy kod',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Wysłaliśmy kod na '),
                      TextSpan(
                        text: widget.email,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '. Może chwilę zająć.'),
                    ],
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 8,
                  ),
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.length != 6) return 'Kod ma 6 cyfr.';
                    return null;
                  },
                  onFieldSubmitted: (_) => _verify(),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null) ...[
                  InlineError(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],
                if (_infoMessage != null) ...[
                  Text(
                    _infoMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                LoadingFilledButton(
                  label: 'Zaloguj się',
                  isLoading: _isVerifying,
                  onPressed: _verify,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _isResending ? null : _resend,
                    child: Text(
                      _isResending ? 'Wysyłam…' : 'Wyślij nowy kod',
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
