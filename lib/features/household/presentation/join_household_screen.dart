import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/features/household/application/household_providers.dart';
import 'package:nasz_budzet_domowy/features/household/data/household_repository.dart';
import 'package:nasz_budzet_domowy/shared/widgets/inline_error.dart';
import 'package:nasz_budzet_domowy/shared/widgets/loading_filled_button.dart';

/// Wpisanie kodu zaproszenia (np. ABC-XYZ).
///
/// Format pola: 6 znaków z separatorem `-` w środku. Akceptujemy też
/// wklejony kod bez separatora — `_normalize` go dorzuca.
class JoinHouseholdScreen extends ConsumerStatefulWidget {
  const JoinHouseholdScreen({super.key});

  @override
  ConsumerState<JoinHouseholdScreen> createState() =>
      _JoinHouseholdScreenState();
}

class _JoinHouseholdScreenState extends ConsumerState<JoinHouseholdScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isJoining = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalize(String raw) {
    final cleaned = raw.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    if (cleaned.length != 6) return cleaned;
    return '${cleaned.substring(0, 3)}-${cleaned.substring(3)}';
  }

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;
    final code = _normalize(_controller.text);

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      await ref.read(householdRepositoryProvider).acceptInvitation(code);
      // Router auto-redirect na /home po invalidacji.
      ref.invalidate(currentHouseholdIdProvider);
    } on InvitationException catch (err) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFor(err.error));
    } on Object {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'Nie udało się dołączyć. Spróbuj ponownie.',
      );
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  String _messageFor(InvitationError err) {
    return switch (err) {
      InvitationError.notFound =>
        'Kod nieprawidłowy. Sprawdź czy nie pomyliłeś znaków (O ≠ 0, I ≠ 1).',
      InvitationError.alreadyUsed => 'Ten kod był już użyty. Poproś o nowy.',
      InvitationError.expired =>
        'Kod wygasł. Poproś osobę z gospodarstwa o nowy kod.',
      InvitationError.unauthenticated => 'Sesja wygasła. Zaloguj się ponownie.',
      InvitationError.unknown => 'Nie udało się dołączyć. Spróbuj ponownie.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Dołącz do gospodarstwa')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wpisz kod zaproszenia',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Dostałeś/aś kod od partnera/ki w wiadomości. '
                  'Format to 6 znaków, np. ABC-XYZ.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 6,
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(7),
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9-]')),
                    TextInputFormatter.withFunction((old, neu) {
                      return neu.copyWith(text: neu.text.toUpperCase());
                    }),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'ABC-XYZ',
                  ),
                  validator: (value) {
                    final v = _normalize(value ?? '');
                    if (v.length != 7) return 'Kod ma 6 znaków (ABC-XYZ).';
                    return null;
                  },
                  onFieldSubmitted: (_) => _join(),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null) ...[
                  InlineError(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],
                LoadingFilledButton(
                  label: 'Dołącz',
                  isLoading: _isJoining,
                  icon: Icons.login,
                  onPressed: _join,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
