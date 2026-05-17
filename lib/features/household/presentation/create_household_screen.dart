import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nasz_budzet_domowy/features/household/application/household_providers.dart';
import 'package:nasz_budzet_domowy/shared/widgets/inline_error.dart';
import 'package:nasz_budzet_domowy/shared/widgets/loading_filled_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateHouseholdScreen extends ConsumerStatefulWidget {
  const CreateHouseholdScreen({super.key});

  @override
  ConsumerState<CreateHouseholdScreen> createState() =>
      _CreateHouseholdScreenState();
}

class _CreateHouseholdScreenState extends ConsumerState<CreateHouseholdScreen> {
  final _controller = TextEditingController(text: 'Nasz dom');
  final _formKey = GlobalKey<FormState>();
  bool _isCreating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _controller.text.trim();

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(householdRepositoryProvider);
      final householdId = await repo.createHousehold(name: name);
      // Stwórz pierwsze zaproszenie od razu — user zaraz pokaże je partnerowi.
      final invitation = await repo.createInvitation(householdId);
      // Invaliduj cache `currentHouseholdIdProvider` — router teraz wie
      // że user ma gospodarstwo i może iść do /home (po zamknięciu invite).
      ref.invalidate(currentHouseholdIdProvider);
      if (!mounted) return;
      context.pushReplacement('/onboarding/invite/${invitation.code}');
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Nie udało się stworzyć gospodarstwa: '
            '${e.code ?? "?"} ${e.message}';
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Nie udało się stworzyć gospodarstwa: $e';
      });
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Nowe gospodarstwo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jak nazwać Wasz budżet?',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tylko Ty i osoby których zaprosisz to zobaczą.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa',
                    hintText: 'Np. Nasz dom, Rodzina Kowalskich…',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Wpisz nazwę.';
                    if (v.length < 2) return 'Za krótka nazwa.';
                    return null;
                  },
                  onFieldSubmitted: (_) => _create(),
                ),
                const SizedBox(height: 12),
                if (_errorMessage != null) ...[
                  InlineError(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],
                LoadingFilledButton(
                  label: 'Stwórz gospodarstwo',
                  isLoading: _isCreating,
                  icon: Icons.check_circle_outline,
                  onPressed: _create,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
