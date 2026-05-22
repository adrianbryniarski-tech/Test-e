import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nasz_budzet_domowy/shared/widgets/comic_shadow.dart';

/// Pokazuje wygenerowany kod zaproszenia po stworzeniu gospodarstwa.
///
/// User kopiuje kod i wysyła partnerowi przez Telegram/Signal. Po
/// tap "Gotowe" przechodzi do /home — gospodarstwo działa nawet zanim
/// partner dołączy.
class InvitationShareScreen extends ConsumerWidget {
  const InvitationShareScreen({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                'Gospodarstwo gotowe',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Wyślij ten kod partnerowi/ce — gdy go wpisze, '
                'dołączy do Waszego wspólnego budżetu.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              _CodeCard(code: code),
              const SizedBox(height: 12),
              Text(
                'Kod ważny przez 14 dni. Nowy możesz stworzyć w Ustawieniach.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Przejdź do budżetu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ComicCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
            Text(
              code,
              style: theme.textTheme.displayMedium?.copyWith(
                letterSpacing: 6,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CodeAction(
                  icon: Icons.copy_outlined,
                  label: 'Kopiuj',
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kod skopiowany'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                _CodeAction(
                  icon: Icons.share_outlined,
                  label: 'Udostępnij',
                  onTap: () async {
                    // share_plus nie jest w pubspec; fallback: skopiuj
                    // i pokaż instrukcję. v2 dorzuci share_plus.
                    await Clipboard.setData(ClipboardData(text: code));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Kod skopiowany — wklej go w Telegramie/Signal.',
                        ),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeAction extends StatelessWidget {
  const _CodeAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
