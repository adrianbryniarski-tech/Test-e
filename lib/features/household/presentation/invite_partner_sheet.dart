import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/features/household/application/household_providers.dart';
import 'package:nasz_budzet_domowy/features/household/data/household_repository.dart';
import 'package:nasz_budzet_domowy/shared/widgets/comic_shadow.dart';
import 'package:nasz_budzet_domowy/shared/widgets/manga_icons.dart';

/// Bottom sheet do udostępnienia kodu zaproszenia.
/// Pokazuje aktywne (nieprzyjęte, niewygasłe) zaproszenia gospodarstwa.
/// Jeśli żadnego nie ma — generuje nowe. Plus przycisk "Stwórz nowy".
class InvitePartnerSheet extends ConsumerStatefulWidget {
  const InvitePartnerSheet({required this.householdId, super.key});

  final String householdId;

  @override
  ConsumerState<InvitePartnerSheet> createState() => _InvitePartnerSheetState();
}

class _InvitePartnerSheetState extends ConsumerState<InvitePartnerSheet> {
  Invitation? _active;
  bool _loading = true;
  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(householdRepositoryProvider);
    try {
      final list = await repo.activeInvitations(widget.householdId);
      if (!mounted) return;
      setState(() {
        _active = list.isEmpty ? null : list.first;
        _loading = false;
      });
      if (_active == null) {
        // Brak aktywnego — generujemy od razu, żeby user nie musiał klikać.
        await _createNew();
      }
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Nie udało się pobrać zaproszeń: $e';
        _loading = false;
      });
    }
  }

  Future<void> _createNew() async {
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final invitation = await ref
          .read(householdRepositoryProvider)
          .createInvitation(widget.householdId);
      if (!mounted) return;
      setState(() {
        _active = invitation;
        _creating = false;
      });
      ref.invalidate(activeInvitationsProvider(widget.householdId));
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Nie udało się utworzyć kodu: $e';
        _creating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Zaproś partnera', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Wyślij ten kod osobie z którą dzielicie budżet. '
            'Wpisuje go w apce → "Wpisz kod zaproszenia".',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          if (_loading || _creating)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            )
          else if (_active != null)
            _CodeBlock(invitation: _active!),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: (_loading || _creating) ? null : _createNew,
            icon: const AppIcon(Icons.refresh),
            label: const Text('Wygeneruj nowy kod'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.invitation});

  final Invitation invitation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysLeft = invitation.expiresAt.difference(DateTime.now()).inDays;
    return ComicCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            Text(
              'KOD ZAPROSZENIA',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              invitation.code,
              style: theme.textTheme.displaySmall?.copyWith(
                letterSpacing: 6,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ważny jeszcze $daysLeft ${_pluralDays(daysLeft)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: invitation.code),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kod skopiowany — wklej w Telegramie.'),
                  ),
                );
              },
              icon: const AppIcon(Icons.copy),
              label: const Text('Kopiuj kod'),
            ),
          ],
        ),
      ),
    );
  }

  String _pluralDays(int n) {
    if (n == 1) return 'dzień';
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return 'dni';
    }
    return 'dni';
  }
}
